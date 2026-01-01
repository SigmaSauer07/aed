import { NextResponse } from 'next/server';
import { ethers } from 'ethers';
import { ABI } from '@/lib/contract';

export async function GET() {
  try {
    const provider = new ethers.JsonRpcProvider(process.env.AMOY_RPC);
    const testContract = new ethers.Contract(process.env.CONTRACT_ADDRESS!, ABI, provider);

    const tests: any = {
      contractAddress: process.env.CONTRACT_ADDRESS,
      rpcUrl: process.env.AMOY_RPC ? `${process.env.AMOY_RPC.substring(0, 30)}...` : 'NOT SET'
    };

    const tokenTests = [];
    for (let i = 1; i <= 15; i++) {
      try {
        const owner = await testContract.ownerOf(i);
        let domainData: any = { exists: true, tokenId: i, owner };

        try {
          const info = await testContract.getDomainInfo(i);
          const domain = `${info.name}.${info.tld}`;
          domainData = {
            ...domainData,
            domain,
            name: info.name,
            tld: info.tld,
            isSubdomain: info.isSubdomain,
            method: 'getDomainInfo'
          };
        } catch (domainInfoError) {
          try {
            const domain = await testContract.getDomainByTokenId(i);
            domainData = {
              ...domainData,
              domain,
              method: 'getDomainByTokenId'
            };
          } catch (domainByTokenError) {
            domainData = {
              ...domainData,
              error: `Both methods failed`,
              method: 'none'
            };
          }
        }

        tokenTests.push(domainData);
      } catch (error) {
        tokenTests.push({
          tokenId: i,
          error: error instanceof Error ? error.message : 'Unknown error',
          exists: false
        });
      }
    }

    tests.tokens = tokenTests;

    try {
      const globalDesc = await testContract.getGlobalDescription();
      tests.globalDescription = globalDesc;
    } catch (error) {
      tests.globalDescriptionError = error instanceof Error ? error.message : 'Unknown error';
    }

    return NextResponse.json(tests);
  } catch (error) {
    return NextResponse.json(
      {
        error: 'Contract test failed',
        details: error instanceof Error ? error.message : 'Unknown error',
        contractAddress: process.env.CONTRACT_ADDRESS,
        rpcUrl: process.env.AMOY_RPC ? 'Set' : 'NOT SET'
      },
      { status: 500 }
    );
  }
}