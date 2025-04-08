import { describe, test, expect, vi, beforeEach, afterEach } from 'vitest';
import { execSync, spawn } from 'child_process';
import readline from 'readline';

// Mock dependencies
vi.mock('child_process', () => ({
  execSync: vi.fn(),
  spawn: vi.fn(() => ({
    on: vi.fn((event, callback) => {
      if (event === 'close') {
        callback(0); // Simulate successful process completion
      }
    })
  }))
}));

vi.mock('readline', () => ({
  createInterface: vi.fn(() => ({
    question: vi.fn(),
    close: vi.fn()
  }))
}));

// Import the functions we want to test
// Note: We'll need to convert test-app.js to TypeScript and export these functions
import {
  runCommand,
  checkDocker,
  getInteractiveMode,
  cleanupPrevious,
  cleanupCache,
  buildImages,
  startServices,
  runTests,
  cleanupAfter
} from '../test-app';

describe('test-app.ts', () => {
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

      const result = runCommand('docker --version');

      expect(execSync).toHaveBeenCalledWith('docker --version', { encoding: 'utf8' });
      expect(result).toBe(mockOutput);
    });

    test('should throw error when command fails', () => {
      (execSync as unknown as vi.Mock).mockImplementation(() => {
        throw new Error('command failed');
      });

      expect(() => runCommand('invalid-command')).toThrow();
      expect(console.error).toHaveBeenCalled();
    });
  });

  describe('checkDocker', () => {
    test('should return true when Docker is available', async () => {
      (execSync as unknown as vi.Mock).mockReturnValue('Docker version 20.10.12');

      const result = await checkDocker();

      expect(execSync).toHaveBeenCalledWith('docker --version', { encoding: 'utf8' });
      expect(console.log).toHaveBeenCalledWith(expect.stringContaining('Docker is available'));
      expect(result).toBe(true);
    });

    test('should return false when Docker is not available', async () => {
      (execSync as unknown as vi.Mock).mockImplementation(() => {
        throw new Error('docker command not found');
      });

      const result = await checkDocker();

      expect(console.error).toHaveBeenCalledWith(expect.stringContaining('Docker is not available'));
      expect(result).toBe(false);
    });
  });

  describe('getInteractiveMode', () => {
    test('should return user selected mode', async () => {
      const mockReadline = {
        question: vi.fn((_, callback) => callback('ci')),
        close: vi.fn()
      };
      (readline.createInterface as unknown as vi.Mock).mockReturnValue(mockReadline);

      const result = await getInteractiveMode();

      expect(mockReadline.question).toHaveBeenCalled();
      expect(mockReadline.close).toHaveBeenCalled();
      expect(result).toBe('ci');
    });

    test('should default to local mode for invalid input', async () => {
      const mockReadline = {
        question: vi.fn((_, callback) => callback('invalid')),
        close: vi.fn()
      };
      (readline.createInterface as unknown as vi.Mock).mockReturnValue(mockReadline);

      const result = await getInteractiveMode();

      expect(console.log).toHaveBeenCalledWith(expect.stringContaining('Invalid mode'));
      expect(result).toBe('local');
    });
  });

  describe('cleanupPrevious', () => {
    test('should clean up previous containers', async () => {
      (execSync as unknown as vi.Mock).mockReturnValue('');

      await cleanupPrevious();

      expect(execSync).toHaveBeenCalledWith('docker compose down -v', { encoding: 'utf8' });
      expect(console.log).toHaveBeenCalledWith(expect.stringContaining('Previous containers cleaned up'));
    });

    test('should handle errors during cleanup', async () => {
      (execSync as unknown as vi.Mock).mockImplementation(() => {
        throw new Error('cleanup failed');
      });

      await cleanupPrevious();

      expect(console.log).toHaveBeenCalledWith(expect.stringContaining('No previous containers to clean up'));
    });
  });

  describe('cleanupCache', () => {
    test('should clean up cache files', async () => {
      (execSync as unknown as vi.Mock).mockReturnValue('');

      await cleanupCache();

      expect(execSync).toHaveBeenCalledWith(expect.stringContaining('find . -type d -name __pycache__'), { encoding: 'utf8' });
      expect(execSync).toHaveBeenCalledWith(expect.stringContaining('find . -type d -name .pytest_cache'), { encoding: 'utf8' });
      expect(console.log).toHaveBeenCalledWith(expect.stringContaining('Cache files cleaned up'));
    });

    test('should handle errors during cache cleanup', async () => {
      (execSync as unknown as vi.Mock).mockImplementation(() => {
        throw new Error('cleanup failed');
      });

      await cleanupCache();

      expect(console.log).toHaveBeenCalledWith(expect.stringContaining('Error cleaning cache files'));
    });
  });

  describe('buildImages', () => {
    test('should build Docker images', async () => {
      (execSync as unknown as vi.Mock).mockReturnValue('');

      await buildImages();

      expect(execSync).toHaveBeenCalledWith('docker compose build', { encoding: 'utf8' });
      expect(console.log).toHaveBeenCalledWith(expect.stringContaining('Images built'));
    });

    test('should throw error when build fails', async () => {
      (execSync as unknown as vi.Mock).mockImplementation(() => {
        throw new Error('build failed');
      });

      await expect(buildImages()).rejects.toThrow('Failed to build Docker images');
    });
  });

  describe('startServices', () => {
    test('should start Docker services', async () => {
      (execSync as unknown as vi.Mock).mockReturnValue('');

      await startServices();

      expect(execSync).toHaveBeenCalledWith('docker compose up -d', { encoding: 'utf8' });
      expect(console.log).toHaveBeenCalledWith(expect.stringContaining('Services started'));
    });

    test('should throw error when services fail to start', async () => {
      (execSync as unknown as vi.Mock).mockImplementation(() => {
        throw new Error('services failed to start');
      });

      await expect(startServices()).rejects.toThrow('Failed to start Docker services');
    });
  });

  describe('runTests', () => {
    test('should run tests successfully', async () => {
      const mockSpawn = vi.fn().mockReturnValue({
        on: vi.fn((event, callback) => {
          if (event === 'close') {
            callback(0); // Simulate successful process completion
          }
        })
      });
      (spawn as unknown as vi.Mock).mockImplementation(mockSpawn);

      await runTests();

      expect(console.log).toHaveBeenCalledWith(expect.stringContaining('Running tests'));
      expect(mockSpawn).toHaveBeenCalledWith('docker', ['compose', 'exec', 'backend', 'pytest'], { stdio: 'inherit' });
      expect(console.log).toHaveBeenCalledWith(expect.stringContaining('Tests completed successfully'));
    });

    test('should handle test failures', async () => {
      const mockSpawn = vi.fn().mockReturnValue({
        on: vi.fn((event, callback) => {
          if (event === 'close') {
            callback(1); // Simulate failed process completion
          }
        })
      });
      (spawn as unknown as vi.Mock).mockImplementation(mockSpawn);

      await expect(runTests()).rejects.toThrow('Tests failed with exit code 1');
    });
  });

  describe('cleanupAfter', () => {
    test('should clean up in CI mode', async () => {
      (execSync as unknown as vi.Mock).mockReturnValue('');

      await cleanupAfter('ci');

      expect(execSync).toHaveBeenCalledWith('docker compose down -v', { encoding: 'utf8' });
      expect(console.log).toHaveBeenCalledWith(expect.stringContaining('Cleanup complete'));
    });

    test('should keep services running in local mode', async () => {
      await cleanupAfter('local');

      expect(execSync).not.toHaveBeenCalled();
      expect(console.log).toHaveBeenCalledWith(expect.stringContaining('Keeping services running'));
    });

    test('should handle errors during cleanup', async () => {
      (execSync as unknown as vi.Mock).mockImplementation(() => {
        throw new Error('cleanup failed');
      });

      await cleanupAfter('ci');

      expect(console.log).toHaveBeenCalledWith(expect.stringContaining('Error during cleanup'));
    });
  });
});
