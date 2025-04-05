#!/usr/bin/env node

/**
 * Interactive workflow selector for testing GitHub Actions workflows
 * This script provides a user-friendly interface to select and test workflows
 */

import { execSync } from 'child_process';
import fs from 'fs';
import path from 'path';
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

interface Workflow {
  name: string;
  path: string;
}

// Run a command and return its output
export function runCommand(command: string): string {
  try {
    return execSync(command, { encoding: 'utf8', stdio: 'inherit' });
  } catch (error) {
    console.error(`${colors.red}Command failed: ${command}${colors.reset}`);
    throw error;
  }
}

// Get all workflow files
export function getWorkflowFiles(): Workflow[] {
  const workflowDir = path.join('.github', 'workflows');
  try {
    return fs.readdirSync(workflowDir)
      .filter(file => file.endsWith('.yml') || file.endsWith('.yaml'))
      .map(file => ({ name: file, path: path.join(workflowDir, file) }));
  } catch (error) {
    console.error(`${colors.red}Error reading workflow directory: ${(error as Error).message}${colors.reset}`);
    return [];
  }
}

// Display workflow selection menu
export async function selectWorkflow(workflows: Workflow[]): Promise<Workflow> {
  return new Promise((resolve) => {
    console.log(`${colors.blue}Available workflows:${colors.reset}`);
    workflows.forEach((workflow, index) => {
      console.log(`${index + 1}. ${workflow.name}`);
    });

    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout
    });

    rl.question(`${colors.yellow}Select a workflow (1-${workflows.length}): ${colors.reset}`, (answer) => {
      rl.close();
      const index = parseInt(answer) - 1;
      if (index >= 0 && index < workflows.length) {
        resolve(workflows[index]);
      } else {
        console.error(`${colors.red}Invalid selection${colors.reset}`);
        process.exit(1);
      }
    });
  });
}

// Select event type
export async function selectEventType(): Promise<string> {
  return new Promise((resolve) => {
    console.log(`${colors.blue}Event types:${colors.reset}`);
    const events = ['push', 'pull_request', 'workflow_dispatch'];
    events.forEach((event, index) => {
      console.log(`${index + 1}. ${event}`);
    });

    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout
    });

    rl.question(`${colors.yellow}Select an event type (1-${events.length}): ${colors.reset}`, (answer) => {
      rl.close();
      const index = parseInt(answer) - 1;
      if (index >= 0 && index < events.length) {
        resolve(events[index]);
      } else {
        console.error(`${colors.red}Invalid selection${colors.reset}`);
        process.exit(1);
      }
    });
  });
}

// Ask for branch name
export async function askBranchName(): Promise<string> {
  return new Promise((resolve) => {
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout
    });

    rl.question(`${colors.yellow}Enter branch name (optional, press Enter to skip): ${colors.reset}`, (answer) => {
      rl.close();
      resolve(answer.trim());
    });
  });
}

// Main function
async function main(): Promise<void> {
  try {
    console.log(`${colors.blue}GitHub Workflow Tester${colors.reset}`);
    console.log(`${colors.cyan}This tool helps you test GitHub Actions workflows locally${colors.reset}`);
    console.log();

    // Get workflow files
    const workflows = getWorkflowFiles();
    if (workflows.length === 0) {
      console.error(`${colors.red}No workflow files found in .github/workflows directory${colors.reset}`);
      process.exit(1);
    }

    // Select workflow
    const workflow = await selectWorkflow(workflows);
    console.log(`${colors.green}Selected workflow: ${workflow.name}${colors.reset}`);

    // Select event type
    const eventType = await selectEventType();
    console.log(`${colors.green}Selected event type: ${eventType}${colors.reset}`);

    // Ask for branch name
    const branchName = await askBranchName();
    if (branchName) {
      console.log(`${colors.green}Using branch: ${branchName}${colors.reset}`);
    }

    // Run the test-workflow.sh script
    console.log(`${colors.blue}Running workflow test...${colors.reset}`);
    const command = `./scripts/test/test-workflow.sh -w ${workflow.name} -e ${eventType}${branchName ? ` -b ${branchName}` : ''}`;
    console.log(`${colors.cyan}Executing: ${command}${colors.reset}`);
    runCommand(command);

    console.log(`${colors.green}Workflow test completed successfully!${colors.reset}`);
  } catch (error) {
    console.error(`${colors.red}Error: ${(error as Error).message}${colors.reset}`);
    process.exit(1);
  }
}

// Run the main function
if (require.main === module) {
  main();
}
