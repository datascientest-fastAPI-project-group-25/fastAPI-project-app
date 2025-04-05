import { describe, test, expect, vi, beforeEach, afterEach } from 'vitest';
import { execSync } from 'child_process';
import readline from 'readline';
import { paramCase } from '../../utils';

// Mock dependencies
vi.mock('child_process', () => ({
  execSync: vi.fn()
}));

vi.mock('readline', () => ({
  createInterface: vi.fn(() => ({
    question: vi.fn(),
    close: vi.fn()
  }))
}));

vi.mock('../../utils', () => ({
  paramCase: vi.fn((input) => input.toLowerCase().replace(/\s+/g, '-'))
}));

// Import the functions we want to test
// Note: We'll need to refactor create-branch.ts to export these functions
import {
  runGitCommand,
  updateDevBranch,
  createBranchWithParams,
  isValidBranchName,
  normalizeBranchName
} from '../create-branch';

describe('create-branch.ts', () => {
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

  describe('runGitCommand', () => {
    test('should execute git command and return output', () => {
      const mockOutput = 'mock git output';
      (execSync as unknown as vi.Mock).mockReturnValue(mockOutput);

      const result = runGitCommand('git status');

      expect(execSync).toHaveBeenCalledWith('git status', { encoding: 'utf8' });
      expect(result).toBe(mockOutput);
    });

    test('should exit process when git command fails', () => {
      (execSync as unknown as vi.Mock).mockImplementation(() => {
        throw new Error('git command failed');
      });

      expect(() => runGitCommand('git status')).toThrow();
      expect(console.error).toHaveBeenCalled();
      expect(process.exit).toHaveBeenCalledWith(1);
    });
  });

  describe('updateDevBranch', () => {
    test('should update dev branch successfully', async () => {
      (execSync as unknown as vi.Mock).mockReturnValue('');

      const result = await updateDevBranch();

      expect(execSync).toHaveBeenCalledTimes(3);
      expect(execSync).toHaveBeenCalledWith('git fetch origin', { encoding: 'utf8' });
      expect(execSync).toHaveBeenCalledWith('git checkout dev', { encoding: 'utf8' });
      expect(execSync).toHaveBeenCalledWith('git pull origin dev', { encoding: 'utf8' });
      expect(result).toBe(true);
    });

    test('should handle errors and continue', async () => {
      (execSync as unknown as vi.Mock).mockImplementation(() => {
        throw new Error('git command failed');
      });

      const result = await updateDevBranch();

      expect(console.error).toHaveBeenCalled();
      expect(console.log).toHaveBeenCalledWith(expect.stringContaining('Continuing with branch creation anyway'));
      expect(result).toBe(false);
    });
  });

  describe('createBranchWithParams', () => {
    test('should create feature branch successfully', () => {
      (execSync as unknown as vi.Mock).mockReturnValue('');

      const result = createBranchWithParams('feat', 'new-feature', false);

      expect(execSync).toHaveBeenCalledWith('git checkout -b feat/new-feature', { encoding: 'utf8' });
      expect(result).toBe(true);
      expect(console.log).toHaveBeenCalledWith(expect.stringContaining('Successfully created branch'));
    });

    test('should create fix branch with automerge flag', () => {
      (execSync as unknown as vi.Mock).mockReturnValue('');

      const result = createBranchWithParams('fix', 'critical-fix', true);

      expect(execSync).toHaveBeenCalledWith('git checkout -b fix/critical-fix-automerge', { encoding: 'utf8' });
      expect(result).toBe(true);
      expect(console.log).toHaveBeenCalledWith(expect.stringContaining('Automerge'));
    });

    test('should handle errors when creating branch', () => {
      (execSync as unknown as vi.Mock).mockImplementation(() => {
        throw new Error('git command failed');
      });

      const result = createBranchWithParams('feat', 'new-feature', false);

      expect(console.error).toHaveBeenCalled();
      expect(result).toBe(false);
    });
  });

  describe('isValidBranchName', () => {
    test('should validate correct branch names', () => {
      expect(isValidBranchName('valid-branch')).toBe(true);
      expect(isValidBranchName('valid-branch-123')).toBe(true);
      expect(isValidBranchName('123-valid')).toBe(true);
    });

    test('should reject invalid branch names', () => {
      expect(isValidBranchName('Invalid Branch')).toBe(false);
      expect(isValidBranchName('invalid_branch')).toBe(false);
      expect(isValidBranchName('invalid.branch')).toBe(false);
      expect(isValidBranchName('-invalid')).toBe(false);
      expect(isValidBranchName('invalid-')).toBe(false);
    });
  });

  describe('normalizeBranchName', () => {
    test('should normalize branch names correctly', () => {
      (paramCase as unknown as vi.Mock).mockImplementation((input) =>
        input.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '')
      );

      expect(normalizeBranchName('Branch Name')).toBe('branch-name');
      expect(normalizeBranchName('Branch_Name')).toBe('branch-name');
      expect(normalizeBranchName('Branch.Name')).toBe('branch-name');
      expect(normalizeBranchName('  Branch  Name  ')).toBe('branch-name');
    });
  });
});
