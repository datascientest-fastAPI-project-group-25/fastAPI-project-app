#!/usr/bin/env node

/**
 * Interactive workflow selection CLI
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
const fs = require('fs');
const path = require('path');

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
let workflowCategory = "";
let eventType = "";
let workflowFile = "";

// Parse command line arguments
for (let i = 0; i < args.length; i++) {
  switch (args[i]) {
    case "--category":
      workflowCategory = args[++i];
      break;
    case "--event":
      eventType = args[++i];
      break;
    case "--workflow":
      workflowFile = args[++i];
      break;
  }
}

// Define workflow categories and their workflows
const WORKFLOW_CATEGORIES = {
  "Pre-commit": [{ file: "pre-commit/pre-commit.yml", events: ["pull_request", "push"] }],
  "Feature": [{ file: "feature/feature-push.yml", events: ["push"] }],
  "Dev": [
    { file: "dev/pr-to-dev.yml", events: ["pull_request"] },
    { file: "dev/merge-to-dev.yml", events: ["push"] }
  ],
  "Main": [
    { file: "main/pr-to-main.yml", events: ["pull_request"] },
    { file: "main/merge-to-main.yml", events: ["push"] }
  ],
  "Shared": [
    { file: "shared/shared-tests.yml", events: ["workflow_call"] },
    { file: "shared/shared-build.yml", events: ["workflow_call"] },
    { file: "shared/shared-release.yml", events: ["workflow_call"] }
  ]
};

// Workflow directory mapping
const workflowDirMap = {
  "Pre-commit": ".github/workflows/pre-commit",
  "Feature": ".github/workflows/feature",
  "Dev": ".github/workflows/dev",
  "Main": ".github/workflows/main",
  "Shared": ".github/workflows/shared",
};

/**
 * Execute a git command and return the result
 * @param {string} command - The command to execute
 * @returns {string|null} - The command output or null if error
 */
function runGitCommand(command) {
  try {
    return execSync(command, { encoding: "utf8" }).trim();
  } catch (error) {
    console.error(
      `${colors.red}Error executing command:${colors.reset}`,
      error.message,
    );
    return null;
  }
}

const runTestScript = async (workflowFile, eventType) => {
  try {
    console.log(`\nTesting workflow: ${workflowFile} with event: ${eventType}`);
    const testScript = path.join(__dirname, '../.github/workflows/utils/test-workflow.sh');
    const workflowPath = path.join(__dirname, "..", ".github", "workflows", workflowFile);
    const testCommand = `${testScript} "${workflowPath}" "${eventType}"`;

    // Run the test script with live output
    const { spawn } = require('child_process');
    const testProcess = spawn('bash', ['-c', testCommand], {
      stdio: 'inherit'
    });

    return new Promise((resolve, reject) => {
      testProcess.on('close', (code) => {
        if (code === 0) {
          console.log(chalk.green(`\n✅ Workflow test completed successfully!`));
          resolve();
        } else {
          console.error(chalk.yellow(`\n⚠️ Workflow test failed with exit code: ${code}`));
          resolve(); // Don't reject as this is expected behavior
        }
      });

      testProcess.on('error', (error) => {
        console.error(chalk.red(`Error running test script: ${error.message}`));
        reject(error);
      });
    });
  } catch (error) {
    throw new Error(`Failed to run test script: ${error.message}`);
  }
};

/**
 * Interactive selection of workflow category
 * @returns {Promise<{category: string}>} - Selected category
 */
async function selectWorkflowCategory() {
  const categories = Object.keys(WORKFLOW_CATEGORIES);

  // If there's only one category, return it immediately
  if (categories.length === 1) {
    console.log(chalk.cyan(`\nAuto-selected category: ${categories[0]}`));
    return categories[0];
  }

  const questions = [
    {
      type: 'list',
      name: 'category',
      message: 'Select workflow category:',
      choices: categories
    }
  ];

  const { category } = await inquirer.prompt(questions);
  return category;
}

/**
 * Interactive selection of workflow file
 * @param {string} category - Selected category
 * @returns {Promise<{workflow: string}>} - Selected workflow file
 */
async function selectWorkflowFile(category) {
  const workflows = WORKFLOW_CATEGORIES[category];

  // If there's only one workflow, return it immediately
  if (workflows.length === 1) {
    console.log(chalk.cyan(`\nAuto-selected workflow: ${workflows[0].file}`));
    return workflows[0].file;
  }

  const questions = [
    {
      type: 'list',
      name: 'workflow',
      message: 'Select workflow file:',
      choices: workflows.map(w => w.file)
    }
  ];

  const { workflow } = await inquirer.prompt(questions);
  return workflow;
}

/**
 * Interactive selection of event type
 * @param {string} workflow - Selected workflow file
 * @returns {Promise<{event: string}>} - Selected event type
 */
async function selectEventType(workflow) {
  const workflows = Object.values(WORKFLOW_CATEGORIES).flat();
  const workflowConfig = workflows.find(w => w.file === workflow);

  if (!workflowConfig) {
    console.error(chalk.red('Error: Workflow not found in configuration'));
    process.exit(1);
  }

  const events = workflowConfig.events;

  // If there's only one event type, return it immediately
  if (events.length === 1) {
    console.log(chalk.cyan(`\nAuto-selected event: ${events[0]}`));
    return events[0];
  }

  const questions = [
    {
      type: 'list',
      name: 'event',
      message: 'Select event type:',
      choices: events
    }
  ];

  const { event } = await inquirer.prompt(questions);
  return event;
}

// Test all workflows in all categories
const testAllWorkflows = async () => {
  try {
    console.log(chalk.blue('\n📚 Testing All GitHub Workflows'));

    for (const category of Object.keys(WORKFLOW_CATEGORIES)) {
      console.log(chalk.cyan(`\n🔍 Testing category: ${category}`));

      for (const workflowObj of WORKFLOW_CATEGORIES[category]) {
        for (const event of workflowObj.events) {
          console.log(chalk.yellow(`\n⚡ Testing workflow: ${workflowObj.file} with event: ${event}`));
          await runTestScript(workflowObj.file, event);
        }
      }
    }

    console.log(chalk.green('\n✅ All workflows tested!'));
  } catch (error) {
    console.error(chalk.red(`\n❌ Error testing all workflows: ${error.message}`));
    throw error;
  }
};

// Main execution
(async () => {
  try {
    // Check for --all flag
    if (args.includes('--all')) {
      await testAllWorkflows();
      return;
    }

    // Check if we're in interactive mode
    if (process.stdin.isTTY) {
      console.log(chalk.blue('\n📚 GitHub Workflow Tester'));

      // Get category
      const category = await selectWorkflowCategory();

      // Get workflow file
      const workflow = await selectWorkflowFile(category);

      // Get event type
      const event = await selectEventType(workflow);

      // Run the workflow
      await runTestScript(workflow, event);
    } else {
      // Non-interactive mode
      if (workflowCategory && eventType) {
        await runTestScript(workflowCategory, eventType);
        process.exit(0);
      } else {
        console.error(chalk.red('\nError: In non-interactive mode, both category and event must be specified'));
        process.exit(1);
      }
    }
  } catch (error) {
    console.error(chalk.red(`\nError: ${error.message}`));
    process.exit(1);
  }
})();
