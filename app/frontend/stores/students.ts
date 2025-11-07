// frontend/stores/students.ts
import { create } from "zustand";

export type StudentCreateIn = {
  name: string;
  isAdult: boolean;
  birthdate?: string;
  grade?: string;
  guardianName?: string;
  guardianPhone?: string;
  email?: string;
  note?: string;
};

export type Student = {
  id: string;
  name: string;
  isAdult: boolean;
  birthdate?: string;
  grade?: string;
  guardianName?: string;
  guardianPhone?: string;
  email?: string;
  note?: string;
};

type StudentState = {
  students: Student[];
  createOnServer: (input: StudentCreateIn) => Promise<string>;
};

const genId = () => `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;

export const useStudentStore = create<StudentState>((set) => ({
  students: [],
  createOnServer: async (input) => {
    await new Promise((resolve) => setTimeout(resolve, 300));

    const id = genId();
    set((s) => ({
      students: [{ id, ...input }, ...s.students],
    }));

    return id;
  },
}));
