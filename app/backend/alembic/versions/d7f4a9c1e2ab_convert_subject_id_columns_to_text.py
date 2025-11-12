"""convert subject_id columns to text

Revision ID: d7f4a9c1e2ab
Revises: c3d9a5f4781e
Create Date: 2025-11-12 21:55:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "d7f4a9c1e2ab"
down_revision: Union[str, None] = "c3d9a5f4781e"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # students
    op.drop_constraint("fk_students_subject_id", "students", type_="foreignkey")
    op.alter_column(
        "students",
        "subject_id",
        existing_type=sa.Integer(),
        type_=sa.String(length=50),
        existing_nullable=True,
        postgresql_using="subject_id::text",
    )

    # teachers
    op.drop_constraint("fk_teachers_subject_id", "teachers", type_="foreignkey")
    op.alter_column(
        "teachers",
        "subject_id",
        existing_type=sa.Integer(),
        type_=sa.String(length=50),
        existing_nullable=True,
        postgresql_using="subject_id::text",
    )

    # schedules
    op.drop_constraint("fk_schedules_subject_id_subjects", "schedules", type_="foreignkey")
    op.alter_column(
        "schedules",
        "subject_id",
        existing_type=sa.Integer(),
        type_=sa.String(length=50),
        existing_nullable=False,
        postgresql_using="subject_id::text",
    )


def downgrade() -> None:
    # schedules
    op.alter_column(
        "schedules",
        "subject_id",
        existing_type=sa.String(length=50),
        type_=sa.Integer(),
        existing_nullable=False,
        postgresql_using="subject_id::integer",
    )
    op.create_foreign_key(
        "fk_schedules_subject_id_subjects",
        "schedules",
        "subjects",
        ["subject_id"],
        ["id"],
    )

    # teachers
    op.alter_column(
        "teachers",
        "subject_id",
        existing_type=sa.String(length=50),
        type_=sa.Integer(),
        existing_nullable=True,
        postgresql_using="subject_id::integer",
    )
    op.create_foreign_key(
        "fk_teachers_subject_id",
        "teachers",
        "subjects",
        ["subject_id"],
        ["id"],
    )

    # students
    op.alter_column(
        "students",
        "subject_id",
        existing_type=sa.String(length=50),
        type_=sa.Integer(),
        existing_nullable=True,
        postgresql_using="subject_id::integer",
    )
    op.create_foreign_key(
        "fk_students_subject_id",
        "students",
        "subjects",
        ["subject_id"],
        ["id"],
    )

