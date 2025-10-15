const fs = require('fs');
const path = require('path');

/**
 * Utility function to resolve address files in a consistent manner
 * @param {string} filename - Name of the address file
 * @returns {object} Parsed addresses object
 */
function resolveAddresses(filename) {
  const currentDir = process.cwd();
  const scriptDir = __dirname;

  // Try different possible locations
  const possiblePaths = [
    path.join(currentDir, filename),           // Current working directory
    path.join(scriptDir, '..', filename),      // Project root (relative to scripts)
    path.join(scriptDir, filename),            // Scripts directory
    path.join(scriptDir, '..', 'amoy-upgradeable-addresses.json'), // Fallback
  ];

  for (const filePath of possiblePaths) {
    if (fs.existsSync(filePath)) {
      console.log(`📋 Using addresses from: ${path.relative(currentDir, filePath)}`);
      return JSON.parse(fs.readFileSync(filePath, 'utf8'));
    }
  }

  throw new Error(`❌ Address file '${filename}' not found in any of the expected locations`);
}

/**
 * Get the most recent/relevant address file
 * Priority: secure > upgradeable > others
 */
function getLatestAddresses() {
  const addressFiles = [
    'amoy-addresses-secure.json',
    'amoy-upgradeable-addresses.json',
    'amoy-addresses.json',
    'upgradeable-addresses.json'
  ];

  for (const filename of addressFiles) {
    try {
      return resolveAddresses(filename);
    } catch (error) {
      // Continue to next file
    }
  }

  throw new Error('❌ No address files found. Please deploy a contract first.');
}

module.exports = {
  resolveAddresses,
  getLatestAddresses
};