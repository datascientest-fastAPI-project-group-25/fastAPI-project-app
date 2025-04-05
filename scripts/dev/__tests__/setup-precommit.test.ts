import { describe, test, expect, vi, beforeEach, afterEach } from 'vitest';
import { execSync } from 'child_process';
import readline from 'readline';

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

// Import the functions we want to test
// Note: We'll need to convert setup-precommit.js to TypeScript and export these functions
import {
  runCommand,
  checkPreCommit,
  getInteractiveMode,
  installWithPip,
  installWithPip3,
  installWithBrew,
  installPreCommit,
  installGitHooks
} from '../setup-precommit';

describe('setup-precommit.ts', () => {
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
      const mockOutput = 'command output';
      (execSync as unknown as vi.Mock).mockReturnValue(mockOutput);

      const result = runCommand('pre-commit --version');

      expect(execSync).toHaveBeenCalledWith('pre-commit --version', { encoding: 'utf8' });
      expect(result).toBe(mockOutput);
    });

    test('should throw error when command fails', () => {
      (execSync as unknown as vi.Mock).mockImplementation(() => {
        throw new Error('command failed');
      });

      expect(() => runCommand('invalid-command')).toThrow();
    });
  });

  describe('checkPreCommit', () => {
    test('should return true when pre-commit is installed', async () => {
      (execSync as unknown as vi.Mock).mockReturnValue('pre-commit 2.20.0');

      const result = await checkPreCommit();

      expect(execSync).toHaveBeenCalledWith('pre-commit --version', { encoding: 'utf8' });
      expect(console.log).toHaveBeenCalledWith(expect.stringContaining('pre-commit is already installed'));
      expect(result).toBe(true);
    });

    test('should return false when pre-commit is not installed', async () => {
      (execSync as unknown as vi.Mock).mockImplementation(() => {
        throw new Error('command not found');
      });

      const result = await checkPreCommit();

      expect(console.log).toHaveBeenCalledWith(expect.stringContaining('pre-commit is not installed'));
      expect(result).toBe(false);
    });
  });

  describe('getInteractiveMode', () => {
    test('should return true when user wants to install', async () => {
      const mockReadline = {
        question: vi.fn((_, callback) => callback('y')),
        close: vi.fn()
      };
      (readline.createInterface as unknown as vi.Mock).mockReturnValue(mockReadline);

      const result = await getInteractiveMode();

      expect(mockReadline.question).toHaveBeenCalled();
      expect(mockReadline.close).toHaveBeenCalled();
      expect(result).toBe(true);
    });

    test('should return false when user does not want to install', async () => {
      const mockReadline = {
        question: vi.fn((_, callback) => callback('n')),
        close: vi.fn()
      };
      (readline.createInterface as unknown as vi.Mock).mockReturnValue(mockReadline);

      const result = await getInteractiveMode();

      expect(result).toBe(false);
    });
  });

  describe('installWithPip', () => {
    test('should install pre-commit with pip', async () => {
      (execSync as unknown as vi.Mock).mockReturnValue('');

      const result = await installWithPip();

      expect(execSync).toHaveBeenCalledWith('pip install pre-commit', { encoding: 'utf8' });
      expect(console.log).toHaveBeenCalledWith(expect.stringContaining('pre-commit installed with pip'));
      expect(result).toBe(true);
    });

    test('should return false when pip installation fails', async () => {
      (execSync as unknown as vi.Mock).mockImplementation(() => {
        throw new Error('pip installation failed');
      });

      const result = await installWithPip();

      expect(result).toBe(false);
    });
  });

  describe('installWithPip3', () => {
    test('should install pre-commit with pip3', async () => {
      (execSync as unknown as vi.Mock).mockReturnValue('');

      const result = await installWithPip3();

      expect(execSync).toHaveBeenCalledWith('pip3 install pre-commit', { encoding: 'utf8' });
      expect(console.log).toHaveBeenCalledWith(expect.stringContaining('pre-commit installed with pip3'));
      expect(result).toBe(true);
    });

    test('should return false when pip3 installation fails', async () => {
      (execSync as unknown as vi.Mock).mockImplementation(() => {
        throw new Error('pip3 installation failed');
      });

      const result = await installWithPip3();

      expect(result).toBe(false);
    });
  });

  describe('installWithBrew', () => {
    test('should install pre-commit with brew', async () => {
      (execSync as unknown as vi.Mock).mockReturnValue('');

      const result = await installWithBrew();

      expect(execSync).toHaveBeenCalledWith('brew install pre-commit', { encoding: 'utf8' });
      expect(console.log).toHaveBeenCalledWith(expect.stringContaining('pre-commit installed with brew'));
      expect(result).toBe(true);
    });

    test('should return false when brew installation fails', async () => {
      (execSync as unknown as vi.Mock).mockImplementation(() => {
        throw new Error('brew installation failed');
      });

      const result = await installWithBrew();

      expect(result).toBe(false);
    });
  });

  describe('installPreCommit', () => {
    test('should try all installation methods and return true if any succeeds', async () => {
      vi.spyOn(global, 'installWithPip').mockResolvedValue(false);
      vi.spyOn(global, 'installWithPip3').mockResolvedValue(true);

      const result = await installPreCommit();

      expect(result).toBe(true);
    });

    test('should return false if all installation methods fail', async () => {
      vi.spyOn(global, 'installWithPip').mockResolvedValue(false);
      vi.spyOn(global, 'installWithPip3').mockResolvedValue(false);
      vi.spyOn(global, 'installWithBrew').mockResolvedValue(false);

      const result = await installPreCommit();

      expect(console.error).toHaveBeenCalledWith(expect.stringContaining('Could not install pre-commit'));
      expect(result).toBe(false);
    });
  });

  describe('installGitHooks', () => {
    test('should install git hooks successfully', async () => {
      (execSync as unknown as vi.Mock).mockReturnValue('');

      const result = await installGitHooks();

      expect(execSync).toHaveBeenCalledWith(
        'pre-commit install --hook-type pre-commit --hook-type commit-msg --hook-type pre-push',
        { encoding: 'utf8' }
      );
      expect(console.log).toHaveBeenCalledWith(expect.stringContaining('Git hooks installed successfully'));
      expect(result).toBe(true);
    });

    test('should return false when hook installation fails', async () => {
      (execSync as unknown as vi.Mock).mockImplementation(() => {
        throw new Error('hook installation failed');
      });

      const result = await installGitHooks();

      expect(console.error).toHaveBeenCalledWith(expect.stringContaining('Error installing git hooks'));
      expect(result).toBe(false);
    });
  });
});
