const fs = require("fs");
const readline = require("readline");
const { exec } = require("child_process");

// Define the log file and the output markdown file
const LOG_FILE = "gas.log";
const OUTPUT_FILE = "gas_report.md";

// Function to execute the `forge test` command
function runForgeTest() {
  return new Promise((resolve, reject) => {
    console.log("🚀 Running forge tests, this may take a few minutes...");
    exec("forge test -vv --mt test_Gas > gas.log", (error, stdout, stderr) => {
      if (error) {
        console.error(`❌ Exec error: ${error}`);
        reject(`exec error: ${error}`);
      }
      console.log("✅ Forge tests completed.");
      resolve(stdout ? stdout : stderr);
    });
  });
}

// Function to parse the log file and generate the report
async function generateReport() {
  await runForgeTest();

  const fileStream = fs.createReadStream(LOG_FILE);
  const rl = readline.createInterface({
    input: fileStream,
    crlfDelay: Infinity,
  });

  const results = [];

  console.log("📄 Parsing log file, please wait...");
  for await (const line of rl) {
    console.log(line);
    if (line.includes("::")) {
      const parts = line.split("::");
      const PROTOCOL = parts[0];
      const ACTION_FUNCTION = parts[1];
      let ACCOUNT_TYPE;
      let IS_DEPLOYED;
      if (line.includes("EOA")) {
        ACCOUNT_TYPE = "EOA";
        IS_DEPLOYED = "False";
      } else if (line.includes("Nexus")) {
        ACCOUNT_TYPE = "Smart Account";
        IS_DEPLOYED = "True";
      } else {
        ACCOUNT_TYPE = "Smart Account";
        IS_DEPLOYED = "False";
      }

      const WITH_PAYMASTER = line.includes("WithPaymaster") ? "True" : "False";

      const GAS_INFO = parts[4];
      const ACCESS_TYPE = GAS_INFO.split(": ")[0];
      const GAS_USED = GAS_INFO.split(": ")[1];

      let RECEIVER_ACCESS;
      if (ACCESS_TYPE === "ColdAccess") {
        RECEIVER_ACCESS = "🧊 ColdAccess";
      } else if (ACCESS_TYPE === "WarmAccess") {
        RECEIVER_ACCESS = "🔥 WarmAccess";
      } else {
        RECEIVER_ACCESS = "N/A";
      }

      results.push({
        PROTOCOL,
        ACTION_FUNCTION,
        ACCOUNT_TYPE,
        IS_DEPLOYED,
        WITH_PAYMASTER,
        RECEIVER_ACCESS,
        GAS_USED,
        FULL_LOG: line.trim(),
      });
    }
  }

  console.log("🔄 Sorting results...");
  // Custom sort: Group by protocol alphabetically, then by EOA first, Smart Account with Is Deployed=True next, then the rest
  results.sort((a, b) => {
    if (a.PROTOCOL < b.PROTOCOL) return -1;
    if (a.PROTOCOL > b.PROTOCOL) return 1;
    if (a.ACCOUNT_TYPE === "EOA" && b.ACCOUNT_TYPE !== "EOA") return -1;
    if (a.ACCOUNT_TYPE !== "EOA" && b.ACCOUNT_TYPE === "EOA") return 1;
    if (a.IS_DEPLOYED === "True" && b.IS_DEPLOYED !== "True") return -1;
    if (a.IS_DEPLOYED !== "True" && b.IS_DEPLOYED === "True") return 1;
    return 0;
  });

  console.log("🖋️ Writing report...");
  // Write the report
  const outputStream = fs.createWriteStream(OUTPUT_FILE);
  outputStream.write("# Gas Report\n");
  outputStream.write(
    "| **Protocol** | **Actions / Function** | **Account Type** | **Is Deployed** | **With Paymaster?** | **Receiver Access** | **Gas Used** | **Full Log** |\n",
  );
  outputStream.write(
    "|:------------:|:---------------------:|:----------------:|:--------------:|:-------------------:|:-------------------:|:------------:|:-------------:|\n",
  );

  results.forEach((result) => {
    outputStream.write(
      `| ${result.PROTOCOL} | ${result.ACTION_FUNCTION} | ${result.ACCOUNT_TYPE} | ${result.IS_DEPLOYED} | ${result.WITH_PAYMASTER} | ${result.RECEIVER_ACCESS} | ${result.GAS_USED} | ${result.FULL_LOG} |\n`,
    );
  });

  console.log(`📊 Gas report generated and saved to ${OUTPUT_FILE}`);
}

// Function to clean up temporary files
function cleanUp() {
  fs.unlink(LOG_FILE, (err) => {
    if (err) console.error(`❌ Error deleting ${LOG_FILE}: ${err}`);
    else console.log(`🗑️ ${LOG_FILE} deleted successfully.`);
  });
}

// Run the function to generate the report and then clean up
generateReport().then(cleanUp).catch(console.error);
