from sqlalchemy import Enum

lesson_place = Enum("offline", "online", name="lesson_place")
recur_freq = Enum("weekly", "biweekly", name="recur_freq")
attendance_status = Enum("present", "late", "absent", name="attendance_status")
invoice_status = Enum("draft", "sent", "partial", "paid", "void", name="invoice_status")
pay_status = Enum("pending", "completed", "failed", "refunded", "partial", name="pay_status")
pay_method = Enum("kakao", "bank", "card", "cash", "link", name="pay_method")
stt_status = Enum("queued", "processing", "completed", "failed", name="stt_status")
teacher_tax_type = Enum("사업소득", "기타소득", "프리랜서", "미신고", name="teacher_tax_type")
schedule_type = Enum("lesson", "available", "vacation", "personal", name="schedule_type")
auth_provider = Enum("google", "kakao", "naver", "apple", name="auth_provider")
