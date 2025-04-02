"""initial migration

Revision ID: 809e876ec601
Revises:
Create Date: 2025-03-30 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
import sqlmodel

# revision identifiers, used by Alembic.
revision: str = '809e876ec601'
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # This is handled by SQLModel's metadata
    pass


def downgrade() -> None:
    # This is handled by SQLModel's metadata
    pass
