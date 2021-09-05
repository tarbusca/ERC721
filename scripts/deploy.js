const hre = require("hardhat");

async function main() {
  
	const [deployer] = await hre.ethers.getSigners();
	
  console.log("Deploying contracts with the account:", deployer.address);


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.

const myERC721  = await hre.ethers.getContractFactory("myERC721");
const Ttoken  = await myERC721.deploy();

await Ttoken.deployed();

  console.log("ERC721 Token deployed to:", Ttoken.address);
}
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
