import 'dotenv/config';
import { ethers } from 'ethers';
import pino from 'pino';
import bridgeAbi from './abi/Bridge.json' assert { type: 'json' };

const logger = pino({ level: process.env.LOG_LEVEL || 'info', transport: { target: 'pino-pretty' } });

function requireEnv(name: string): string {
  const v = process.env[name];
  if (!v) throw new Error(`Missing env ${name}`);
  return v;
}

async function main() {
  const SOURCE_RPC_URL = requireEnv('SOURCE_RPC_URL');
  const SOURCE_BRIDGE_ADDRESS = requireEnv('SOURCE_BRIDGE_ADDRESS');
  const SOURCE_CHAIN_ID = BigInt(requireEnv('SOURCE_CHAIN_ID'));

  const DEST_RPC_URL = requireEnv('DEST_RPC_URL');
  const DEST_BRIDGE_ADDRESS = requireEnv('DEST_BRIDGE_ADDRESS');
  const DEST_TOKEN_ADDRESS = requireEnv('DEST_TOKEN_ADDRESS');
  const DEST_CHAIN_ID = BigInt(requireEnv('DEST_CHAIN_ID'));

  const RELAYER_PRIVATE_KEY = requireEnv('RELAYER_PRIVATE_KEY');

  const srcProvider = new ethers.JsonRpcProvider(SOURCE_RPC_URL);
  const dstProvider = new ethers.JsonRpcProvider(DEST_RPC_URL);
  const wallet = new ethers.Wallet(RELAYER_PRIVATE_KEY, dstProvider);

  const srcBridge = new ethers.Contract(SOURCE_BRIDGE_ADDRESS, bridgeAbi, srcProvider);
  const dstBridge = new ethers.Contract(DEST_BRIDGE_ADDRESS, bridgeAbi, wallet);

  const processed = new Set<string>();

  logger.info({ SOURCE_BRIDGE_ADDRESS, DEST_BRIDGE_ADDRESS }, 'Relayer started');

  srcBridge.on(
    srcBridge.filters.TransferInitiated(),
    async (
      messageId: string,
      sourceChainId: bigint,
      destChainId: bigint,
      token: string,
      sender: string,
      recipient: string,
      amount: bigint,
      nonce: bigint,
      event: ethers.EventLog
    ) => {
      try {
        logger.info({ messageId, sourceChainId, destChainId, token, sender, recipient, amount, nonce }, 'Event received');

        if (destChainId !== DEST_CHAIN_ID) {
          logger.warn({ destChainId }, 'Ignore event: different dest chain');
          return;
        }

        if (processed.has(messageId)) {
          logger.warn({ messageId }, 'Skip already processed');
          return;
        }

        const tx = await dstBridge.receiveFromChain(
          sourceChainId,
          destChainId,
          DEST_TOKEN_ADDRESS,
          sender,
          recipient,
          amount,
          nonce,
          { gasLimit: 1_000_000 }
        );

        logger.info({ hash: tx.hash }, 'Submitted receiveFromChain');

        const receipt = await tx.wait();
        if (receipt?.status !== 1n) {
          logger.error({ receipt }, 'Transaction failed');
          return;
        }
        
        processed.add(messageId);
        logger.info({ hash: receipt.transactionHash }, 'Transfer completed');
      } catch (err) {
        logger.error({ err }, 'Handler error');
      }
    }
  );
}

main().catch((err) => {
  // eslint-disable-next-line no-console
  console.error(err);
  process.exit(1);
});
