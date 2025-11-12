"""add subject_id to teachers and teacher_history

Revision ID: 7d4e6b1c9dbe
Revises: 5f8c9b2e7a1d
Create Date: 2025-11-12 21:05:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "7d4e6b1c9dbe"
down_revision: Union[str, None] = "5f8c9b2e7a1d"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("teachers", sa.Column("subject_id", sa.Integer(), nullable=True))
    op.create_index("ix_teachers_subject_id", "teachers", ["subject_id"], unique=False)
    op.create_foreign_key(
        "fk_teachers_subject_id",
        "teachers",
        "subjects",
        ["subject_id"],
        ["id"],
    )

    op.add_column("teacher_history", sa.Column("subject_id", sa.Integer(), nullable=True))
    op.create_index(
        "ix_teacher_history_subject_id",
        "teacher_history",
        ["subject_id"],
        unique=False,
    )
    op.create_foreign_key(
        "fk_teacher_history_subject_id",
        "teacher_history",
        "subjects",
        ["subject_id"],
        ["id"],
    )


def downgrade() -> None:
    op.drop_constraint("fk_teacher_history_subject_id", "teacher_history", type_="foreignkey")
    op.drop_index("ix_teacher_history_subject_id", table_name="teacher_history")
    op.drop_column("teacher_history", "subject_id")

    op.drop_constraint("fk_teachers_subject_id", "teachers", type_="foreignkey")
    op.drop_index("ix_teachers_subject_id", table_name="teachers")
    op.drop_column("teachers", "subject_id")

