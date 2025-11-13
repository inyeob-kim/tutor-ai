"""Update teachers table with nickname/account_name/bank_code

Revision ID: a6b4c72f8d3e
Revises: 27d930263f9f
Create Date: 2025-11-13 10:15:00.000000
"""
from __future__ import annotations

import json
import re
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

from app.backend.core.crypto import aesgcm_decrypt_str, aesgcm_encrypt_str

# revision identifiers, used by Alembic.
revision: str = "a6b4c72f8d3e"
down_revision: Union[str, None] = "27d930263f9f"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def _decrypt_value(raw: str | None) -> str | None:
    if raw is None:
        return None
    try:
        envelope = json.loads(raw)
        if isinstance(envelope, dict) and "ct" in envelope:
            return aesgcm_decrypt_str(envelope)
    except json.JSONDecodeError:
        return raw
    except Exception:
        return raw
    return raw


def _encrypt_value(value: str | None) -> str | None:
    if value is None:
        return None
    return json.dumps(aesgcm_encrypt_str(value))


def upgrade() -> None:
    op.add_column("teachers", sa.Column("nickname", sa.String(length=50), nullable=True))
    op.add_column("teachers", sa.Column("account_name", sa.Text(), nullable=True))
    op.add_column("teachers", sa.Column("bank_code", sa.String(length=3), nullable=True))

    bind = op.get_bind()
    metadata = sa.MetaData()
    metadata.reflect(bind=bind, only=("teachers",))
    teachers = metadata.tables["teachers"]

    used_nicknames: set[str] = set()
    max_len = 50

    def make_nickname(base: str, teacher_id: int) -> str:
        base = re.sub(r"\s+", "_", base).strip("_")
        if not base:
            base = f"teacher_{teacher_id}"
        suffix = 0
        candidate = base[:max_len]
        while candidate in used_nicknames:
            suffix += 1
            suffix_txt = f"_{suffix}"
            candidate = (base[: max_len - len(suffix_txt)] + suffix_txt).strip("_") or f"teacher_{teacher_id}_{suffix}"
        used_nicknames.add(candidate)
        return candidate

    rows = list(bind.execute(sa.select(teachers.c.teacher_id, teachers.c.name)))
    for row in rows:
        plain_name = _decrypt_value(row.name)
        nickname_source = plain_name or ""
        nickname_value = make_nickname(nickname_source, row.teacher_id)
        account_name_encrypted = _encrypt_value(plain_name) if plain_name else None
        bind.execute(
            teachers.update()
            .where(teachers.c.teacher_id == row.teacher_id)
            .values(
                nickname=nickname_value,
                account_name=account_name_encrypted,
            )
        )

    op.alter_column("teachers", "nickname", nullable=False)
    op.create_unique_constraint("uq_teachers_nickname", "teachers", ["nickname"])

    op.drop_column("teachers", "name")
    op.drop_column("teachers", "bank_name")


def downgrade() -> None:
    op.add_column("teachers", sa.Column("bank_name", sa.Text(), nullable=True))
    op.add_column("teachers", sa.Column("name", sa.Text(), nullable=True))

    bind = op.get_bind()
    metadata = sa.MetaData()
    metadata.reflect(bind=bind, only=("teachers",))
    teachers = metadata.tables["teachers"]

    rows = list(bind.execute(sa.select(teachers.c.teacher_id, teachers.c.nickname, teachers.c.account_name)))
    for row in rows:
        name_value = row.nickname
        bind.execute(
            teachers.update()
            .where(teachers.c.teacher_id == row.teacher_id)
            .values(name=name_value)
        )

    op.drop_constraint("uq_teachers_nickname", "teachers", type_="unique")
    op.drop_column("teachers", "bank_code")
    op.drop_column("teachers", "account_name")
    op.drop_column("teachers", "nickname")
    op.alter_column("teachers", "name", nullable=False)

