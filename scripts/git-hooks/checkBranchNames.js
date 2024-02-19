// Use Node.js APIs to execute shell commands and handle logic
const execSync = require('child_process').execSync;
const branchName = execSync('git branch --show-current').toString().trim();
const pattern = /^(feat\/|fix\/|release\/|chore\/)/;
const ignoreBranches = /^(main|dev)$/;

if (!ignoreBranches.test(branchName) && !pattern.test(branchName)) {
  console.error('🛑 ERROR: Your branch name does not meet the required pattern (feat/, fix/, release/, chore/).');
  process.exit(1);
} else {
    console.log('✅ SUCCESS: Your branch name meets the required pattern.');
    process.exit(0);
}
