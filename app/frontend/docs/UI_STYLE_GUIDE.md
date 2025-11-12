# UI Style Guide  
**Version 1.1 — Flutter 프로젝트용 (Toss-inspired Minimal UI)**  
**Design Principle:** Simple, Clean, Spacious (심플 + 깔끔 + 여백)

---

## 🎨 1. Color System (Design Tokens)

| Token            | HEX       | 용도 |
|------------------|-----------|------|
| `Primary`        | `#1E64FF` | 메인 액션 / Primary 버튼 / 활성 요소 |
| `PrimaryDark`    | `#0F53E6` | Pressed / Highlight 상태 |
| `PrimaryLight`   | `#EAF3FF` | 칩 / 강조 배경 |
| `Background`     | `#F5F6F8` | 전체 배경 |
| `Surface/Card`   | `#FFFFFF` | 카드 / 섹션 컨테이너 |
| `Divider`        | `#EDEFF2` | 구분선 / 리스트 구분 |
| `TextPrimary`    | `#111827` | 제목 / 메인 텍스트 |
| `TextSecondary`  | `#6B7280` | 보조 텍스트 |
| `TextMuted`      | `#9CA3AF` | 설명 / 서브 텍스트 |
| `Success`        | `#10B981` | 성공 상태 |
| `Warning`        | `#F59E0B` | 경고 |
| `Error`          | `#EF4444` | 오류 |

---

## ✏️ 2. Typography (글씨체 & 스타일)

### ✅ 기본 폰트
- **Pretendard** 또는 **Noto Sans KR**

### ✅ 텍스트 레벨 정의

| Name      | Size | Weight | 사용 위치 |
|-----------|------|--------|----------|
| `H1`      | 22–24px | 700 | 큰 섹션 제목 |
| `H2`      | 18–20px | 700 | 카드 / 리스트 제목 |
| `Body`    | 16px    | 500–600 | 일반 텍스트 |
| `Caption` | 12–13px | 500 | 칩 / 라벨 / 작은 텍스트 |

---

## 🧩 3. Components

### ✅ Card

| Property  | Value |
|-----------|-------|
| Background | `Surface/Card` |
| Padding | `16–20px` |
| Corner Radius | `16–20px` |
| Elevation | `0–1` |
| Between Cards | `12–16px` |

---

### ✅ Chip / Badge

| Property | Value |
|----------|-------|
| Background | `PrimaryLight` |
| Text Color | `Primary` |
| Radius | `12px` |
| Padding | `10px (Horizontal) / 6px (Vertical)` |

---

### ✅ Button

| Type | Style |
|------|-------|
| **Primary Button** | 배경: `Primary`, 텍스트: `white`, radius: `12px` |
| **Text Button** | 텍스트: `Primary`, 배경 없음 |

---

### ✅ Bottom Navigation (Tab Bar)

| Property | Value |
|----------|-------|
| Background | `Surface/Card` |
| Shadow | 없음 |
| Selected Color | `Primary` |
| Unselected Color | `TextMuted` |
| Icon size | `24px` |
| Label size | `11–12px` |

---

## 🧱 4. Layout / Spacing

| Element                | Spacing |
|-----------------------|----------|
| 화면 기본 padding     | `16–20px` |
| 카드 간 간격         | `12–16px` |
| 컨테이너 내부 padding | `16–20px` |
| Row 수평 간격        | `8–12px` |

> ✅ 핵심: **여백을 넉넉히 해서 UI가 답답해 보이지 않도록 한다.**

---

## 🖼 5. Icon Style

| Property | Value |
|----------|-------|
| Icon Style | Outline (선명하고 심플) |
| Icon Highlight Background | `PrimaryLight` |
| Radius | `8px` |

---

## 🧪 6. Shadow & Elevation

| Element | Elevation |
|---------|-----------|
| Card | `0–1` |
| FAB 등 Floating 요소 | `4–6` |

---

> 이 문서는 Flutter 프로젝트 UI 일관성을 위한 Reference 문서입니다.
