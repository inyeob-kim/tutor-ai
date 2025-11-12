"""add teacher_id to students and history

Revision ID: 5f8c9b2e7a1d
Revises: 3b52f4c2a98c
Create Date: 2025-11-12 20:45:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "5f8c9b2e7a1d"
down_revision: Union[str, None] = "3b52f4c2a98c"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("students", sa.Column("teacher_id", sa.BigInteger(), nullable=True))
    op.create_index("ix_students_teacher_id", "students", ["teacher_id"], unique=False)
    op.create_foreign_key(
        "fk_students_teacher_id",
        "students",
        "teachers",
        ["teacher_id"],
        ["teacher_id"],
    )

    op.add_column("student_history", sa.Column("teacher_id", sa.BigInteger(), nullable=True))
    op.create_index(
        "ix_student_history_teacher_id",
        "student_history",
        ["teacher_id"],
        unique=False,
    )
    op.create_foreign_key(
        "fk_student_history_teacher_id",
        "student_history",
        "teachers",
        ["teacher_id"],
        ["teacher_id"],
    )


def downgrade() -> None:
    op.drop_constraint("fk_student_history_teacher_id", "student_history", type_="foreignkey")
    op.drop_index("ix_student_history_teacher_id", table_name="student_history")
    op.drop_column("student_history", "teacher_id")

    op.drop_constraint("fk_students_teacher_id", "students", type_="foreignkey")
    op.drop_index("ix_students_teacher_id", table_name="students")
    op.drop_column("students", "teacher_id")

