"""add categories and subjects tables and link schedules to subjects

Revision ID: 12b3fba7c34e
Revises: 8f971e4c3d9a
Create Date: 2025-11-12 18:30:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "12b3fba7c34e"
down_revision: Union[str, None] = "8f971e4c3d9a"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "categories",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("name", sa.String(length=50), nullable=False),
        sa.Column("icon", sa.String(length=100), nullable=True),
        sa.Column("sort_order", sa.Integer(), nullable=False, server_default=sa.text("0")),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.text("true")),
    )

    op.create_table(
        "subjects",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("category_id", sa.Integer(), nullable=False),
        sa.Column("code", sa.String(length=20), nullable=False),
        sa.Column("name", sa.String(length=50), nullable=False),
        sa.Column("color", sa.String(length=7), nullable=False, server_default=sa.text("'#3788D8'")),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.text("true")),
        sa.ForeignKeyConstraint(["category_id"], ["categories.id"]),
        sa.UniqueConstraint("code"),
    )

    op.drop_table("teacher_subjects")

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

    op.drop_index("ix_schedules_subject", table_name="schedules")
    op.add_column("schedules", sa.Column("subject_id", sa.Integer(), nullable=True))
    op.create_foreign_key(
        "fk_schedules_subject_id_subjects",
        "schedules",
        "subjects",
        ["subject_id"],
        ["id"],
    )
    op.create_index("ix_schedules_subject_id", "schedules", ["subject_id"], unique=False)
    op.drop_column("schedules", "subject")
    op.alter_column("schedules", "subject_id", existing_type=sa.Integer(), nullable=False)


def downgrade() -> None:
    op.alter_column("schedules", "subject_id", existing_type=sa.Integer(), nullable=True)
    op.add_column("schedules", sa.Column("subject", sa.String(length=50), nullable=False))
    op.drop_index("ix_schedules_subject_id", table_name="schedules")
    op.drop_constraint("fk_schedules_subject_id_subjects", "schedules", type_="foreignkey")
    op.drop_column("schedules", "subject_id")
    op.create_index("ix_schedules_subject", "schedules", ["subject"], unique=False)

    op.drop_table("teacher_subjects")
    op.create_table(
        "teacher_subjects",
        sa.Column("teacher_id", sa.BigInteger(), nullable=False),
        sa.Column("subject", sa.String(length=50), nullable=False),
        sa.Column("hourly_rate", sa.Integer(), nullable=True),
        sa.ForeignKeyConstraint(["teacher_id"], ["teachers.teacher_id"]),
        sa.PrimaryKeyConstraint("teacher_id", "subject"),
    )

    op.drop_table("subjects")
    op.drop_table("categories")

