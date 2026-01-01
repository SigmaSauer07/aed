import { getContract, getGlobalDescription } from './contract';

const DOMAIN_BG = 'https://moccasin-obvious-mongoose-68.mypinata.cloud/ipfs/bafybeib5jf536bbe7x44kmgvxm6nntlxpzuexg5x7spzwzi6gfqwmkkj5m/domain_background.png';
const SUB_BG = 'https://moccasin-obvious-mongoose-68.mypinata.cloud/ipfs/bafybeib5jf536bbe7x44kmgvxm6nntlxpzuexg5x7spzwzi6gfqwmkkj5m/subdomain_background.png';

export async function buildMetadata(tokenId: bigint, isSub: boolean) {
  const contract = getContract();
  const globalDesc = getGlobalDescription();

  if (!contract) {
    throw new Error('Contract not initialized');
  }

  try {
    const owner = await contract.ownerOf(tokenId);
    console.log(`Building metadata for token ${tokenId}, owner: ${owner}`);

    let domainName = '';
    let domainInfo: any = null;
    let isSubdomain = false;

    try {
      domainInfo = await contract.getDomainInfo(tokenId);
      console.log(`Domain info for ${tokenId}:`, domainInfo);

      domainName = `${domainInfo.name}.${domainInfo.tld}`;
      isSubdomain = domainInfo.isSubdomain;

      console.log(`Constructed domain name: ${domainName}, isSubdomain: ${isSubdomain}`);
    } catch (domainInfoError) {
      console.log(`getDomainInfo failed for ${tokenId}`);

      try {
        domainName = await contract.getDomainByTokenId(tokenId);
        console.log(`Got domain name from getDomainByTokenId: ${domainName}`);
        isSubdomain = (domainName.split('.').length > 2);
      } catch (domainByTokenError) {
        console.log(`getDomainByTokenId also failed for ${tokenId}`);

        try {
          const tokenURI = await contract.tokenURI(tokenId);
          if (tokenURI && tokenURI.startsWith('data:application/json;base64,')) {
            const jsonString = Buffer.from(tokenURI.split(',')[1], 'base64').toString();
            const metadata = JSON.parse(jsonString);
            domainName = metadata.name || `domain${tokenId}`;
            isSubdomain = metadata.attributes?.some((attr: any) =>
              attr.trait_type === 'Type' && attr.value === 'Subdomain'
            ) || domainName.includes('.');
            console.log(`Extracted from tokenURI - name: ${domainName}, isSubdomain: ${isSubdomain}`);
          }
        } catch (tokenURIError) {
          console.log(`TokenURI parsing failed for ${tokenId}`);
          domainName = `domain${tokenId}`;
          isSubdomain = isSub;
        }
      }
    }

    if (!domainName || domainName === '') {
      domainName = `domain${tokenId}`;
    }

    const metadata: any = {
      name: domainName,
      description: globalDesc || "Alsania Enhanced Domain",
      external_url: `https://alsania.io/domain/${domainName}`,
      image: isSubdomain ? SUB_BG : DOMAIN_BG,
      attributes: [
        { trait_type: 'Token ID', value: tokenId.toString() },
        { trait_type: 'Owner', value: owner },
        { trait_type: 'Type', value: isSubdomain ? 'Subdomain' : 'Domain' },
        { trait_type: 'Contract', value: 'Alsania Enhanced Domains' }
      ]
    };

    if (domainInfo) {
      metadata.attributes.push(
        { trait_type: 'TLD', value: domainInfo.tld },
        { trait_type: 'Subdomain Count', value: domainInfo.subdomainCount.toString() }
      );

      if (domainInfo.subdomainCount > 0) {
        metadata.attributes.push({ trait_type: 'Has Subdomains', value: 'true' });
      }
    }

    try {
      const evolutionLevel = await contract.getEvolutionLevel(tokenId);
      const fragmentCount = await contract.getFragmentCount(tokenId);

      metadata.attributes.push(
        { trait_type: 'Evolution Level', value: evolutionLevel.toString() },
        { trait_type: 'Fragments Earned', value: fragmentCount.toString() }
      );

      try {
        const fragments = await contract.getTokenFragments(tokenId);
        if (fragments && fragments.length > 0) {
          const fragmentTypes = fragments.map((f: any) => f.fragmentType).join(', ');
          metadata.attributes.push({
            trait_type: 'Fragment Types',
            value: fragmentTypes
          });
        }
      } catch (fragmentError) {
        console.log(`Could not fetch fragment details for ${tokenId}`);
      }

      console.log(`Evolution data for ${tokenId}: Level ${evolutionLevel}, ${fragmentCount} fragments`);
    } catch (evolutionError) {
      console.log(`Could not fetch evolution data for ${tokenId}`);
    }

    console.log(`Final metadata for ${tokenId}:`, metadata);
    return metadata;

  } catch (error) {
    console.error(`Error building metadata for ${tokenId}:`, error);
    return {
      name: `Domain #${tokenId}`,
      description: globalDesc || "Alsania Enhanced Domain",
      external_url: `https://www.alsania-io.com/aed`,
      image: isSub ? SUB_BG : DOMAIN_BG,
      attributes: [
        { trait_type: 'Token ID', value: tokenId.toString() },
        { trait_type: 'Type', value: isSub ? 'Subdomain' : 'Domain' },
        { trait_type: 'Contract', value: 'Alsania Enhanced Domains' }
      ]
    };
  }
}