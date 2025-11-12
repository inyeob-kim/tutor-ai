"""remove subject_id from teacher_history

Revision ID: 8ac3d1f2e4bf
Revises: 7d4e6b1c9dbe
Create Date: 2025-11-12 21:15:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "8ac3d1f2e4bf"
down_revision: Union[str, None] = "7d4e6b1c9dbe"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.drop_constraint("fk_teacher_history_subject_id", "teacher_history", type_="foreignkey")
    op.drop_index("ix_teacher_history_subject_id", table_name="teacher_history")
    op.drop_column("teacher_history", "subject_id")


def downgrade() -> None:
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

