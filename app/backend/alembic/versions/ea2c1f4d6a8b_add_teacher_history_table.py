"""add teacher_history table

Revision ID: ea2c1f4d6a8b
Revises: d5f8d5b2172c
Create Date: 2025-11-12 15:10:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision: str = "ea2c1f4d6a8b"
down_revision: Union[str, None] = "d5f8d5b2172c"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "teacher_history",
        sa.Column("history_id", sa.BigInteger(), autoincrement=True, nullable=False),
        sa.Column("teacher_id", sa.BigInteger(), nullable=False),
        sa.Column("change_type", sa.String(length=20), nullable=False),
        sa.Column("payload", postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column("changed_at", sa.DateTime(), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["teacher_id"], ["teachers.teacher_id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("history_id"),
    )
    op.create_index(
        op.f("ix_teacher_history_teacher_id"),
        "teacher_history",
        ["teacher_id"],
        unique=False,
    )
    op.create_index(
        "ix_teacher_history_teacher_id_changed_at",
        "teacher_history",
        ["teacher_id", "changed_at"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index("ix_teacher_history_teacher_id_changed_at", table_name="teacher_history")
    op.drop_index(op.f("ix_teacher_history_teacher_id"), table_name="teacher_history")
    op.drop_table("teacher_history")


