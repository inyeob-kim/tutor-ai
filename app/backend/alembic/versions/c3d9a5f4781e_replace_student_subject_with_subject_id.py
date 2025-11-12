"""replace student subject text with subject_id

Revision ID: c3d9a5f4781e
Revises: b2a5e7d4f1c3
Create Date: 2025-11-12 21:45:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "c3d9a5f4781e"
down_revision: Union[str, None] = "b2a5e7d4f1c3"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("students", sa.Column("subject_id", sa.Integer(), nullable=True))
    op.create_index("ix_students_subject_id", "students", ["subject_id"], unique=False)
    op.create_foreign_key(
        "fk_students_subject_id",
        "students",
        "subjects",
        ["subject_id"],
        ["id"],
    )
    op.drop_column("students", "subject")


def downgrade() -> None:
    op.add_column(
        "students",
        sa.Column("subject", sa.String(length=100), nullable=True),
    )
    op.drop_constraint("fk_students_subject_id", "students", type_="foreignkey")
    op.drop_index("ix_students_subject_id", table_name="students")
    op.drop_column("students", "subject_id")

