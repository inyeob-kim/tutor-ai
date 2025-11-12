"""drop teacher_subjects table

Revision ID: 9e6f2d1a4c55
Revises: 8ac3d1f2e4bf
Create Date: 2025-11-12 21:25:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "9e6f2d1a4c55"
down_revision: Union[str, None] = "8ac3d1f2e4bf"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.drop_table("teacher_subjects")


def downgrade() -> None:
    op.create_table(
        "teacher_subjects",
        sa.Column("teacher_id", sa.BigInteger(), nullable=False),
        sa.Column("subject_id", sa.Integer(), nullable=False),
        sa.Column("price_per_hour", sa.Integer(), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.text("true")),
        sa.ForeignKeyConstraint(["subject_id"], ["subjects.id"]),
        sa.ForeignKeyConstraint(["teacher_id"], ["teachers.teacher_id"]),
        sa.PrimaryKeyConstraint("teacher_id", "subject_id"),
    )

