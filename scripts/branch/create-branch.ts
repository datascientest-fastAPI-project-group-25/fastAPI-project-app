#!/usr/bin/env node

/**
 * Interactive branch creation CLI
 * Updated for new workflow (feat/fix → dev → main)
 */

import { execSync } from 'child_process';
import readline from 'readline';
import { paramCase } from '../utils';

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

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
});

const branchTypes = ["feat", "fix"];

export function runGitCommand(command: string): string {
  try {
    return execSync(command, { encoding: "utf8" }).trim();
  } catch (error) {
    console.error(
      `${colors.red}Error executing git command:${colors.reset}`,
      (error as Error).message,
    );
    process.exit(1);
  }
}

export async function updateDevBranch(): Promise<boolean> {
  console.log(`${colors.blue}Updating dev branch...${colors.reset}`);
  try {
    runGitCommand("git fetch origin");
    runGitCommand("git checkout dev");
    runGitCommand("git pull origin dev");
    return true;
  } catch (error) {
    console.error(
      `${colors.red}Failed to update dev branch:${colors.reset}`,
      (error as Error).message,
    );
    console.log(
      `${colors.yellow}Continuing with branch creation anyway...${colors.reset}`,
    );
    return false;
  }
}

export function createBranchWithParams(branchType: string, branchName: string, automerge: boolean): boolean {
  let fullBranchName = `${branchType}/${branchName}`;
  if (branchType === "fix" && automerge) {
    fullBranchName += "-automerge";
  }

  try {
    runGitCommand(`git checkout -b ${fullBranchName}`);
    console.log(
      `\n${colors.green}✅ Successfully created branch: ${colors.reset}${fullBranchName}`,
    );

    console.log(`\n${colors.cyan}Workflow:${colors.reset}`);
    console.log(`1. Make your changes`);
    console.log(`2. Commit with meaningful messages`);
    console.log(
      `3. Push: ${colors.yellow}git push -u origin ${fullBranchName}${colors.reset}`,
    );
    console.log(
      `4. PR will be auto-created to ${colors.magenta}dev${colors.reset} branch`,
    );

    if (branchType === "fix" && automerge) {
      console.log(
        `\n${colors.magenta}Automerge:${colors.reset} Will merge to dev after tests pass`,
      );
    }
    return true;
  } catch (error) {
    console.error(
      `${colors.red}Failed to create branch:${colors.reset}`,
      (error as Error).message,
    );
    return false;
  }
}

async function askBranchType(): Promise<string> {
  return new Promise((resolve) => {
    rl.question(`Branch type (${branchTypes.join(", ")}): `, (type) => {
      if (!branchTypes.includes(type)) {
        console.error("Invalid branch type");
        rl.close();
        process.exit(1);
      }
      resolve(type);
    });
  });
}

export function isValidBranchName(name: string): boolean {
  return /^[a-z0-9]+(-[a-z0-9]+)*$/.test(name);
}

async function askBranchName(): Promise<string> {
  return new Promise((resolve) => {
    rl.question(
      "Branch name (lowercase letters, numbers, and hyphens only): ",
      (name) => {
        if (!isValidBranchName(name)) {
          console.error("Invalid branch name");
          rl.close();
          process.exit(1);
        }
        resolve(name);
      }
    );
  });
}

async function askAutomerge(): Promise<boolean> {
  return new Promise((resolve) => {
    rl.question("Enable automerge? (y/N): ", (answer) => {
      resolve(answer.toLowerCase() === "y");
    });
  });
}

export function normalizeBranchName(name: string): string {
  return paramCase(name);
}

async function main(): Promise<boolean> {
  let success = false;

  try {
    // Non-interactive mode
    if (branchType && branchName) {
      if (!branchTypes.includes(branchType)) {
        console.error("Invalid branch type");
        return false;
      }

      const normalizedBranchName = normalizeBranchName(branchName);

      await updateDevBranch();
      success = createBranchWithParams(branchType, normalizedBranchName, automerge);
      return success;
    }

    // Interactive mode
    console.log("Interactive Branch Creation\n");
    branchType = await askBranchType();
    branchName = await askBranchName();

    const normalizedBranchName = normalizeBranchName(branchName);

    if (branchType === "fix") {
      automerge = await askAutomerge();
    }

    await updateDevBranch();
    success = createBranchWithParams(branchType, normalizedBranchName, automerge);
    return success;
  } catch (error) {
    console.error("An error occurred:", error);
    return false;
  } finally {
    rl.close();
    process.exit(success ? 0 : 1);
  }
}

// Run the main function
main().catch(error => {
  console.error("Fatal error:", error);
  process.exit(1);
});
