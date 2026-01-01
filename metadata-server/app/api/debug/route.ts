import { NextResponse } from 'next/server';
import { getContract, getGlobalDescription } from '@/lib/contract';

export async function GET() {
  const contract = getContract();
  const globalDescription = getGlobalDescription();
  
  const debug = {
    timestamp: new Date().toISOString(),
    environment: {
      RPC_URL_SET: !!process.env.AMOY_RPC,
      CONTRACT_ADDRESS_SET: !!process.env.CONTRACT_ADDRESS,
      RPC_URL_VALUE: process.env.AMOY_RPC ? `${process.env.AMOY_RPC.substring(0, 20)}...` : 'NOT SET',
      CONTRACT_VALUE: process.env.CONTRACT_ADDRESS || 'NOT SET'
    },
    contract: {
      initialized: !!contract,
      globalDescription: globalDescription || 'None loaded'
    }
  };
  
  return NextResponse.json(debug);
}