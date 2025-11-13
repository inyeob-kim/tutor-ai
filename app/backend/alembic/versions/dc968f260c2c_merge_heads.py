"""merge heads

Revision ID: dc968f260c2c
Revises: a6b4c72f8d3e, d7f4a9c1e2ab
Create Date: 2025-11-13 17:24:14.488095

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'dc968f260c2c'
down_revision: Union[str, None] = ('a6b4c72f8d3e', 'd7f4a9c1e2ab')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass
