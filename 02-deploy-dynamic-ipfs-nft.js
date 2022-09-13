const { AlchemyWebSocketProvider } = require("@ethersproject/providers")
const { deployMockContract } = require("ethereum-waffle")
const fs = require("fs-extra")
const { network, getNamedAccounts, deployments, ethers } = require("hardhat")
const { developmentChains, networkConfig } = require("../helper-hardhat-config")
const { verify } = require("../utils/verify")
let  ethUsdPriceFeedAddress
module.exports = async function({getNamedAccounts, deployments}) {
    const {deploy, log} = deployments
    const { deployer } = await getNamedAccounts()
    const chainId = network.config.chainId

    if (developmentChains.includes(network.name)) {
        const EthUsdAggregator = await ethers.getContract("MockV3Aggregator")
        ethUsdPriceFeedAddress = EthUsdAggregator.address;
    } else {
        ethUsdPriceFeedAddress = networkConfig[chainId].ethUsdPriceFeedAddress
    }
    log("*********")
//    const lowSVG = fs.readFileSync("./images/dynamicNFT/frown.svg", { encoding: "utf8" })
//    const highSVG = fs.readFileSync("./images/dynamicNFT/happy.svg", { encoding: "utf8" })
    const lowSVG = fs.readFileSync("./frown.svg", { encoding: "utf8" })
    const highSVG = fs.readFileSync("./happy.svg", { encoding: "utf8" })
    console.log(ethUsdPriceFeedAddress)
arguments = [ethUsdPriceFeedAddress, lowSVG, highSVG]
    const dynamicSvgNft = await deploy("DynamicSvgNft", {
        from: deployer,
        args: arguments,
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1,
    })

        // Verify the deployment
    if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
        log("Verifying...")
        await verify(dynamicSvgNft.address, args)
    }
}

module.exports.tags = ["all", "dynamicsvg", "main"]
