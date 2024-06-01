const fs = require('fs');

function compareGasReports(prevFile, currFile) {
    if (!fs.existsSync(prevFile)) {
        console.error('No previous gas report found.');
        return 'No previous gas report found. Skipping comparison.';
    }

    const prevData = fs.readFileSync(prevFile, 'utf8');
    const currData = fs.readFileSync(currFile, 'utf8');

    const prevLines = prevData.split('\n');
    const currLines = currData.split('\n');

    const diffLines = [
        '# Gas Report Comparison',
        '| **Protocol** | **Actions / Function** | **Account Type** | **Is Deployed** | **With Paymaster?** | **Receiver Access** | **Gas Used** | **Gas Difference** |',
        '|:------------:|:---------------------:|:----------------:|:--------------:|:-------------------:|:-------------------:|:------------:|:------------------:|'
    ];

    const prevResults = parseGasReport(prevLines);
    const currResults = parseGasReport(currLines);

    currResults.forEach(curr => {
        const prev = prevResults.find(prev => prev.NUMBER === curr.NUMBER);
        let gasDiff = '0';
        let gasDiffEmoji = '';

        if (prev) {
            const diff = curr.GAS_USED - prev.GAS_USED;
            gasDiff = diff.toString();
            gasDiffEmoji = diff > 0 ? '🥵' : (diff < 0 ? '🥳' : '');
        }

        diffLines.push(`| ${curr.PROTOCOL} | ${curr.ACTION_FUNCTION} | ${curr.ACCOUNT_TYPE} | ${curr.IS_DEPLOYED} | ${curr.WITH_PAYMASTER} | ${curr.RECEIVER_ACCESS} | ${curr.GAS_USED} | ${gasDiffEmoji} ${gasDiff} |`);
    });

    return diffLines.join('\n');
}

function parseGasReport(lines) {
    const results = [];
    for (const line of lines) {
        if (line.startsWith('|')) {
            const parts = line.split('|').map(part => part.trim());
            if (parts.length === 9 && !parts[0].includes('**')) {
                results.push({
                    PROTOCOL: parts[1],
                    ACTION_FUNCTION: parts[2],
                    ACCOUNT_TYPE: parts[3],
                    IS_DEPLOYED: parts[4],
                    WITH_PAYMASTER: parts[5],
                    RECEIVER_ACCESS: parts[6],
                    GAS_USED: parseInt(parts[7], 10),
                    NUMBER: parseInt(parts[7], 10)
                });
            }
        }
    }
    return results;
}

if (process.argv.length !== 4) {
    console.error('Usage: node compareGasReports.js <previous_gas_report> <current_gas_report>');
    process.exit(1);
}

const previousFile = process.argv[2];
const currentFile = process.argv[3];

const comparison = compareGasReports(previousFile, currentFile);
console.log(comparison);
