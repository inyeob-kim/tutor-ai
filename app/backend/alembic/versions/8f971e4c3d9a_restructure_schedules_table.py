"""restructure schedules table

Revision ID: 8f971e4c3d9a
Revises: ff6c7c3b8f1e
Create Date: 2025-11-12 16:05:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision: str = "8f971e4c3d9a"
down_revision: Union[str, None] = "ff6c7c3b8f1e"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Drop old indexes and constraints
    with op.batch_alter_table("schedules", schema=None) as batch_op:
        batch_op.drop_index("idx_date")
        batch_op.drop_index("idx_teacher")
        batch_op.drop_index("idx_student")
        batch_op.drop_constraint("uniq_teacher_date_time", type_="unique")

    # Drop legacy columns
    with op.batch_alter_table("schedules", schema=None) as batch_op:
        batch_op.drop_column("schedule_type")
        batch_op.drop_column("title")
        batch_op.drop_column("color")
        batch_op.alter_column("student_id", existing_type=sa.BigInteger(), nullable=False)

    # Add new columns
    with op.batch_alter_table("schedules", schema=None) as batch_op:
        batch_op.add_column(sa.Column("subject", sa.String(length=50), nullable=False))
        batch_op.add_column(sa.Column("status", sa.String(length=20), nullable=False, server_default="confirmed"))
        batch_op.add_column(sa.Column("cancelled_at", sa.DateTime(), nullable=True))
        batch_op.add_column(sa.Column("cancelled_by", sa.BigInteger(), nullable=True))
        batch_op.add_column(sa.Column("cancel_reason", sa.Text(), nullable=True))

    # Add new indexes
    op.create_index("ix_schedules_teacher_id_lesson_date", "schedules", ["teacher_id", "lesson_date"], unique=False)
    op.create_index("ix_schedules_status", "schedules", ["status"], unique=False)
    op.create_index("ix_schedules_subject", "schedules", ["subject"], unique=False)


def downgrade() -> None:
    # Drop new indexes
    op.drop_index("ix_schedules_subject", table_name="schedules")
    op.drop_index("ix_schedules_status", table_name="schedules")
    op.drop_index("ix_schedules_teacher_id_lesson_date", table_name="schedules")

    # Remove new columns
    with op.batch_alter_table("schedules", schema=None) as batch_op:
        batch_op.drop_column("cancel_reason")
        batch_op.drop_column("cancelled_by")
        batch_op.drop_column("cancelled_at")
        batch_op.drop_column("status")
        batch_op.drop_column("subject")

    # Restore student_id nullability and legacy columns
    with op.batch_alter_table("schedules", schema=None) as batch_op:
        batch_op.alter_column("student_id", existing_type=sa.BigInteger(), nullable=True)
        batch_op.add_column(sa.Column("color", sa.String(length=7), nullable=False, server_default="#3788D8"))
        batch_op.add_column(sa.Column("title", sa.String(length=100), nullable=True))
        batch_op.add_column(
            sa.Column(
                "schedule_type",
                sa.Enum("lesson", "available", "vacation", "personal", name="schedule_type"),
                nullable=False,
            )
        )

    # Restore previous indexes and constraints
    op.create_index("idx_student", "schedules", ["student_id"], unique=False)
    op.create_index("idx_date", "schedules", ["lesson_date"], unique=False)
    op.create_index("idx_teacher", "schedules", ["teacher_id"], unique=False)
    op.create_unique_constraint(
        "uniq_teacher_date_time",
        "schedules",
        ["teacher_id", "lesson_date", "start_time"],
    )


