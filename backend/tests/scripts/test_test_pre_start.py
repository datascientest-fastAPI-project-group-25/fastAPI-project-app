from unittest.mock import MagicMock, patch

from sqlmodel import select

from app.tests_pre_start import init, logger


def test_init_successful_connection() -> None:
    """Test that the database connection initialization works correctly."""
    # Mock the database engine
    engine_mock = MagicMock()

    # Mock the session and its exec method
    session_mock = MagicMock()
    exec_mock = MagicMock(return_value=True)
    session_mock.configure_mock(**{"exec.return_value": exec_mock})

    # Patch the necessary dependencies
    with (
        patch("sqlmodel.Session", return_value=session_mock),
        patch.object(logger, "info"),
        patch.object(logger, "error"),
        patch.object(logger, "warn"),
    ):
        # Execute the function under test
        try:
            init(engine_mock)
            connection_successful = True
        except Exception as e:
            connection_successful = False
            error_message = str(e)

        # Verify the function executed without errors
        if not connection_successful:
            raise ValueError(
                f"The database connection should be successful and not raise an exception. "
                f"Error: {error_message if 'error_message' in locals() else 'Unknown error'}"
            )

        # Verify the session executed the expected query
        if not session_mock.exec.called_once_with(select(1)):
            raise ValueError(
                "The session should execute a select statement once. "
                f"Call count: {session_mock.exec.call_count}"
            )
