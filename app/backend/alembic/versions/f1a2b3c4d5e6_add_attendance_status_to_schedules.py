"""add attendance_status to schedules

Revision ID: f1a2b3c4d5e6
Revises: dc968f260c2c
Create Date: 2025-01-15 12:00:00.000000
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = "f1a2b3c4d5e6"
down_revision: Union[str, None] = "dc968f260c2c"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Create attendance_status enum if it doesn't exist
    op.execute("""
        DO $$ BEGIN
            CREATE TYPE attendance_status AS ENUM ('present', 'late', 'absent');
        EXCEPTION
            WHEN duplicate_object THEN null;
        END $$;
    """)
    
    # Add attendance_status column to schedules table
    op.add_column(
        "schedules",
        sa.Column(
            "attendance_status",
            postgresql.ENUM("present", "late", "absent", name="attendance_status"),
            nullable=True,
        ),
    )


def downgrade() -> None:
    # Remove attendance_status column
    op.drop_column("schedules", "attendance_status")
    
    # Drop enum type (only if no other tables use it)
    op.execute("DROP TYPE IF EXISTS attendance_status")

