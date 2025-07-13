import abi from './aedABI.json' assert {type:'json'};
const address = '0xF331AA1dAe471c2e77C1ed98dB36bC2e25f36D9f';
let provider, signer, AED;

async function connect(){
 if(!window.ethereum) return alert('Install MetaMask');
 provider = new ethers.providers.Web3Provider(window.ethereum);
 await provider.send('eth_requestAccounts',[]);
 signer = provider.getSigner();
 AED = new ethers.Contract(address, abi, signer);
 document.getElementById('wallet').innerText='Wallet: '+await signer.getAddress();
}
window.addEventListener('load', connect);

async function registerFree(){
 const name=document.getElementById('domainName').value;
 const tld=document.getElementById('tld').value;
 const price=await AED.renewalPrice();
 const huge=3153600000; // 100 years free tier
 const tx=await AED.registerDomain(name,tld,0,false,huge,{value: price.mul(huge)});
 await tx.wait();
 alert('Domain registered!');
}
async function upgrade(){
 alert('Upgrade feature coming soon – requires contract support.');
}
async function subscribe(){
 alert('Subscription feature coming soon – requires contract support.');
}
