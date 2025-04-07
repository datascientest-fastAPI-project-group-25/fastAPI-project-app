#!/usr/bin/env node

/**
 * Test application runner
 * Provides a unified interface for running tests in local or CI environments
 */

const { execSync, spawn } = require('child_process');
const readline = require('readline');

// ANSI color codes
const colors = {
  reset: "\x1b[0m",
  green: "\x1b[32m",
  yellow: "\x1b[33m",
  red: "\x1b[31m",
  blue: "\x1b[34m",
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

// Run a command and return its output
function runCommand(command) {
  try {
    return execSync(command, { encoding: 'utf8' });
  } catch (error) {
    console.error(chalk.red(`Command failed: ${command}`));
    console.error(chalk.red(error.message));
    throw error;
  }
}

// Check if Docker is available
async function checkDocker() {
  try {
    runCommand("docker --version");
    console.log(chalk.green("✓ Docker is available"));
    return true;
  } catch (error) {
    console.error(chalk.red("Error: Docker is not available"));
    console.error(chalk.yellow("Please install Docker and try again"));
    return false;
  }
}

// Get interactive mode
async function getInteractiveMode() {
  return new Promise((resolve) => {
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout
    });

    rl.question(chalk.blue("Select test mode (local/ci): "), (answer) => {
      rl.close();
      if (answer === "local" || answer === "ci") {
        resolve(answer);
      } else {
        console.log(chalk.yellow("Invalid mode, defaulting to local"));
        resolve("local");
      }
    });
  });
}

// Clean up previous test runs
async function cleanupPrevious() {
  console.log(chalk.blue("Cleaning up previous test runs..."));
  try {
    runCommand("docker compose down -v");
    console.log(chalk.green("✓ Previous containers cleaned up"));
  } catch (error) {
    console.log(chalk.yellow("No previous containers to clean up"));
  }
}

// Clean up Python cache files
async function cleanupCache() {
  console.log(chalk.blue("Cleaning up cache files..."));
  try {
    runCommand("find . -type d -name __pycache__ -exec rm -rf {} +");
    runCommand("find . -type d -name .pytest_cache -exec rm -rf {} +");
    console.log(chalk.green("✓ Cache files cleaned up"));
  } catch (error) {
    console.log(chalk.yellow("Error cleaning cache files"));
  }
}

// Build Docker images
async function buildImages() {
  console.log(chalk.blue("Building Docker images..."));
  try {
    runCommand("docker compose build");
    console.log(chalk.green("✓ Images built"));
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
          reject(new Error(`Tests failed with exit code ${code}`));
        }
      });
    });
  } catch (error) {
    throw new Error("Failed to run tests");
  }
}

// Clean up after tests
async function cleanupAfter() {
  if (mode === "ci") {
    console.log(chalk.blue("Cleaning up after tests..."));
    try {
      runCommand("docker compose down -v");
      console.log(chalk.green("✓ Cleanup complete"));
    } catch (error) {
      console.log(chalk.yellow("Error during cleanup"));
    }
  } else {
    console.log(chalk.blue("Keeping services running for local development"));
  }
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
