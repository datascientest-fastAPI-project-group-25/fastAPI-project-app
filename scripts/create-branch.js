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

// Parse command line arguments
function parseArgs() {
  const args = process.argv.slice(2);
  const result = {
    branchType: null,
    branchName: null,
    automerge: false,
    nonInteractive: false,
  };

  for (let i = 0; i < args.length; i++) {
    if (args[i] === "--type" || args[i] === "-t") {
      result.branchType = args[i + 1];
      i++;
    } else if (args[i] === "--name" || args[i] === "-n") {
      result.branchName = args[i + 1];
      i++;
    } else if (args[i] === "--automerge" || args[i] === "-a") {
      result.automerge = true;
    } else if (args[i] === "--non-interactive") {
      result.nonInteractive = true;
    }
  }

  // Validate branch type
  if (result.branchType && !["feat", "fix"].includes(result.branchType)) {
    console.error(
      chalk.red('Error: Branch type must be either "feat" or "fix"'),
    );
    process.exit(1);
  }

  // Validate branch name if provided
  if (result.branchName && !/^[a-z0-9-_]+$/i.test(result.branchName)) {
    console.error(
      chalk.red(
        "Error: Branch name should only contain letters, numbers, hyphens, and underscores",
      ),
    );
    process.exit(1);
  }

  return result;
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

// Interactive branch creation using inquirer
async function interactiveBranchCreation() {
  if (!inquirer) {
    console.error(
      chalk.red(
        'Error: Inquirer is required for interactive mode. Install it with "npm install inquirer" or use non-interactive mode.',
      ),
    );
    console.log(
      chalk.yellow(
        "Example: node create-branch.js --type fix --name my-fix-name --automerge",
      ),
    );
    process.exit(1);
  }

  console.log(
    `${colors.green}✨ Interactive Branch Creation Tool ✨${colors.reset}`,
  );
  console.log(
    `${colors.cyan}This tool will help you create a new branch following our branching strategy.${colors.reset}`,
  );

  try {
    const answers = await inquirer.prompt([
      {
        type: "list",
        name: "branchType",
        message: "What type of branch do you want to create?",
        choices: [
          { name: "🚀 Feature branch (feat/)", value: "feat" },
          { name: "🔧 Fix branch (fix/)", value: "fix" },
        ],
      },
      {
        type: "input",
        name: "branchName",
        message: "Enter a descriptive name for your branch (without prefix):",
        validate: (input) => {
          if (input.trim() === "") {
            return "Branch name cannot be empty";
          }
          if (!/^[a-z0-9-_]+$/i.test(input)) {
            return "Branch name should only contain letters, numbers, hyphens, and underscores";
          }
          return true;
        },
      },
      {
        type: "confirm",
        name: "automerge",
        message: "Enable automerge for this branch? (Only for fix branches)",
        default: false,
        when: (answers) => answers.branchType === "fix",
      },
    ]);

    return createBranchWithParams(
      answers.branchType,
      answers.branchName,
      answers.automerge,
    );
  } catch (error) {
    console.error(
      chalk.red("An error occurred during interactive prompt:"),
      error.message,
    );
    console.log(chalk.yellow("Try using non-interactive mode:"));
    console.log(
      "node create-branch.js --type fix --name my-fix-name --automerge",
    );
    return false;
  }
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
