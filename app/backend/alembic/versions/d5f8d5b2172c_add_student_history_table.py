"""add student_history table

Revision ID: d5f8d5b2172c
Revises: cced1f6db171
Create Date: 2025-11-12 13:45:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision: str = "d5f8d5b2172c"
down_revision: Union[str, None] = "cced1f6db171"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "student_history",
        sa.Column("history_id", sa.BigInteger(), autoincrement=True, nullable=False),
        sa.Column("student_id", sa.BigInteger(), nullable=False),
        sa.Column("change_type", sa.String(length=20), nullable=False),
        sa.Column("payload", postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column("changed_at", sa.DateTime(), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["student_id"], ["students.student_id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("history_id"),
    )
    op.create_index(op.f("ix_student_history_student_id"), "student_history", ["student_id"], unique=False)
    op.create_index(
        "ix_student_history_student_id_changed_at",
        "student_history",
        ["student_id", "changed_at"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index("ix_student_history_student_id_changed_at", table_name="student_history")
    op.drop_index(op.f("ix_student_history_student_id"), table_name="student_history")
    op.drop_table("student_history")


