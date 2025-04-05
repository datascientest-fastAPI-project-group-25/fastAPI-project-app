#!/usr/bin/env node

/**
 * Test application runner
 * Provides a unified interface for running tests in local or CI environments
 */

import { execSync, spawn } from 'child_process';
import readline from 'readline';

// ANSI color codes
const colors = {
  reset: "\x1b[0m",
  green: "\x1b[32m",
  yellow: "\x1b[33m",
  red: "\x1b[31m",
  blue: "\x1b[34m",
  cyan: "\x1b[36m",
};

type TestMode = 'local' | 'ci';

// Command line arguments
const args = process.argv.slice(2);
let mode: TestMode = "local"; // Default to local mode
let testArgs: string[] = [];

// Parse command line arguments
for (let i = 0; i < args.length; i++) {
  if (args[i] === "local" || args[i] === "ci") {
    mode = args[i] as TestMode;
  } else {
    testArgs.push(args[i]);
  }
}

// Run a command and return its output
export function runCommand(command: string): string {
  try {
    return execSync(command, { encoding: 'utf8' });
  } catch (error) {
    console.error(`${colors.red}Command failed: ${command}${colors.reset}`);
    console.error(`${colors.red}${(error as Error).message}${colors.reset}`);
    throw error;
  }
}

// Check if Docker is available
export async function checkDocker(): Promise<boolean> {
  try {
    runCommand("docker --version");
    console.log(`${colors.green}✓ Docker is available${colors.reset}`);
    return true;
  } catch (error) {
    console.error(`${colors.red}Error: Docker is not available${colors.reset}`);
    console.error(`${colors.yellow}Please install Docker and try again${colors.reset}`);
    return false;
  }
}

// Get interactive mode
export async function getInteractiveMode(): Promise<TestMode> {
  return new Promise((resolve) => {
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout
    });

    rl.question(`${colors.blue}Select test mode (local/ci): ${colors.reset}`, (answer) => {
      rl.close();
      if (answer === "local" || answer === "ci") {
        resolve(answer as TestMode);
      } else {
        console.log(`${colors.yellow}Invalid mode, defaulting to local${colors.reset}`);
        resolve("local");
      }
    });
  });
}

// Clean up previous test runs
export async function cleanupPrevious(): Promise<void> {
  console.log(`${colors.blue}Cleaning up previous test runs...${colors.reset}`);
  try {
    runCommand("docker compose down -v");
    console.log(`${colors.green}✓ Previous containers cleaned up${colors.reset}`);
  } catch (error) {
    console.log(`${colors.yellow}No previous containers to clean up${colors.reset}`);
  }
}

// Clean up Python cache files
export async function cleanupCache(): Promise<void> {
  console.log(`${colors.blue}Cleaning up cache files...${colors.reset}`);
  try {
    runCommand("find . -type d -name __pycache__ -exec rm -rf {} +");
    runCommand("find . -type d -name .pytest_cache -exec rm -rf {} +");
    console.log(`${colors.green}✓ Cache files cleaned up${colors.reset}`);
  } catch (error) {
    console.log(`${colors.yellow}Error cleaning cache files${colors.reset}`);
  }
}

// Build Docker images
export async function buildImages(): Promise<void> {
  console.log(`${colors.blue}Building Docker images...${colors.reset}`);
  try {
    runCommand("docker compose build");
    console.log(`${colors.green}✓ Images built${colors.reset}`);
  } catch (error) {
    throw new Error("Failed to build Docker images");
  }
}

// Start Docker services
export async function startServices(): Promise<void> {
  console.log(`${colors.blue}Starting Docker services...${colors.reset}`);
  try {
    runCommand("docker compose up -d");
    console.log(`${colors.green}✓ Services started${colors.reset}`);
  } catch (error) {
    throw new Error("Failed to start Docker services");
  }
}

// Run tests
export async function runTests(): Promise<void> {
  console.log(`${colors.blue}Running tests...${colors.reset}`);
  try {
    const testCommand = `docker compose exec backend pytest ${testArgs.join(" ")}`;
    console.log(`${colors.cyan}Running command: ${testCommand}${colors.reset}`);

    // Run the tests with live output
    const testProcess = spawn('docker', ['compose', 'exec', 'backend', 'pytest', ...testArgs], {
      stdio: 'inherit'
    });

    return new Promise((resolve, reject) => {
      testProcess.on('close', (code) => {
        if (code === 0) {
          console.log(`${colors.green}✓ Tests completed successfully${colors.reset}`);
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
export async function cleanupAfter(testMode: TestMode): Promise<void> {
  if (testMode === "ci") {
    console.log(`${colors.blue}Cleaning up after tests...${colors.reset}`);
    try {
      runCommand("docker compose down -v");
      console.log(`${colors.green}✓ Cleanup complete${colors.reset}`);
    } catch (error) {
      console.log(`${colors.yellow}Error during cleanup${colors.reset}`);
    }
  } else {
    console.log(`${colors.blue}Keeping services running for local development${colors.reset}`);
  }
}

// Main execution
async function main(): Promise<void> {
  try {
    // Get mode if not provided as argument
    if (!mode) {
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
    await cleanupAfter(mode);

    console.log(`${colors.green}✅ All tests completed successfully!${colors.reset}`);
  } catch (error) {
    console.error(`${colors.red}Error: ${(error as Error).message}${colors.reset}`);
    process.exit(1);
  }
}

// Run the main function
if (require.main === module) {
  main();
}
