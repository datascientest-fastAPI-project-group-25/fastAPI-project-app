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
const yaml = require('js-yaml');

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
let eventType = "";
let workflowFile = "";

// Parse command line arguments
for (let i = 0; i < args.length; i++) {
  switch (args[i]) {
    case "--event":
      eventType = args[++i];
      break;
    case "--workflow":
      workflowFile = args[++i];
      break;
  }
}

const WORKFLOW_DIR = path.join(__dirname, '..', '.github', 'workflows');

/**
 * Scans the workflow directory and parses YAML files to get workflow info.
 * @returns {Array<{file: string, events: string[]}>} List of workflows and their events.
 */
function getWorkflows() {
  const workflows = [];
  try {
    const files = fs.readdirSync(WORKFLOW_DIR);
    files.forEach(file => {
      if (file.endsWith('.yml') || file.endsWith('.yaml')) {
        const filePath = path.join(WORKFLOW_DIR, file);
        try {
          const fileContent = fs.readFileSync(filePath, 'utf8');
          const doc = yaml.load(fileContent);
          let events = [];
          if (doc && doc.on) {
            if (typeof doc.on === 'string') {
              events = [doc.on];
            } else if (Array.isArray(doc.on)) {
              events = doc.on;
            } else if (typeof doc.on === 'object') {
              events = Object.keys(doc.on);
            }
          }
          // Filter out workflow_call as it's not directly triggerable by act
          events = events.filter(e => e !== 'workflow_call');
          if (events.length > 0) {
            workflows.push({ file: file, events: events });
          }
        } catch (parseError) {
          console.error(chalk.yellow(`Could not parse ${file}: ${parseError.message}`));
        }
      }
    });
  } catch (readError) {
    console.error(chalk.red(`Error reading workflow directory: ${readError.message}`));
    process.exit(1);
  }
  return workflows;
}

const ALL_WORKFLOWS = getWorkflows();

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
    const workflowPath = path.join(WORKFLOW_DIR, workflowFile);
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
 * Interactive selection of workflow file
 * @returns {Promise<{workflow: string}>} - Selected workflow file
 */
async function selectWorkflowFile() {
  const questions = [
    {
      type: 'list',
      name: 'workflow',
      message: 'Select workflow file:',
      choices: ALL_WORKFLOWS.map(w => w.file)
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
  const workflowConfig = ALL_WORKFLOWS.find(w => w.file === workflow);

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

// Test all workflows
const testAllWorkflows = async () => {
  try {
    console.log(chalk.blue('\n📚 Testing All GitHub Workflows'));

    for (const workflowObj of ALL_WORKFLOWS) {
      for (const event of workflowObj.events) {
        console.log(chalk.yellow(`\n⚡ Testing workflow: ${workflowObj.file} with event: ${event}`));
        await runTestScript(workflowObj.file, event);
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

      // Get workflow file
      const workflow = await selectWorkflowFile();

      // Get event type
      const event = await selectEventType(workflow);

      // Run the workflow
      await runTestScript(workflow, event);
    } else {
      // Non-interactive mode
      if (workflowFile && eventType) {
        await runTestScript(workflowFile, eventType);
        process.exit(0);
      } else {
        console.error(chalk.red('\nError: In non-interactive mode, both workflow and event must be specified'));
        process.exit(1);
      }
    }
  } catch (error) {
    console.error(chalk.red(`\nError: ${error.message}`));
    process.exit(1);
  }
})();
