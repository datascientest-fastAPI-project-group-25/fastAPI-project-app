#!/usr/bin/env node

const readline = require('readline');
const { execSync } = require('child_process');

// Conventional commit types
const VALID_TYPES = ['feat', 'fix', 'hotfix', 'chore'];

// Create readline interface for interactive mode
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

// Normalize branch name
function normalizeBranchName(name) {
  return name
    .toLowerCase()
    .replace(/[^a-z0-9-]/g, '-') // Replace invalid chars with hyphens
    .replace(/-+/g, '-')         // Replace multiple hyphens with single
    .replace(/^-|-$/g, '')       // Remove leading/trailing hyphens
    .trim();
}

// Extract branch type from input
function extractBranchType(input) {
  const normalizedInput = input.toLowerCase();
  for (const type of VALID_TYPES) {
    if (normalizedInput.startsWith(type + '/') || normalizedInput.startsWith(type + ' ')) {
      return type;
    }
  }
  return null;
}

// Create branch with given type and name
function createBranch(type, name) {
  const normalizedName = normalizeBranchName(name);
  const branchName = `${type}/${normalizedName}`;

  try {
    execSync(`git checkout -b ${branchName}`);
    console.log(`✅ Successfully created branch: ${branchName}`);
  } catch (error) {
    console.error(`❌ Failed to create branch: ${error.message}`);
    process.exit(1);
  }
}

// Interactive mode
function interactiveMode() {
  console.log('🌿 Interactive Branch Creation');
  console.log('Available branch types:', VALID_TYPES.join(', '));

  rl.question('Enter branch type: ', (type) => {
    const normalizedType = type.toLowerCase();

    if (!VALID_TYPES.includes(normalizedType)) {
      console.error(`❌ Invalid branch type. Please use one of: ${VALID_TYPES.join(', ')}`);
      rl.close();
      process.exit(1);
    }

    rl.question('Enter branch name: ', (name) => {
      createBranch(normalizedType, name);
      rl.close();
    });
  });
}

// Direct mode
function directMode(input) {
  // Check if input is a complete branch name with type prefix
  const branchType = extractBranchType(input);
  if (branchType) {
    // Remove type prefix to get the name part
    const name = input.substring(input.indexOf('/') + 1 || input.indexOf(' ') + 1);
    createBranch(branchType, name);
  } else {
    // Assume input is just the name part and use default type 'feat'
    createBranch('feat', input);
  }
}

// Main execution
const args = process.argv.slice(2);

if (args.length === 0) {
  interactiveMode();
} else {
  directMode(args.join(' '));
}
