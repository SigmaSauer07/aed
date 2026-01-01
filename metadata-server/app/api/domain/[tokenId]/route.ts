import { NextRequest, NextResponse } from 'next/server';
import { buildMetadata } from '@/lib/metadata';

export async function GET(
  request: NextRequest,
  { params }: { params: { tokenId: string } }
) {
  try {
    const tokenId = BigInt(params.tokenId);
    const metadata = await buildMetadata(tokenId, false);
    
    return NextResponse.json(metadata, {
      headers: {
        'Content-Type': 'application/json',
        'Cache-Control': 'public, max-age=300, s-maxage=3600',
      },
    });
  } catch (error) {
    console.error('Domain metadata error:', error);
    return NextResponse.json(
      { error: 'failed', details: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    );
  }
}