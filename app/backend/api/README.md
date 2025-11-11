# API v1 Overview

## Students

- `GET /students/list`
  - Query params: `q` (optional), `page` (default 1), `size` (default 20)
  - Returns student records with ID, contact info, schedule preferences, rates, notes, status timestamps.

## Teachers

- `GET /teachers/list`
  - Query params: `q` (optional), `page` (default 1), `size` (default 20)
  - Returns teacher profile data including banking, tax type, availability, rates, metrics.
- `GET /teachers/{teacher_id}`
  - Fetch detailed information for a single teacher.

## Schedules

- `GET /schedules/list`
  - Query params: `teacher_id`, `date_from`, `date_to`, `page`, `size`
  - Returns schedules filtered by teacher and date range.
- `GET /schedules/{schedule_id}`
  - Fetch a single schedule item.
- `POST /schedules/check-conflict`
  - Body or query: `teacher_id`, `lesson_date` (YYYY-MM-DD), `start_time` (HH:MM), `end_time` (HH:MM)
  - Returns whether a conflicting schedule exists.
- `POST /schedules/bulk-generate`
  - Params: `teacher_id`, `weekday` (0=Mon..6=Sun), `start_time`, `end_time`, `date_from`, `date_to`, optional: `schedule_type`, `title`, `color`
  - Creates weekly schedules across the date range; skips conflicts automatically.

### Notes

- All endpoints rely on the shared async session via `get_session`.
- For full CRUD operations, see FastAPI routers in `app/backend/routers/`.
