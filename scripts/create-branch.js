#!/usr/bin/env node

/**
 * Interactive branch creation CLI
 * Uses Inquirer for a modern, interactive command-line interface
 */

// Try to load dependencies, but provide fallbacks if they're not available
let inquirer;
try {
  inquirer = require("inquirer");
} catch (error) {
  console.log("Inquirer not found, using fallback for non-interactive mode");
}
const { execSync } = require("child_process");
const readline = require("readline");

// ANSI color codes as fallback if chalk is not available
const colors = {
  reset: "\x1b[0m",
  green: "\x1b[32m",
  yellow: "\x1b[33m",
  red: "\x1b[31m",
  blue: "\x1b[34m",
  magenta: "\x1b[35m",
  cyan: "\x1b[36m",
};

// Try to load chalk, but use fallback colors if not available
let chalk;
try {
  chalk = require("chalk");
} catch (error) {
  chalk = {
    green: (text) => `${colors.green}${text}${colors.reset}`,
    yellow: (text) => `${colors.yellow}${text}${colors.reset}`,
    red: (text) => `${colors.red}${text}${colors.reset}`,
    blue: (text) => `${colors.blue}${text}${colors.reset}`,
    magenta: (text) => `${colors.magenta}${text}${colors.reset}`,
    cyan: (text) => `${colors.cyan}${text}${colors.reset}`,
  };
}

// Command line arguments
const args = process.argv.slice(2);
let branchType = "";
let branchName = "";
let automerge = false;

// Parse command line arguments
for (let i = 0; i < args.length; i++) {
  switch (args[i]) {
    case "--type":
      branchType = args[++i];
      break;
    case "--name":
      branchName = args[++i];
      break;
    case "--automerge":
      automerge = true;
      break;
  }
}

// Create readline interface
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
});

// Branch types
const branchTypes = [
  "feat",
  "fix",
  "docs",
  "style",
  "refactor",
  "perf",
  "test",
  "build",
  "ci",
  "chore",
  "revert",
];

// Function to validate branch name
function isValidBranchName(name) {
  return /^[a-z0-9-]+$/.test(name);
}

// Helper function to run git commands
function runGitCommand(command) {
  try {
    return execSync(command, { encoding: "utf8" }).trim();
  } catch (error) {
    console.error(
      `${colors.red}Error executing git command:${colors.reset}`,
      error.message,
    );
    process.exit(1);
  }
}

// Create branch with the given parameters
function createBranchWithParams(branchType, branchName, automerge) {
  // Format the branch name
  let fullBranchName = `${branchType}/${branchName}`;
  if (branchType === "fix" && automerge) {
    fullBranchName += "-automerge";
  }

  // Create the branch
  try {
    runGitCommand(`git checkout -b ${fullBranchName}`);
    console.log(
      `\n${colors.green}✅ Successfully created branch: ${colors.reset}${fullBranchName}`,
    );

    // Show helpful information
    console.log(`\n${colors.cyan}Next steps:${colors.reset}`);
    console.log(`1. Make your changes`);
    console.log(`2. Commit your changes with a meaningful message`);
    console.log(
      `3. Push your branch with: ${colors.yellow}git push -u origin ${fullBranchName}${colors.reset}`,
    );

    if (branchType === "feat") {
      console.log(
        `\n${colors.magenta}Note: ${colors.reset}Feature branches will increment the minor version (0.1.0 → 0.2.0)`,
      );
    } else {
      console.log(
        `\n${colors.magenta}Note: ${colors.reset}Fix branches will increment the patch version (0.1.0 → 0.1.1)`,
      );
      if (automerge) {
        console.log(
          `${colors.magenta}Automerge: ${colors.reset}This branch will automatically merge after tests pass`,
        );
      } else {
        console.log(
          `${colors.magenta}Manual approval: ${colors.reset}This branch will require approval before merging`,
        );
      }
    }
    return true;
  } catch (error) {
    console.error(
      `${colors.red}Failed to create branch:${colors.reset}`,
      error.message,
    );
    return false;
  }
}

// Ensure we're up to date with main
async function updateMainBranch() {
  console.log(`${colors.blue}Updating main branch...${colors.reset}`);
  try {
    runGitCommand("git fetch origin");
    runGitCommand("git checkout main");
    runGitCommand("git pull origin main");
    return true;
  } catch (error) {
    console.error(
      `${colors.red}Failed to update main branch:${colors.reset}`,
      error.message,
    );
    console.log(
      `${colors.yellow}Continuing with branch creation anyway...${colors.reset}`,
    );
    return false;
  }
}

// Interactive branch creation if no arguments provided
if (!branchType || !branchName) {
  console.log("Interactive Branch Creation\n");

  // Ask for branch type
  rl.question(`Branch type (${branchTypes.join(", ")}): `, (type) => {
    if (!branchTypes.includes(type)) {
      console.error("Invalid branch type");
      rl.close();
      process.exit(1);
    }

    // Ask for branch name
    rl.question(
      "Branch name (lowercase letters, numbers, and hyphens only): ",
      (name) => {
        if (!isValidBranchName(name)) {
          console.error("Invalid branch name");
          rl.close();
          process.exit(1);
        }

        // Ask for automerge
        rl.question("Enable automerge? (y/N): ", (answer) => {
          const enableAutomerge = answer.toLowerCase() === "y";
          rl.close();
          createBranchWithParams(type, name, enableAutomerge);
        });
      },
    );
  });
} else {
  // Non-interactive branch creation
  if (!branchTypes.includes(branchType)) {
    console.error("Invalid branch type");
    process.exit(1);
  }

  if (!isValidBranchName(branchName)) {
    console.error("Invalid branch name");
    process.exit(1);
  }

  createBranchWithParams(branchType, branchName, automerge);
}

// Main function
async function main() {
  const args = parseArgs();

  // Update main branch first
  await updateMainBranch();

  // If we have all required parameters or non-interactive mode is forced, use them
  if ((args.branchType && args.branchName) || args.nonInteractive) {
    if (!args.branchType || !args.branchName) {
      console.error(
        chalk.red(
          "Error: Both branch type and name are required in non-interactive mode",
        ),
      );
      console.log(
        chalk.yellow(
          "Example: node create-branch.js --type fix --name my-fix-name --automerge",
        ),
      );
      process.exit(1);
    }
    return createBranchWithParams(
      args.branchType,
      args.branchName,
      args.automerge,
    );
  }

  // Otherwise use interactive mode
  return interactiveBranchCreation();
}

// Run the main function
main()
  .then((success) => {
    if (!success) {
      process.exit(1);
    }
  })
  .catch((error) => {
    console.error(chalk.red("An unexpected error occurred:"), error);
    process.exit(1);
  });
