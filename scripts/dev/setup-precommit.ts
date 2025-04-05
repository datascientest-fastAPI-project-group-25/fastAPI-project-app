#!/usr/bin/env node

/**
 * Pre-commit setup script
 * Installs and configures pre-commit hooks for the project
 */

import { execSync } from 'child_process';
import readline from 'readline';

// ANSI color codes
const colors = {
  reset: "\x1b[0m",
  green: "\x1b[32m",
  yellow: "\x1b[33m",
  red: "\x1b[31m",
  blue: "\x1b[34m",
};

// Command line arguments
const args = process.argv.slice(2);
const force = args.includes("--force") || args.includes("-f");

// Run a command and return its output
export function runCommand(command: string): string {
  try {
    return execSync(command, { encoding: 'utf8' });
  } catch (error) {
    throw new Error(`Command failed: ${command}\n${(error as Error).message}`);
  }
}

// Check if pre-commit is installed
export async function checkPreCommit(): Promise<boolean> {
  try {
    runCommand("pre-commit --version");
    console.log(`${colors.green}✓ pre-commit is already installed${colors.reset}`);
    return true;
  } catch (error) {
    console.log(`${colors.yellow}pre-commit is not installed${colors.reset}`);
    return false;
  }
}

// Get interactive mode
export async function getInteractiveMode(): Promise<boolean> {
  return new Promise((resolve) => {
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout
    });

    rl.question(`${colors.blue}Would you like to install pre-commit? (y/N): ${colors.reset}`, (answer) => {
      rl.close();
      resolve(answer.toLowerCase() === "y");
    });
  });
}

// Install pre-commit using pip
export async function installWithPip(): Promise<boolean> {
  try {
    console.log(`${colors.blue}Installing pre-commit with pip...${colors.reset}`);
    runCommand("pip install pre-commit");
    console.log(`${colors.green}✓ pre-commit installed with pip${colors.reset}`);
    return true;
  } catch (error) {
    return false;
  }
}

// Install pre-commit using pip3
export async function installWithPip3(): Promise<boolean> {
  try {
    console.log(`${colors.blue}Installing pre-commit with pip3...${colors.reset}`);
    runCommand("pip3 install pre-commit");
    console.log(`${colors.green}✓ pre-commit installed with pip3${colors.reset}`);
    return true;
  } catch (error) {
    return false;
  }
}

// Install pre-commit using brew
export async function installWithBrew(): Promise<boolean> {
  try {
    console.log(`${colors.blue}Installing pre-commit with brew...${colors.reset}`);
    runCommand("brew install pre-commit");
    console.log(`${colors.green}✓ pre-commit installed with brew${colors.reset}`);
    return true;
  } catch (error) {
    return false;
  }
}

// Install pre-commit
export async function installPreCommit(): Promise<boolean> {
  if (await installWithPip()) return true;
  if (await installWithPip3()) return true;
  if (await installWithBrew()) return true;

  console.error(`${colors.red}Error: Could not install pre-commit${colors.reset}`);
  console.error(`${colors.yellow}Please install pip or brew first${colors.reset}`);
  return false;
}

// Install git hooks
export async function installGitHooks(): Promise<boolean> {
  try {
    console.log(`${colors.blue}Installing git hooks with pre-commit...${colors.reset}`);
    runCommand("pre-commit install --hook-type pre-commit --hook-type commit-msg --hook-type pre-push");
    console.log(`${colors.green}✓ Git hooks installed successfully${colors.reset}`);
    return true;
  } catch (error) {
    console.error(`${colors.red}Error installing git hooks${colors.reset}`);
    console.error(`${colors.yellow}You may need to run this command manually:${colors.reset}`);
    console.error(`${colors.yellow}git config --unset-all core.hooksPath${colors.reset}`);
    console.error(`${colors.yellow}pre-commit install --hook-type pre-commit --hook-type commit-msg --hook-type pre-push${colors.reset}`);
    return false;
  }
}

// Main execution
async function main(): Promise<void> {
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

    console.log(`${colors.green}✅ Git hooks have been successfully installed!${colors.reset}`);
    console.log(`${colors.blue}🚀 You're all set to start developing with automatic code quality checks.${colors.reset}`);

  } catch (error) {
    console.error(`${colors.red}Error: ${(error as Error).message}${colors.reset}`);
    process.exit(1);
  }
}

// Execute main function
if (require.main === module) {
  main();
}
