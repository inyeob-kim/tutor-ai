"""change schedule times to text

Revision ID: 3b52f4c2a98c
Revises: 12b3fba7c34e
Create Date: 2025-11-12 20:15:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "3b52f4c2a98c"
down_revision: Union[str, None] = "12b3fba7c34e"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.alter_column(
        "schedules",
        "start_time",
        type_=sa.String(length=5),
        existing_type=sa.Time(),
        nullable=False,
        postgresql_using="to_char(start_time, 'HH24:MI')",
    )
    op.alter_column(
        "schedules",
        "end_time",
        type_=sa.String(length=5),
        existing_type=sa.Time(),
        nullable=False,
        postgresql_using="to_char(end_time, 'HH24:MI')",
    )


def downgrade() -> None:
    op.alter_column(
        "schedules",
        "start_time",
        type_=sa.Time(),
        existing_type=sa.String(length=5),
        nullable=False,
        postgresql_using="start_time::time",
    )
    op.alter_column(
        "schedules",
        "end_time",
        type_=sa.Time(),
        existing_type=sa.String(length=5),
        nullable=False,
        postgresql_using="end_time::time",
    )

