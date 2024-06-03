const fs = require("fs");
const readline = require("readline");
const { exec } = require("child_process");

const LOG_FILE = "gas.log";
const OUTPUT_FILE = "GAS_REPORT.md";
const PREVIOUS_REPORT_FILE = ".github/previous_gas_report.json";
const CURRENT_REPORT_FILE = ".github/current_gas_report.json";
const REPORT_FILES = [".github/gas_report.json"];

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
 * Backup the current gas report file.
 * @returns {Promise<void>}
 */
async function backupCurrentGasReport() {
  if (fs.existsSync(REPORT_FILES[0])) {
    fs.copyFileSync(REPORT_FILES[0], CURRENT_REPORT_FILE);
    console.log(`✅ Current gas report backed up to ${CURRENT_REPORT_FILE}.`);
  }
}

/**
 * Checkout the gas report file from the dev branch.
 * @returns {Promise<string|null>} - Promise resolving to the file path or null if not found
 */
async function checkoutDevBranchAndGetReport() {
  for (const file of REPORT_FILES) {
    try {
      console.log(`🔄 Checking out ${file} from dev branch...`);
      await execPromise(`git fetch origin dev && git checkout origin/dev -- ${file}`);
      if (fs.existsSync(file)) {
        console.log(`✅ Fetched ${file} from dev branch.`);
        fs.renameSync(file, PREVIOUS_REPORT_FILE);
        console.log(`✅ Previous gas report saved to ${PREVIOUS_REPORT_FILE}.`);
        return PREVIOUS_REPORT_FILE;
      }
    } catch (error) {
      console.error(`❌ Could not fetch ${file} from dev branch.`);
    }
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
      const [number, PROTOCOL, ACTION_FUNCTION, , , GAS_INFO] =
        line.split("::");
      const ACCESS_TYPE = GAS_INFO.split(": ")[0];
      const GAS_USED = parseInt(GAS_INFO.split(": ")[1], 10);

      const ACCOUNT_TYPE = line.includes("EOA") ? "EOA" : "Smart Account";
      const IS_DEPLOYED = line.includes("Nexus") ? "True" : "False";
      const WITH_PAYMASTER = line.includes("WithPaymaster") ? "True" : "False";
      const RECEIVER_ACCESS =
        ACCESS_TYPE === "ColdAccess"
          ? "🧊 ColdAccess"
          : ACCESS_TYPE === "WarmAccess"
          ? "🔥 WarmAccess"
          : "N/A";

      results.push({
        NUMBER: parseInt(number, 10),
        PROTOCOL,
        ACTION_FUNCTION,
        ACCOUNT_TYPE,
        IS_DEPLOYED,
        WITH_PAYMASTER,
        RECEIVER_ACCESS,
        GAS_USED,
      });
    }
  }

  console.log("🔄 Sorting results...");
  results.sort((a, b) => a.NUMBER - b.NUMBER);

  fs.writeFileSync(CURRENT_REPORT_FILE, JSON.stringify(results, null, 2));
  console.log(`📊 Current gas report generated and saved to ${CURRENT_REPORT_FILE}`);
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
  const currResults = JSON.parse(fs.readFileSync(CURRENT_REPORT_FILE, "utf8"));

  const diffLines = [
    "# Gas Report Comparison",
    "| **Protocol** | **Actions / Function** | **Account Type** | **Is Deployed** | **With Paymaster?** | **Receiver Access** | **Gas Used** | **Gas Difference** |",
    "|:------------:|:---------------------:|:----------------:|:--------------:|:-------------------:|:-------------------:|:------------:|:------------------:|",
  ];

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
      if (diff !== 0) {
        hasDiff = true;
        console.log(
          `🔍 ${curr.PROTOCOL} - ${curr.ACTION_FUNCTION} (${curr.ACCOUNT_TYPE}, Deployed: ${curr.IS_DEPLOYED}, Paymaster: ${curr.WITH_PAYMASTER}): ${prev.GAS_USED} -> ${curr.GAS_USED} (${gasDiff})`
        );
      }
    }
  });

  if (!hasDiff) {
    diffLines.push("| No differences found in gas usage. |");
    console.log("📉 No differences found.");
  } else {
    console.log("📈 Differences found and reported.");
  }

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

  fs.unlink(PREVIOUS_REPORT_FILE, (err) => {
    if (err) console.error(`❌ Error deleting ${PREVIOUS_REPORT_FILE}: ${err}`);
    else console.log(`🗑️ ${PREVIOUS_REPORT_FILE} deleted successfully.`);
  });
}

async function main() {
  await backupCurrentGasReport();
  await generateReport();
  await compareReports();
}

main().catch(console.error);
