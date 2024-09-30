import { deployToTestnet } from "./deployToTestnet";

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
deployToTestnet()
  .then(() => {
    process.exit(0);
  })
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
