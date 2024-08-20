import { deployContractsAndSAFixture } from "../../test/hardhat/utils/deployment";

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
deployContractsAndSAFixture()
	.then(() => {
		process.exit(0);
	})
	.catch((error) => {
		console.error(error);
		process.exitCode = 1;
	});
