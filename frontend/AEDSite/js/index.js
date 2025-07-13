const CONTRACT_ADDRESS = '0x3Bf795D47f7B32f36cbB1222805b0E0c5EF066f1';
let provider, signer, AED;

async function connectWallet() {
    provider = new ethers.providers.Web3Provider(window.ethereum, "any");
    await provider.send("eth_requestAccounts", []);
    signer = provider.getSigner();
    const abi = await fetch('js/aedABI.json').then(r => r.json());
    AED = new ethers.Contract(CONTRACT_ADDRESS, abi, signer);
    const address = await signer.getAddress();
    document.getElementById("wallet").innerText = "Wallet: " + address;
    await updatePricePreview(); // fetch on load
}

async function updatePricePreview() {
    const tld = document.getElementById("tld").value;
    const subEnh = document.getElementById("enhSubdomain").checked;

    try {
        const tldPrice = await AED.getTLDPrice(tld);
        const subFee = subEnh ? ethers.utils.parseEther("2") : ethers.BigNumber.from(0);
        const total = tldPrice.add(subFee);
        document.getElementById("feePreview").innerText = ethers.utils.formatEther(total) + " MATIC";
    } catch (err) {
        document.getElementById("feePreview").innerText = "Error fetching fee";
        console.error(err);
    }
}

async function registerDomain() {
    if (!AED) return alert("❌ Connect your wallet first.");
    const name = document.getElementById("domainName").value.trim();
    const tld = document.getElementById("tld").value;
    const enh = document.getElementById("enhSubdomain").checked;
    if (!name || !tld) return alert("❌ Name or TLD missing");

    try {
        const tldPrice = await AED.getTLDPrice(tld);
        const subFee = enh ? ethers.utils.parseEther("2") : ethers.BigNumber.from(0);
        const totalFee = tldPrice.add(subFee);
        const duration = ethers.BigNumber.from("3153600000"); // 100 years

        // callStatic check
        await AED.callStatic.registerDomain(name, tld, subFee, enh, duration, { value: totalFee });

        // Estimate gas
        let gasLimit;
        try {
            const est = await AED.estimateGas.registerDomain(name, tld, subFee, enh, duration, { value: totalFee });
            gasLimit = est.mul(12).div(10);
        } catch {
            gasLimit = ethers.BigNumber.from(500000);
        }

        const tx = await AED.registerDomain(name, tld, subFee, enh, duration, { value: totalFee, gasLimit });
        const receipt = await tx.wait();
        alert("✅ Registered! Tx: " + receipt.transactionHash);
    } catch (err) {
        console.error(err);
        alert("❌ Failed: " + (err.reason || err.message));
    }
}

window.addEventListener("DOMContentLoaded", () => {
    document.getElementById("connectBtn").onclick = connectWallet;
    document.getElementById("tld").onchange = updatePricePreview;
    document.getElementById("enhSubdomain").onchange = updatePricePreview;
    document.getElementById("registerBtn").onclick = registerDomain;
});