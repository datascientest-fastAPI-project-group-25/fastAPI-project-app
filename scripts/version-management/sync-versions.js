#!/usr/bin/env node
/**
 * This script synchronizes the version between the VERSION file and package.json
 * It can be run in two modes:
 * 1. VERSION -> package.json: Updates package.json with the version from VERSION file
 * 2. package.json -> VERSION: Updates VERSION file with the version from package.json
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { execSync } from 'child_process';

// Get the directory name in ES modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Paths
const rootDir = path.resolve(__dirname, '../..');
const versionFilePath = path.join(rootDir, 'VERSION');
const packageJsonPath = path.join(rootDir, 'package.json');

// Function to read the VERSION file
function readVersionFile() {
  try {
    return fs.readFileSync(versionFilePath, 'utf8').trim();
  } catch (error) {
    console.error(`Error reading VERSION file: ${error.message}`);
    process.exit(1);
  }
}

// Function to read the package.json file
function readPackageJson() {
  try {
    const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf8'));
    return packageJson;
  } catch (error) {
    console.error(`Error reading package.json: ${error.message}`);
    process.exit(1);
  }
}

// Function to update the VERSION file
function updateVersionFile(version) {
  try {
    fs.writeFileSync(versionFilePath, version);
    console.log(`✅ Updated VERSION file to ${version}`);
  } catch (error) {
    console.error(`Error updating VERSION file: ${error.message}`);
    process.exit(1);
  }
}

// Function to update the package.json file
function updatePackageJson(version) {
  try {
    const packageJson = readPackageJson();
    packageJson.version = version;
    fs.writeFileSync(packageJsonPath, JSON.stringify(packageJson, null, 2) + '\n');
    console.log(`✅ Updated package.json version to ${version}`);
  } catch (error) {
    console.error(`Error updating package.json: ${error.message}`);
    process.exit(1);
  }
}

// Function to compare versions
function compareVersions(version1, version2) {
  const v1Parts = version1.split('.').map(Number);
  const v2Parts = version2.split('.').map(Number);

  for (let i = 0; i < Math.max(v1Parts.length, v2Parts.length); i++) {
    const v1Part = v1Parts[i] || 0;
    const v2Part = v2Parts[i] || 0;

    if (v1Part > v2Part) return 1;
    if (v1Part < v2Part) return -1;
  }

  return 0;
}

// Main function
function main() {
  const args = process.argv.slice(2);
  const direction = args[0] || 'auto';

  const versionFileVersion = readVersionFile();
  const packageJsonVersion = readPackageJson().version;

  console.log(`Current VERSION file: ${versionFileVersion}`);
  console.log(`Current package.json: ${packageJsonVersion}`);

  if (versionFileVersion === packageJsonVersion) {
    console.log('✅ Versions are already in sync.');
    return;
  }

  if (direction === 'to-package') {
    // Update package.json with VERSION file
    updatePackageJson(versionFileVersion);
  } else if (direction === 'to-version') {
    // Update VERSION file with package.json
    updateVersionFile(packageJsonVersion);
  } else if (direction === 'auto') {
    // Automatically determine which version to use (higher one)
    const comparison = compareVersions(versionFileVersion, packageJsonVersion);

    if (comparison > 0) {
      // VERSION file has higher version
      console.log('VERSION file has higher version. Updating package.json...');
      updatePackageJson(versionFileVersion);
    } else {
      // package.json has higher version
      console.log('package.json has higher version. Updating VERSION file...');
      updateVersionFile(packageJsonVersion);
    }
  } else {
    console.error(`Invalid direction: ${direction}`);
    console.error('Usage: node sync-versions.js [to-package|to-version|auto]');
    process.exit(1);
  }

  console.log('✅ Versions synchronized successfully.');
}

main();
