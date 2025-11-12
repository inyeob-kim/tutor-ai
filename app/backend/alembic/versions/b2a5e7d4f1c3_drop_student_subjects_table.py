"""drop student_subjects table

Revision ID: b2a5e7d4f1c3
Revises: 9e6f2d1a4c55
Create Date: 2025-11-12 21:35:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "b2a5e7d4f1c3"
down_revision: Union[str, None] = "9e6f2d1a4c55"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.drop_table("student_subjects")


def downgrade() -> None:
    op.create_table(
        "student_subjects",
        sa.Column("student_id", sa.BigInteger(), nullable=False),
        sa.Column("teacher_id", sa.BigInteger(), nullable=False),
        sa.Column("subject", sa.String(length=50), nullable=False),
        sa.Column("hourly_rate", sa.Integer(), nullable=False),
        sa.Column("lesson_day", sa.String(length=20), nullable=True),
        sa.Column("start_time", sa.Time(), nullable=True),
        sa.Column("end_time", sa.Time(), nullable=True),
        sa.ForeignKeyConstraint(["student_id"], ["students.student_id"]),
        sa.ForeignKeyConstraint(["teacher_id"], ["teachers.teacher_id"]),
        sa.PrimaryKeyConstraint("student_id", "teacher_id", "subject"),
    )

