const fs = require("fs");
const readline = require("readline");
const { exec } = require("child_process");

const LOG_FILE = "gas.log";
const OUTPUT_FILE = "GAS_REPORT.md";
const CURRENT_REPORT_FILE = ".github/gas_report.json";
const DEV_REPORT_FILE = ".github/previous_gas_report.json"; // Temporary file for previous report

/**
 * Execute a shell command and return it as a Promise.
 * @param {string} command - Command to execute
 * @returns {Promise<string>} - Promise resolving to the command output
 */
function execPromise(command) {
  return new Promise((resolve, reject) => {
    exec(command, (error, stdout, stderr) => {
      if (error) {
        reject(error);
      } else {
        resolve(stdout || stderr);
      }
    });
  });
}

/**
 * Run forge test and log results to a file.
 * @returns {Promise<string>} - Promise resolving when the test completes
 */
function runForgeTest() {
  console.log("🧪 Running forge tests, this may take a few minutes...");
  return execPromise("forge test -vv --mt test_Gas > gas.log");
}

/**
 * Checkout the gas report file from the dev branch.
 * @returns {Promise<string|null>} - Promise resolving to the file path or null if not found
 */
async function checkoutDevBranchAndGetReport() {
  try {
    console.log(`🔄 Checking out ${CURRENT_REPORT_FILE} from dev branch...`);
    await execPromise(`git fetch origin dev && git checkout origin/dev -- ${CURRENT_REPORT_FILE}`);
    if (fs.existsSync(CURRENT_REPORT_FILE)) {
      console.log(`✅ Fetched ${CURRENT_REPORT_FILE} from dev branch.`);
      fs.renameSync(CURRENT_REPORT_FILE, DEV_REPORT_FILE);
      return DEV_REPORT_FILE;
    }
  } catch (error) {
    console.error(`❌ Could not fetch ${CURRENT_REPORT_FILE} from dev branch: ${error.message}`);
  }
  return null;
}

/**
 * Generate gas report from the test log.
 * @returns {Promise<Object[]>} - Promise resolving to the current gas report results
 */
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
    if (line.includes("::")) {
      const [number, protocol, actionFunction, , , gasInfo] = line.split("::");
      const accessType = gasInfo.split(": ")[0];
      const gasUsed = parseInt(gasInfo.split(": ")[1], 10);

      const accountType = line.includes("EOA") ? "EOA" : "Smart Account";
      const isDeployed = line.includes("Nexus") ? "True" : "False";
      const withPaymaster = line.includes("WithPaymaster") ? "True" : "False";
      const receiverAccess =
        accessType === "ColdAccess"
          ? "🧊 ColdAccess"
          : accessType === "WarmAccess"
          ? "🔥 WarmAccess"
          : "N/A";

      results.push({
        NUMBER: parseInt(number, 10),
        PROTOCOL: protocol.trim(),
        ACTION_FUNCTION: actionFunction.trim(),
        ACCOUNT_TYPE: accountType,
        IS_DEPLOYED: isDeployed,
        WITH_PAYMASTER: withPaymaster,
        RECEIVER_ACCESS: receiverAccess,
        GAS_USED: gasUsed,
      });
    }
  }

  console.log("🔄 Sorting results...");
  results.sort((a, b) => a.NUMBER - b.NUMBER);

  return results;
}

/**
 * Compare the current gas report with the previous report from the dev branch.
 * @returns {Promise<void>} - Promise resolving when the comparison is complete
 */
async function compareReports() {
  const previousReportFile = await checkoutDevBranchAndGetReport();

  if (!previousReportFile) {
    console.error("❌ No previous gas report found in dev branch.");
    return;
  }

  const prevData = fs.readFileSync(previousReportFile, "utf8");
  const prevResults = JSON.parse(prevData);
  const currResults = await generateReport();

  const diffLines = [
    "# Gas Report Comparison",
    "| **Protocol** | **Actions / Function** | **Account Type** | **Is Deployed** | **With Paymaster?** | **Receiver Access** | **Gas Used** | **Gas Difference** |",
    "|:------------:|:---------------------:|:----------------:|:--------------:|:-------------------:|:-------------------:|:------------:|:------------------:|",
  ];

  const diffResults = [];
  let hasDiff = false;

  currResults.forEach((curr) => {
    const prev = prevResults.find((prev) => prev.NUMBER === curr.NUMBER);
    if (prev) {
      const diff = curr.GAS_USED - prev.GAS_USED;
      const gasDiff =
        diff > 0 ? `🥵 +${diff}` : diff < 0 ? `🥳 -${Math.abs(diff)}` : "0";
      diffLines.push(
        `| ${curr.PROTOCOL} | ${curr.ACTION_FUNCTION} | ${curr.ACCOUNT_TYPE} | ${curr.IS_DEPLOYED} | ${curr.WITH_PAYMASTER} | ${curr.RECEIVER_ACCESS} | ${curr.GAS_USED} | ${gasDiff} |`
      );
      diffResults.push({
        ...curr,
        GAS_DIFFERENCE: gasDiff,
      });

      // Debugging logs
      if (diff !== 0) {
        hasDiff = true;
        console.log(
          `🔍 ${curr.PROTOCOL} - ${curr.ACTION_FUNCTION} (${curr.ACCOUNT_TYPE}, Deployed: ${curr.IS_DEPLOYED}, Paymaster: ${curr.WITH_PAYMASTER}): ${prev.GAS_USED} -> ${curr.GAS_USED} (${gasDiff})`
        );
      }
    } else {
      diffLines.push(
        `| ${curr.PROTOCOL} | ${curr.ACTION_FUNCTION} | ${curr.ACCOUNT_TYPE} | ${curr.IS_DEPLOYED} | ${curr.WITH_PAYMASTER} | ${curr.RECEIVER_ACCESS} | ${curr.GAS_USED} | N/A |`
      );
      diffResults.push({
        ...curr,
        GAS_DIFFERENCE: "N/A",
      });
    }
  });

  if (!hasDiff) {
    console.log("📉 No differences found.");
  } else {
    console.log("📈 Differences found and reported.");
  }

  fs.writeFileSync(CURRENT_REPORT_FILE, JSON.stringify(diffResults, null, 2));
  console.log(`📊 Gas report with differences saved to ${CURRENT_REPORT_FILE}`);

  fs.writeFileSync(OUTPUT_FILE, diffLines.join("\n"));
  console.log("📊 Gas report comparison generated and saved to GAS_REPORT.md");

  // Format with Prettier
  execPromise(`yarn prettier --write ${OUTPUT_FILE}`).then(() => {
    console.log("✨ Prettier formatting completed for GAS_REPORT.md");
  });

  // Clean up
  fs.unlink(LOG_FILE, (err) => {
    if (err) console.error(`❌ Error deleting ${LOG_FILE}: ${err}`);
    else console.log(`🗑️ ${LOG_FILE} deleted successfully.`);
  });

  // Remove the temporary previous gas report file
  fs.unlink(DEV_REPORT_FILE, (err) => {
    if (err) console.error(`❌ Error deleting ${DEV_REPORT_FILE}: ${err}`);
    else console.log(`🗑️ ${DEV_REPORT_FILE} deleted successfully.`);
  });
}

async function main() {
  try {
    await compareReports();
  } catch (error) {
    console.error(`❌ Error: ${error.message}`);
  }
}

main();
