from __future__ import annotations

from sqlalchemy import Boolean, Integer, String, ForeignKey, text
from sqlalchemy.orm import Mapped, mapped_column

from app.backend.db.base_class import Base


class Subject(Base):
    __tablename__ = "subjects"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    category_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("categories.id", ondelete="RESTRICT"), nullable=False
    )
    code: Mapped[str] = mapped_column(String(20), nullable=False, unique=True)
    name: Mapped[str] = mapped_column(String(50), nullable=False)
    color: Mapped[str | None] = mapped_column(String(7), nullable=False, server_default=text("'#3788D8'"))
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text("true"))


