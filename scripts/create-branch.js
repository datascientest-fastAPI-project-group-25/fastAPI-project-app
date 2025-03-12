#!/usr/bin/env node

/**
 * Interactive branch creation CLI
 * Uses Inquirer for a modern, interactive command-line interface
 */

const inquirer = require('inquirer');
const { execSync } = require('child_process');
const chalk = require('chalk') || { green: (text) => text, yellow: (text) => text, red: (text) => text, blue: (text) => text };

// ANSI color codes as fallback if chalk is not available
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  red: '\x1b[31m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m',
};

// Helper function to run git commands
function runGitCommand(command) {
  try {
    return execSync(command, { encoding: 'utf8' }).trim();
  } catch (error) {
    console.error(`${colors.red}Error executing git command:${colors.reset}`, error.message);
    process.exit(1);
  }
}

// Ensure we're up to date with main
console.log(`${colors.blue}Updating main branch...${colors.reset}`);
try {
  runGitCommand('git fetch origin');
  runGitCommand('git checkout main');
  runGitCommand('git pull origin main');
} catch (error) {
  console.error(`${colors.red}Failed to update main branch:${colors.reset}`, error.message);
  console.log(`${colors.yellow}Continuing with branch creation anyway...${colors.reset}`);
}

// Start the interactive prompt
async function createBranch() {
  console.log(`${colors.green}✨ Interactive Branch Creation Tool ✨${colors.reset}`);
  console.log(`${colors.cyan}This tool will help you create a new branch following our branching strategy.${colors.reset}`);

  const answers = await inquirer.prompt([
    {
      type: 'list',
      name: 'branchType',
      message: 'What type of branch do you want to create?',
      choices: [
        { name: '🚀 Feature branch (feat/)', value: 'feat' },
        { name: '🔧 Fix branch (fix/)', value: 'fix' }
      ]
    },
    {
      type: 'input',
      name: 'branchName',
      message: 'Enter a descriptive name for your branch (without prefix):',
      validate: (input) => {
        if (input.trim() === '') {
          return 'Branch name cannot be empty';
        }
        if (!/^[a-z0-9-_]+$/i.test(input)) {
          return 'Branch name should only contain letters, numbers, hyphens, and underscores';
        }
        return true;
      }
    },
    {
      type: 'confirm',
      name: 'automerge',
      message: 'Enable automerge for this branch? (Only for fix branches)',
      default: false,
      when: (answers) => answers.branchType === 'fix'
    }
  ]);

  // Format the branch name
  let fullBranchName = `${answers.branchType}/${answers.branchName}`;
  if (answers.branchType === 'fix' && answers.automerge) {
    fullBranchName += '-automerge';
  }

  // Create the branch
  try {
    runGitCommand(`git checkout -b ${fullBranchName}`);
    console.log(`\n${colors.green}✅ Successfully created branch: ${colors.reset}${fullBranchName}`);

    // Show helpful information
    console.log(`\n${colors.cyan}Next steps:${colors.reset}`);
    console.log(`1. Make your changes`);
    console.log(`2. Commit your changes with a meaningful message`);
    console.log(`3. Push your branch with: ${colors.yellow}git push -u origin ${fullBranchName}${colors.reset}`);

    if (answers.branchType === 'feat') {
      console.log(`\n${colors.magenta}Note: ${colors.reset}Feature branches will increment the minor version (0.1.0 → 0.2.0)`);
    } else {
      console.log(`\n${colors.magenta}Note: ${colors.reset}Fix branches will increment the patch version (0.1.0 → 0.1.1)`);
      if (answers.automerge) {
        console.log(`${colors.magenta}Automerge: ${colors.reset}This branch will automatically merge after tests pass`);
      } else {
        console.log(`${colors.magenta}Manual approval: ${colors.reset}This branch will require approval before merging`);
      }
    }
  } catch (error) {
    console.error(`${colors.red}Failed to create branch:${colors.reset}`, error.message);
    process.exit(1);
  }
}

createBranch().catch(error => {
  console.error(`${colors.red}An error occurred:${colors.reset}`, error);
  process.exit(1);
});
