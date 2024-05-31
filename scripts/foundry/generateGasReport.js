const fs = require('fs');
const readline = require('readline');
const { exec } = require('child_process');

// Define the log file, the output markdown file, and the previous report file
const LOG_FILE = 'gas.log';
const OUTPUT_FILE = 'GAS_REPORT.md';
const PREVIOUS_REPORT_FILE = 'gas_report.json';

// Function to execute the `forge test` command
function runForgeTest() {
    return new Promise((resolve, reject) => {
        console.log('🚀 Running forge tests, this may take a few minutes...');
        exec('forge test -vv --mt test_Gas > gas.log', (error, stdout, stderr) => {
            if (error) {
                console.error(`❌ Exec error: ${error}`);
                reject(`exec error: ${error}`);
            }
            console.log('✅ Forge tests completed.');
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
        crlfDelay: Infinity
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
            if (ACCESS_TYPE === 'ColdAccess') {
                RECEIVER_ACCESS = '🧊 ColdAccess';
            } else if (ACCESS_TYPE === 'WarmAccess') {
                RECEIVER_ACCESS = '🔥 WarmAccess';
            } else {
                RECEIVER_ACCESS = 'N/A';
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

    // Load the previous report if it exists
    let previousResults = [];
    if (fs.existsSync(PREVIOUS_REPORT_FILE)) {
        const previousData = fs.readFileSync(PREVIOUS_REPORT_FILE, 'utf8');
        previousResults = JSON.parse(previousData);
    }

    console.log('🔄 Sorting results...');
    // Sort by NUMBER
    results.sort((a, b) => a.NUMBER - b.NUMBER);

    // Calculate the difference in gas usage
    results.forEach(result => {
        const previousResult = previousResults.find(prev => prev.NUMBER === result.NUMBER);
        if (previousResult) {
            result.GAS_DIFF = result.GAS_USED - previousResult.GAS_USED;
            result.GAS_DIFF_EMOJI = result.GAS_DIFF > 0 ? '🥵' : (result.GAS_DIFF < 0 ? '🥳' : '');
        } else {
            result.GAS_DIFF = 0;
            result.GAS_DIFF_EMOJI = '';
        }
    });

    console.log('🖋️ Writing report...');
    // Write the report
    const outputStream = fs.createWriteStream(OUTPUT_FILE);
    outputStream.write("# Gas Report\n");
    outputStream.write("| **Protocol** | **Actions / Function** | **Account Type** | **Is Deployed** | **With Paymaster?** | **Receiver Access** | **Gas Used** | **Gas Difference** |\n");
    outputStream.write("|:------------:|:---------------------:|:----------------:|:--------------:|:-------------------:|:-------------------:|:------------:|:------------------:|\n");

    results.forEach(result => {
        const gasDiffDisplay = result.GAS_DIFF_EMOJI ? `${result.GAS_DIFF_EMOJI} ${result.GAS_DIFF}` : result.GAS_DIFF;
        outputStream.write(`| ${result.PROTOCOL} | ${result.ACTION_FUNCTION} | ${result.ACCOUNT_TYPE} | ${result.IS_DEPLOYED} | ${result.WITH_PAYMASTER} | ${result.RECEIVER_ACCESS} | ${result.GAS_USED} | ${gasDiffDisplay} |\n`);
    });

    // Save the current results as the previous results for next time
    fs.writeFileSync(PREVIOUS_REPORT_FILE, JSON.stringify(results, null, 2));

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
generateReport()
    .then(cleanUp)
    .catch(console.error);
