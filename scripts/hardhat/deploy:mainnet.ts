import { deployToMainnet } from "./deployToMainnet";

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
deployToMainnet()
  .then(() => {
    process.exit(0);
  })
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
