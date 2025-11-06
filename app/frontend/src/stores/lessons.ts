import AsyncStorage from "@react-native-async-storage/async-storage";
import { create } from "zustand";
import { createJSONStorage, persist } from "zustand/middleware";

export type RateType = "hourly" | "fixed";
export type Attendance = "show" | "late" | "absent"; // ✅ 출결

export type Lesson = {
  id: string;
  studentId: string;
  subject: string;
  startsAt: string;   // ISO
  durationMin: number;
  rateType: RateType;
  rate: number;
  status: "scheduled" | "done" | "canceled";  // ✅ 완료/취소 상태
  attendance?: Attendance;                    // ✅ 출결
  memo?: string;
  createdAt: number;
};

type LessonStore = {
  lessons: Lesson[];
  addLesson: (l: Omit<Lesson, "id" | "createdAt" | "status"> & { status?: Lesson["status"] }) => string;
  setStatus: (id: string, status: Lesson["status"]) => void;
  toggleDone: (id: string) => void;                 // ✅ 완료 토글
  setAttendance: (id: string, a: Attendance) => void; // ✅ 출결 설정
};

const uid = () => Math.random().toString(36).slice(2, 10);

export const useLessonStore = create<LessonStore>()(
  persist(
    (set, get) => ({
      lessons: [],
      addLesson: (payload) => {
        const id = uid();
        const lesson: Lesson = {
          id,
          createdAt: Date.now(),
          status: payload.status ?? "scheduled",
          attendance: "show", // 기본 출석
          ...payload,
        };
        set({ lessons: [lesson, ...get().lessons] });
        return id;
      },
      setStatus: (id, status) => {
        set({ lessons: get().lessons.map(l => (l.id === id ? { ...l, status } : l)) });
      },
      toggleDone: (id) => {
        set({
          lessons: get().lessons.map(l =>
            l.id === id ? { ...l, status: l.status === "done" ? "scheduled" : "done" } : l
          ),
        });
      },
      setAttendance: (id, a) => {
        set({ lessons: get().lessons.map(l => (l.id === id ? { ...l, attendance: a } : l)) });
      },
    }),
    {
      name: "lesson-store",
      storage: createJSONStorage(() => AsyncStorage),
    }
  )
);
