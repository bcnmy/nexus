const fs = require('fs');
const readline = require('readline');
const { exec } = require('child_process');

const LOG_FILE = 'gas.log';
const OUTPUT_FILE = 'GAS_REPORT.md';
const CURRENT_REPORT_FILE = '.github/gas_report.json';

const REPORT_FILES = [
  'gas_report.json',
  'previous_gas_report.json',
  '.github/gas_report.json',
  '.github/previous_gas_report.json'
];

function execPromise(command) {
  return new Promise((resolve, reject) => {
    exec(command, (error, stdout, stderr) => {
      if (error) {
        reject(error);
      } else {
        resolve(stdout ? stdout : stderr);
      }
    });
  });
}

function runForgeTest() {
  return execPromise("forge test -vv --mt test_Gas > gas.log");
}

async function checkoutDevBranchAndGetReport() {
  for (const file of REPORT_FILES) {
    try {
      console.log(`🔄 Checking out ${file} from dev branch...`);
      await execPromise(`git fetch origin dev && git checkout origin/dev -- ${file}`);
      if (fs.existsSync(file)) {
        console.log(`✅ Fetched ${file} from dev branch.`);
        return file;
      }
    } catch (error) {
      console.error(`❌ Could not fetch ${file} from dev branch.`);
    }
  }
  return null;
}

async function generateReport() {
  await runForgeTest();

  const fileStream = fs.createReadStream(LOG_FILE);
  const rl = readline.createInterface({
    input: fileStream,
    crlfDelay: Infinity,
  });

  const results = [];

  console.log('📄 Parsing log file, please wait...');
  for await (const line of rl) {
    if (line.includes('::')) {
      const parts = line.split('::');
      const number = parseInt(parts[0], 10);
      const PROTOCOL = parts[1];
      const ACTION_FUNCTION = parts[2];
      const GAS_INFO = parts[parts.length - 1];
      const ACCESS_TYPE = GAS_INFO.split(': ')[0];
      const GAS_USED = parseInt(GAS_INFO.split(': ')[1], 10);

      let ACCOUNT_TYPE;
      let IS_DEPLOYED;
      if (line.includes('EOA')) {
        ACCOUNT_TYPE = 'EOA';
        IS_DEPLOYED = 'False';
      } else if (line.includes('Nexus')) {
        ACCOUNT_TYPE = 'Smart Account';
        IS_DEPLOYED = 'True';
      } else {
        ACCOUNT_TYPE = 'Smart Account';
        IS_DEPLOYED = 'False';
      }

      const WITH_PAYMASTER = line.includes('WithPaymaster') ? 'True' : 'False';

      let RECEIVER_ACCESS;
      if (ACCESS_TYPE === "ColdAccess") {
        RECEIVER_ACCESS = "🧊 ColdAccess";
      } else if (ACCESS_TYPE === "WarmAccess") {
        RECEIVER_ACCESS = "🔥 WarmAccess";
      } else {
        RECEIVER_ACCESS = "N/A";
      }

      results.push({
        NUMBER: number,
        PROTOCOL,
        ACTION_FUNCTION,
        ACCOUNT_TYPE,
        IS_DEPLOYED,
        WITH_PAYMASTER,
        RECEIVER_ACCESS,
        GAS_USED
      });
    }
  }

  console.log('🔄 Sorting results...');
  results.sort((a, b) => a.NUMBER - b.NUMBER);

  fs.writeFileSync(CURRENT_REPORT_FILE, JSON.stringify(results, null, 2));
  console.log(`📊 Current gas report generated and saved to ${CURRENT_REPORT_FILE}`);
  return results;
}

async function compareReports() {
  const previousReportFile = await checkoutDevBranchAndGetReport();

  if (!previousReportFile) {
    console.error('❌ No previous gas report found in dev branch.');
    return;
  }

  const prevData = fs.readFileSync(previousReportFile, 'utf8');
  const prevResults = JSON.parse(prevData);
  const currResults = JSON.parse(fs.readFileSync(CURRENT_REPORT_FILE, 'utf8'));

  const diffLines = [
    '# Gas Report Comparison',
    '| **Protocol** | **Actions / Function** | **Account Type** | **Is Deployed** | **With Paymaster?** | **Receiver Access** | **Gas Used** | **Gas Difference** |',
    '|:------------:|:---------------------:|:----------------:|:--------------:|:-------------------:|:-------------------:|:------------:|:------------------:|'
  ];

  let hasDiff = false;

  currResults.forEach(curr => {
    const prev = prevResults.find(prev => prev.NUMBER === curr.NUMBER);
    if (prev) {
      const diff = curr.GAS_USED - prev.GAS_USED;
      if (diff !== 0) {
        hasDiff = true;
        const gasDiff = diff > 0 ? `🥵 +${diff}` : `🥳 ${diff}`;
        diffLines.push(`| ${curr.PROTOCOL} | ${curr.ACTION_FUNCTION} | ${curr.ACCOUNT_TYPE} | ${curr.IS_DEPLOYED} | ${curr.WITH_PAYMASTER} | ${curr.RECEIVER_ACCESS} | ${curr.GAS_USED} | ${gasDiff} |`);
        console.log(`🔍 ${curr.ACTION_FUNCTION} (${curr.ACCOUNT_TYPE}, ${curr.IS_DEPLOYED}, ${curr.WITH_PAYMASTER}): ${prev.GAS_USED} -> ${curr.GAS_USED} (${gasDiff})`);
      }
    }
  });

  fs.writeFileSync(OUTPUT_FILE, diffLines.join('\n'));
  console.log('📊 Gas report comparison generated and saved to GAS_REPORT.md');

  if (hasDiff) {
    console.log('📈 Differences found and reported.');
  } else {
    console.log('📉 No differences found.');
  }
}

async function main() {
  await generateReport();
  await compareReports();
}

main().catch(console.error);
