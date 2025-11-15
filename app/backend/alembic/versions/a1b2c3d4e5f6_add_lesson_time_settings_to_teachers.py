"""add lesson time settings to teachers

Revision ID: a1b2c3d4e5f6
Revises: f1a2b3c4d5e6
Create Date: 2024-12-19 12:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'a1b2c3d4e5f6'
down_revision: Union[str, None] = 'f1a2b3c4d5e6'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 수업 시간 설정 컬럼 추가
    op.add_column('teachers', sa.Column('lesson_start_hour', sa.Integer(), nullable=True, server_default='12'))
    op.add_column('teachers', sa.Column('lesson_end_hour', sa.Integer(), nullable=True, server_default='22'))
    op.add_column('teachers', sa.Column('exclude_weekends', sa.Boolean(), nullable=False, server_default='false'))


def downgrade() -> None:
    op.drop_column('teachers', 'exclude_weekends')
    op.drop_column('teachers', 'lesson_end_hour')
    op.drop_column('teachers', 'lesson_start_hour')

