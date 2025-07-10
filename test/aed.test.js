const AED = await ethers.getContractAt("AED", "placeholder_address_here");
const ADMIN_ROLE = await AED.ADMIN_ROLE();
await AED.hasRole(ADMIN_ROLE, "placeholder_address_here");
