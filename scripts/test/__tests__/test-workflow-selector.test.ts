import { describe, test, expect, vi, beforeEach, afterEach } from 'vitest';
import { execSync } from 'child_process';
import fs from 'fs';
import path from 'path';
import readline from 'readline';

// Mock dependencies
vi.mock('child_process', () => ({
  execSync: vi.fn(),
  spawn: vi.fn()
}));

vi.mock('fs', () => ({
  readdirSync: vi.fn(),
  existsSync: vi.fn()
}));

vi.mock('readline', () => ({
  createInterface: vi.fn(() => ({
    question: vi.fn(),
    close: vi.fn()
  }))
}));

// Import the functions we want to test
// Note: We'll need to convert test-workflow-selector.js to TypeScript and export these functions
import {
  runCommand,
  getWorkflowFiles,
  selectWorkflow,
  selectEventType,
  askBranchName
} from '../test-workflow-selector';

describe('test-workflow-selector.ts', () => {
  beforeEach(() => {
    // Reset mocks before each test
    vi.resetAllMocks();

    // Mock console methods
    vi.spyOn(console, 'log').mockImplementation(() => {});
    vi.spyOn(console, 'error').mockImplementation(() => {});

    // Mock process.exit
    vi.spyOn(process, 'exit').mockImplementation((code) => {
      throw new Error(`Process exited with code ${code}`);
    });
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  describe('runCommand', () => {
    test('should execute command and return output', () => {
      (execSync as unknown as vi.Mock).mockReturnValue('command output');

      runCommand('ls -la');

      expect(execSync).toHaveBeenCalledWith('ls -la', { encoding: 'utf8', stdio: 'inherit' });
    });

    test('should throw error when command fails', () => {
      (execSync as unknown as vi.Mock).mockImplementation(() => {
        throw new Error('command failed');
      });

      expect(() => runCommand('invalid-command')).toThrow();
      expect(console.error).toHaveBeenCalled();
    });
  });

  describe('getWorkflowFiles', () => {
    test('should return list of workflow files', () => {
      const mockFiles = ['workflow1.yml', 'workflow2.yaml', 'not-a-workflow.txt'];
      (fs.readdirSync as unknown as vi.Mock).mockReturnValue(mockFiles);

      const result = getWorkflowFiles();

      expect(fs.readdirSync).toHaveBeenCalledWith(expect.stringContaining('workflows'));
      expect(result).toHaveLength(2);
      expect(result[0].name).toBe('workflow1.yml');
      expect(result[1].name).toBe('workflow2.yaml');
    });

    test('should handle errors when reading directory', () => {
      (fs.readdirSync as unknown as vi.Mock).mockImplementation(() => {
        throw new Error('directory not found');
      });

      const result = getWorkflowFiles();

      expect(console.error).toHaveBeenCalled();
      expect(result).toEqual([]);
    });
  });

  describe('selectWorkflow', () => {
    test('should prompt user to select a workflow', async () => {
      const mockWorkflows = [
        { name: 'workflow1.yml', path: '.github/workflows/workflow1.yml' },
        { name: 'workflow2.yml', path: '.github/workflows/workflow2.yml' }
      ];

      const mockReadline = {
        question: vi.fn((_, callback) => callback('1')),
        close: vi.fn()
      };
      (readline.createInterface as unknown as vi.Mock).mockReturnValue(mockReadline);

      const result = await selectWorkflow(mockWorkflows);

      expect(console.log).toHaveBeenCalledWith(expect.stringContaining('Available workflows'));
      expect(mockReadline.question).toHaveBeenCalled();
      expect(mockReadline.close).toHaveBeenCalled();
      expect(result).toEqual(mockWorkflows[0]);
    });

    test('should handle invalid selection', async () => {
      const mockWorkflows = [
        { name: 'workflow1.yml', path: '.github/workflows/workflow1.yml' }
      ];

      const mockReadline = {
        question: vi.fn((_, callback) => callback('99')),
        close: vi.fn()
      };
      (readline.createInterface as unknown as vi.Mock).mockReturnValue(mockReadline);

      await expect(selectWorkflow(mockWorkflows)).rejects.toThrow();
      expect(console.error).toHaveBeenCalledWith(expect.stringContaining('Invalid selection'));
      expect(process.exit).toHaveBeenCalledWith(1);
    });
  });

  describe('selectEventType', () => {
    test('should prompt user to select an event type', async () => {
      const mockReadline = {
        question: vi.fn((_, callback) => callback('1')),
        close: vi.fn()
      };
      (readline.createInterface as unknown as vi.Mock).mockReturnValue(mockReadline);

      const result = await selectEventType();

      expect(console.log).toHaveBeenCalledWith(expect.stringContaining('Event types'));
      expect(mockReadline.question).toHaveBeenCalled();
      expect(mockReadline.close).toHaveBeenCalled();
      expect(result).toBe('push');
    });

    test('should handle invalid selection', async () => {
      const mockReadline = {
        question: vi.fn((_, callback) => callback('99')),
        close: vi.fn()
      };
      (readline.createInterface as unknown as vi.Mock).mockReturnValue(mockReadline);

      await expect(selectEventType()).rejects.toThrow();
      expect(console.error).toHaveBeenCalledWith(expect.stringContaining('Invalid selection'));
      expect(process.exit).toHaveBeenCalledWith(1);
    });
  });

  describe('askBranchName', () => {
    test('should prompt user for branch name', async () => {
      const mockReadline = {
        question: vi.fn((_, callback) => callback('feature-branch')),
        close: vi.fn()
      };
      (readline.createInterface as unknown as vi.Mock).mockReturnValue(mockReadline);

      const result = await askBranchName();

      expect(mockReadline.question).toHaveBeenCalled();
      expect(mockReadline.close).toHaveBeenCalled();
      expect(result).toBe('feature-branch');
    });

    test('should handle empty branch name', async () => {
      const mockReadline = {
        question: vi.fn((_, callback) => callback('')),
        close: vi.fn()
      };
      (readline.createInterface as unknown as vi.Mock).mockReturnValue(mockReadline);

      const result = await askBranchName();

      expect(result).toBe('');
    });
  });
});
