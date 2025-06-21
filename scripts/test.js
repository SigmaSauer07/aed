const AED = await ethers.getContractAt("AED", "0xF331AA1dAe471c2e77C1ed98dB36bC2e25f36D9f");
const ADMIN_ROLE = await AED.ADMIN_ROLE();
await AED.hasRole(ADMIN_ROLE, "0xe49dabf7237776c3edd9524206c0e4330ba0e170")
