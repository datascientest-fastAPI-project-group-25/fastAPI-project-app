#!/usr/bin/env python3
import unittest
import subprocess
import sys
from unittest.mock import patch, MagicMock
import os
import importlib.util

# Get the absolute path to the block-main-push.py script
script_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                          "block-main-push.py")

# Load the script as a module
spec = importlib.util.spec_from_file_location("block_main_push", script_path)
block_main_push = importlib.util.module_from_spec(spec)
spec.loader.exec_module(block_main_push)

class TestBlockMainPush(unittest.TestCase):
    """Test cases for the block-main-push.py script."""

    @patch('subprocess.run')
    def test_main_branch_blocked(self, mock_run):
        """Test that pushes to main branch are blocked."""
        # Mock subprocess.run to return 'main' as the current branch
        mock_process = MagicMock()
        mock_process.stdout = 'main\n'
        mock_run.return_value = mock_process

        # Patch sys.exit to avoid actually exiting during the test
        with patch('sys.exit') as mock_exit:
            # Run the script
            with patch.object(sys, 'argv', ['block-main-push.py']):
                try:
                    # This will call sys.exit(1) if the branch is main
                    block_main_push
                except SystemExit:
                    pass

            # Check that sys.exit was called with code 1
            mock_exit.assert_called_once_with(1)

        # Verify subprocess.run was called with the correct arguments
        mock_run.assert_called_once_with(
            ['/usr/bin/git', 'symbolic-ref', '--short', 'HEAD'],
            capture_output=True,
            text=True,
            check=True
        )

    @patch('subprocess.run')
    def test_dev_branch_blocked(self, mock_run):
        """Test that pushes to dev branch are blocked."""
        # Mock subprocess.run to return 'dev' as the current branch
        mock_process = MagicMock()
        mock_process.stdout = 'dev\n'
        mock_run.return_value = mock_process

        # Patch sys.exit to avoid actually exiting during the test
        with patch('sys.exit') as mock_exit:
            # Run the script
            with patch.object(sys, 'argv', ['block-main-push.py']):
                try:
                    # This will call sys.exit(1) if the branch is dev
                    block_main_push
                except SystemExit:
                    pass

            # Check that sys.exit was called with code 1
            mock_exit.assert_called_once_with(1)

    @patch('subprocess.run')
    def test_feature_branch_allowed(self, mock_run):
        """Test that pushes to feature branches are allowed."""
        # Mock subprocess.run to return a feature branch name
        mock_process = MagicMock()
        mock_process.stdout = 'feat/new-feature\n'
        mock_run.return_value = mock_process

        # Patch sys.exit to avoid actually exiting during the test
        with patch('sys.exit') as mock_exit:
            # Run the script
            with patch.object(sys, 'argv', ['block-main-push.py']):
                try:
                    # This should call sys.exit(0) for feature branches
                    block_main_push
                except SystemExit:
                    pass

            # Check that sys.exit was called with code 0
            mock_exit.assert_called_once_with(0)

    @patch('subprocess.run')
    def test_fix_branch_allowed(self, mock_run):
        """Test that pushes to fix branches are allowed."""
        # Mock subprocess.run to return a fix branch name
        mock_process = MagicMock()
        mock_process.stdout = 'fix/bug-fix\n'
        mock_run.return_value = mock_process

        # Patch sys.exit to avoid actually exiting during the test
        with patch('sys.exit') as mock_exit:
            # Run the script
            with patch.object(sys, 'argv', ['block-main-push.py']):
                try:
                    # This should call sys.exit(0) for fix branches
                    block_main_push
                except SystemExit:
                    pass

            # Check that sys.exit was called with code 0
            mock_exit.assert_called_once_with(0)

    @patch('subprocess.run')
    def test_subprocess_error(self, mock_run):
        """Test handling of subprocess errors."""
        # Mock subprocess.run to raise an exception
        mock_run.side_effect = subprocess.SubprocessError("Command failed")

        # Patch sys.exit to avoid actually exiting during the test
        with patch('sys.exit') as mock_exit:
            # Run the script
            with patch.object(sys, 'argv', ['block-main-push.py']):
                try:
                    # This should catch the exception and call sys.exit(1)
                    block_main_push
                except SystemExit:
                    pass

            # Check that sys.exit was called with code 1
            mock_exit.assert_called_once_with(1)

if __name__ == '__main__':
    unittest.main()
