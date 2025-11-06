// src/stores/students.ts
import { create } from "zustand";
import { StudentDTO, StudentsAPI, StudentUpdateInput } from "../services/students";

export type Student = {
  id: string;
  name: string;
  isAdult?: boolean;
  birthdate?: string;
  grade?: string;
  guardianName?: string;
  guardianPhone?: string;
  email?: string;
  note?: string;
  createdAt: number;
};

type StudentStore = {
  students: Student[];
  loadFromServer: () => Promise<void>;
  createOnServer: (payload: Omit<Student, "id" | "createdAt"> & { isAdult: boolean }) => Promise<string>;
  updateOnServer: (id: string, payload: StudentUpdateInput) => Promise<void>;
  deleteOnServer: (id: string) => Promise<void>;
};

const mapDto = (d: StudentDTO): Student => ({
  id: d.id,
  name: d.name,
  isAdult: d.is_adult,
  birthdate: d.birthdate ?? undefined,
  grade: d.grade ?? undefined,
  guardianName: d.guardian_name ?? undefined,
  guardianPhone: d.guardian_phone ?? undefined,
  email: d.email ?? undefined,
  note: d.note ?? undefined,
  createdAt: new Date(d.created_at).getTime(),
});

export const useStudentStore = create<StudentStore>((set, get) => ({
  students: [],
  loadFromServer: async () => {
    const list = await StudentsAPI.list();
    set({ students: list.map(mapDto) });
  },
  createOnServer: async (payload) => {
    const dto = await StudentsAPI.create(payload);
    const student = mapDto(dto);
    set({ students: [student, ...get().students] });
    return student.id;
  },
  updateOnServer: async (id, payload) => {
    const dto = await StudentsAPI.update(id, payload);
    const updated = mapDto(dto);
    set({
      students: get().students.map((s) => (s.id === id ? updated : s)),
    });
  },
  deleteOnServer: async (id) => {
    await StudentsAPI.remove(id);
    set({
      students: get().students.filter((s) => s.id !== id),
    });
  },
}));
