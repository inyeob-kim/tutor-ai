"""make teacher tax_type nullable

Revision ID: ff6c7c3b8f1e
Revises: ea2c1f4d6a8b
Create Date: 2025-11-12 15:35:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision: str = "ff6c7c3b8f1e"
down_revision: Union[str, None] = "ea2c1f4d6a8b"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.alter_column(
        "teachers",
        "tax_type",
        existing_type=postgresql.ENUM(
            "사업소득", "기타소득", "프리랜서", "미신고", name="teacher_tax_type"
        ),
        server_default=None,
        nullable=True,
    )


def downgrade() -> None:
    op.alter_column(
        "teachers",
        "tax_type",
        existing_type=postgresql.ENUM(
            "사업소득", "기타소득", "프리랜서", "미신고", name="teacher_tax_type"
        ),
        server_default="사업소득",
        nullable=False,
    )


