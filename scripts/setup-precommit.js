#!/usr/bin/env node

/**
 * Interactive pre-commit setup CLI
 * Supports both interactive and non-interactive modes
 */

// Try to load dependencies
let inquirer;
try {
  inquirer = require("inquirer");
} catch (error) {
  console.log("Inquirer not found, using fallback for non-interactive mode");
}

const { execSync } = require("child_process");
const readline = require("readline");

// ANSI color codes
const colors = {
  reset: "\x1b[0m",
  green: "\x1b[32m",
  yellow: "\x1b[33m",
  red: "\x1b[31m",
  blue: "\x1b[34m",
  magenta: "\x1b[35m",
  cyan: "\x1b[36m",
};

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
let force = false;

// Parse command line arguments
for (let i = 0; i < args.length; i++) {
  switch (args[i]) {
    case "--force":
      force = true;
      break;
  }
}

// Helper function to run commands
function runCommand(command, options = {}) {
  try {
    return execSync(command, {
      encoding: "utf8",
      stdio: ["pipe", "pipe", "pipe"],
      ...options,
    }).trim();
  } catch (error) {
    console.error(chalk.red(`Error executing command: ${error.message}`));
    throw error;
  }
}

// Check if pre-commit is installed
async function checkPreCommit() {
  try {
    runCommand("pre-commit --version");
    console.log(chalk.green("✓ pre-commit is installed"));
    return true;
  } catch (error) {
    return false;
  }
}

// Install pre-commit using pip
async function installWithPip() {
  try {
    console.log(chalk.blue("Installing pre-commit with pip..."));
    runCommand("pip install pre-commit");
    console.log(chalk.green("✓ pre-commit installed with pip"));
    return true;
  } catch (error) {
    return false;
  }
}

// Install pre-commit using pip3
async function installWithPip3() {
  try {
    console.log(chalk.blue("Installing pre-commit with pip3..."));
    runCommand("pip3 install pre-commit");
    console.log(chalk.green("✓ pre-commit installed with pip3"));
    return true;
  } catch (error) {
    return false;
  }
}

// Install pre-commit using brew
async function installWithBrew() {
  try {
    console.log(chalk.blue("Installing pre-commit with brew..."));
    runCommand("brew install pre-commit");
    console.log(chalk.green("✓ pre-commit installed with brew"));
    return true;
  } catch (error) {
    return false;
  }
}

// Install pre-commit
async function installPreCommit() {
  if (await installWithPip()) return true;
  if (await installWithPip3()) return true;
  if (await installWithBrew()) return true;

  console.error(chalk.red("Error: Could not install pre-commit"));
  console.error(chalk.yellow("Please install pip or brew first"));
  return false;
}

// Install git hooks
async function installGitHooks() {
  try {
    // Check if hooksPath is set
    const hooksPath = runCommand("git config --get core.hooksPath", { 
      stdio: ["pipe", "pipe", "ignore"],
      encoding: "utf8"
    }).trim();

    if (hooksPath) {
      console.log(chalk.yellow(`Found core.hooksPath: ${hooksPath}`));
      console.log(chalk.yellow("Unsetting core.hooksPath to install pre-commit hooks..."));
      runCommand("git config --unset-all core.hooksPath");
    }

    console.log(chalk.blue("Installing git hooks with pre-commit..."));
    runCommand("pre-commit install --hook-type pre-commit --hook-type commit-msg --hook-type pre-push");
    console.log(chalk.green("✓ Git hooks installed successfully"));
    return true;
  } catch (error) {
    console.error(chalk.red("Error installing git hooks"));
    console.error(chalk.yellow("You may need to run this command manually:"));
    console.error(chalk.yellow("git config --unset-all core.hooksPath"));
    console.error(chalk.yellow("pre-commit install --hook-type pre-commit --hook-type commit-msg --hook-type pre-push"));
    return false;
  }
}

// Interactive mode prompts
async function getInteractiveMode() {
  if (!inquirer) {
    console.log(chalk.yellow("Inquirer not available, using non-interactive mode"));
    return true;
  }

  const { proceed } = await inquirer.prompt([
    {
      type: "confirm",
      name: "proceed",
      message: "pre-commit is not installed. Would you like to install it?",
      default: true,
    },
  ]);

  return proceed;
}

// Main execution
async function main() {
  try {
    // Check if pre-commit is installed
    const isInstalled = await checkPreCommit();

    if (!isInstalled) {
      // Ask for installation if not installed
      if (force || await getInteractiveMode()) {
        if (!await installPreCommit()) {
          process.exit(1);
        }
      }
    }

    // Install git hooks
    if (!await installGitHooks()) {
      process.exit(1);
    }

    console.log(chalk.green("✅ Git hooks have been successfully installed!"));
    console.log(chalk.blue("🚀 You're all set to start developing with automatic code quality checks."));

  } catch (error) {
    console.error(chalk.red(`Error: ${error.message}`));
    process.exit(1);
  }
}

// Execute main function
main();
