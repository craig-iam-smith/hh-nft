const { network, ethers } = require("hardhat")

module.exports = async ({ getNamedAccounts }) => {
    const { deployer } = await getNamedAccounts()
    const chainId = network.config.chainId

    // Basic NFT
    const basicNft = await ethers.getContract("BasicNft", deployer)
    const basicMintTx = await basicNft.mintNft()
    await basicMintTx.wait(1)
    console.log(`Basic NFT index 0 tokenURI: ${await basicNft.tokenURI(0)}`)

    // Dynamic SVG  NFT
    const highValue = ethers.utils.parseEther("4000")
    const dynamicSvgNft = await ethers.getContract("DynamicSvgNft", deployer)
    const dynamicSvgNftMintTx = await dynamicSvgNft.mintNft(highValue)
    await dynamicSvgNftMintTx.wait(1)
    console.log(`Dynamic SVG NFT index 0 tokenURI: ${await dynamicSvgNft.tokenURI(0)}`)

    // Random IPFS NFT
    console.log('before get contract')
    const randomIpfsNft = await ethers.getContract("RandomIpfsNft", deployer)
    console.log('before get mint fee')
    const mintFee = await randomIpfsNft.getMintFee()
    console.log(mintFee)
    console.log('before mint')
    const randomIpfsNftMintTx = await randomIpfsNft.requestNft({ value: mintFee.toString() })
    console.log('before wait nft')
    const randomIpfsNftMintTxReceipt = await randomIpfsNftMintTx.wait(1)
    console.log('after wait tx receipt')
    // Need to listen for response
    await new Promise(async (resolve, reject) => {
        setTimeout(() => reject("Timeout: 'NFTMinted' event did not fire"), 300000) // 5 minute timeout time
        // setup listener for our event
        randomIpfsNft.once("NftMinted", async () => {
            resolve()
        })
        if (chainId == 31337) {
            const requestId = randomIpfsNftMintTxReceipt.events[1].args.requestId.toString()
            const vrfCoordinatorV2Mock = await ethers.getContract("VRFCoordinatorV2Mock", deployer)
            await vrfCoordinatorV2Mock.fulfillRandomWords(requestId, randomIpfsNft.address)
        }
    })
    console.log(`Random IPFS NFT index 0 tokenURI: ${await randomIpfsNft.tokenURI(0)}`)

    // Dynamic SVG NFT
//    const highValue = ethers.utils.parseEther("4000")
//    const dynamicSvgNft = await ethers.getContract("DynamicSvgNft", deployer)
//    const dynamicSvgNftMintTx
}
module.exports.tags = ["all", "mint"]