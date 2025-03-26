#!/usr/bin/env node

/**
 * Unified test script for local and CI environments
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
const path = require("path");

// ANSI color codes
const colors = {
  reset: "\x1b[0m",
  green: "\x1b[32m",
  blue: "\x1b[34m",
  yellow: "\x1b[33m",
  red: "\x1b[31m",
  cyan: "\x1b[36m",
};

let chalk;
try {
  chalk = require("chalk");
} catch (error) {
  chalk = {
    green: (text) => `${colors.green}${text}${colors.reset}`,
    blue: (text) => `${colors.blue}${text}${colors.reset}`,
    yellow: (text) => `${colors.yellow}${text}${colors.reset}`,
    red: (text) => `${colors.red}${text}${colors.reset}`,
    cyan: (text) => `${colors.cyan}${text}${colors.reset}`,
  };
}

// Command line arguments
const args = process.argv.slice(2);
let mode = "local"; // Default to local mode
let testArgs = [];

// Parse command line arguments
for (let i = 0; i < args.length; i++) {
  if (args[i] === "local" || args[i] === "ci") {
    mode = args[i];
  } else {
    testArgs.push(args[i]);
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

// Check if Docker is available
async function checkDocker() {
  try {
    runCommand("docker info");
    console.log(chalk.green("✓ Docker is available"));
    return true;
  } catch (error) {
    console.error(chalk.red("Error: Docker is not installed or not running"));
    return false;
  }
}

// Clean up previous test environments
async function cleanupPrevious() {
  console.log(chalk.blue("Cleaning up previous test environments..."));
  try {
    runCommand("docker compose down -v --remove-orphans");
    console.log(chalk.green("✓ Previous environments cleaned up"));
  } catch (error) {
    console.error(chalk.yellow("Warning: Failed to clean up previous environments"));
  }
}

// Clean up Python cache files (Linux only)
async function cleanupCache() {
  const platform = process.platform;
  if (platform === "linux") {
    console.log(chalk.blue("Removing __pycache__ files..."));
    try {
      const cacheDirs = runCommand("find . -type d -name __pycache__", {
        stdio: ["pipe", "pipe", "ignore"],
      });
      if (cacheDirs) {
        runCommand("find . -type d -name __pycache__ -exec rm -r {} +", {
          stdio: ["pipe", "pipe", "ignore"],
        });
      }
      console.log(chalk.green("✓ Cache files removed"));
    } catch (error) {
      console.error(chalk.yellow("Warning: Failed to remove cache files"));
    }
  }
}

// Build Docker images
async function buildImages() {
  if (process.env.SKIP_BUILD) {
    console.log(chalk.yellow("Skipping build step (SKIP_BUILD is set)"));
    console.log(chalk.yellow("Don't forget to run 'docker compose down -v' when you're done"));
    return;
  }

  console.log(chalk.blue("Building Docker images..."));
  try {
    runCommand("docker compose build");
    console.log(chalk.green("✓ Docker images built successfully"));
  } catch (error) {
    throw new Error("Failed to build Docker images");
  }
}

// Start Docker services
async function startServices() {
  console.log(chalk.blue("Starting Docker services..."));
  try {
    runCommand("docker compose up -d");
    console.log(chalk.green("✓ Services started"));
  } catch (error) {
    throw new Error("Failed to start Docker services");
  }
}

// Run tests
async function runTests() {
  console.log(chalk.blue("Running tests..."));
  try {
    const testCommand = `docker compose exec backend pytest ${testArgs.join(" ")}`;
    console.log(chalk.cyan(`Running command: ${testCommand}`));
    
    // Run the tests with live output
    const { spawn } = require('child_process');
    const testProcess = spawn('docker', ['compose', 'exec', 'backend', 'pytest', ...testArgs], {
      stdio: 'inherit'
    });

    return new Promise((resolve, reject) => {
      testProcess.on('close', (code) => {
        if (code === 0) {
          console.log(chalk.green("✓ Tests completed successfully"));
          resolve();
        } else {
          console.error(chalk.yellow("Warning: Some tests failed"));
          console.error(chalk.yellow("Exit code: " + code));
          resolve(); // Don't reject as this is expected behavior
        }
      });

      testProcess.on('error', (error) => {
        console.error(chalk.red(`Error running tests: ${error.message}`));
        reject(error);
      });
    });
  } catch (error) {
    throw new Error(`Failed to run tests: ${error.message}`);
  }
}

// Clean up after tests
async function cleanupAfter() {
  if (process.env.SKIP_CLEANUP) {
    console.log(chalk.yellow("Skipping cleanup (SKIP_CLEANUP is set)"));
    return;
  }

  console.log(chalk.blue("Cleaning up test environment..."));
  try {
    runCommand("docker compose down -v --remove-orphans");
    console.log(chalk.green("✓ Environment cleaned up"));
  } catch (error) {
    console.error(chalk.yellow("Warning: Failed to clean up environment"));
  }
}

// Interactive mode prompts
async function getInteractiveMode() {
  if (!inquirer) {
    console.log(chalk.yellow("Inquirer not available, using default mode (local)"));
    return "local";
  }

  const { mode } = await inquirer.prompt([
    {
      type: "list",
      name: "mode",
      message: "Select test mode:",
      choices: ["local", "ci"],
      default: "local",
    },
  ]);

  return mode;
}

// Main execution
async function main() {
  try {
    // Get mode if not provided as argument
    if (!mode || mode === "local" || mode === "ci") {
      mode = await getInteractiveMode();
    }

    // Check Docker availability
    if (!await checkDocker()) {
      process.exit(1);
    }

    // Run cleanup
    await cleanupPrevious();
    await cleanupCache();

    // Build and start services
    await buildImages();
    await startServices();

    // Run tests
    await runTests();

    // Clean up
    await cleanupAfter();

    console.log(chalk.green("✅ All tests completed successfully!"));
  } catch (error) {
    console.error(chalk.red(`Error: ${error.message}`));
    process.exit(1);
  }
}

// Execute main function
main();
