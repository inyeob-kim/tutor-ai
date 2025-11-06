// src/services/students.ts
import { http } from "./http";

export type StudentDTO = {
  id: string;
  name: string;
  is_adult: boolean;
  birthdate?: string | null;
  grade?: string | null;
  guardian_name?: string | null;
  guardian_phone?: string | null;
  email?: string | null;
  note?: string | null;
  created_at: string;
};

export type StudentCreateInput = {
  name: string;
  isAdult: boolean;
  birthdate?: string;
  grade?: string;
  guardianName?: string;
  guardianPhone?: string;
  email?: string;
  note?: string;
};

export type StudentUpdateInput = Partial<StudentCreateInput>;

export const StudentsAPI = {
  create: (p: StudentCreateInput) =>
    http<StudentDTO>("/students", {
      method: "POST",
      body: JSON.stringify({
        name: p.name,
        is_adult: p.isAdult,
        birthdate: p.birthdate,
        grade: p.grade,
        guardian_name: p.isAdult ? undefined : p.guardianName,
        guardian_phone: p.isAdult ? undefined : p.guardianPhone,
        email: p.email,
        note: p.note,
      }),
    }),
  list: () => http<StudentDTO[]>("/students"),
  get: (id: string) => http<StudentDTO>(`/students/${id}`),
  update: (id: string, p: StudentUpdateInput) =>
    http<StudentDTO>(`/students/${id}`, {
      method: "PATCH",
      body: JSON.stringify({
        name: p.name,
        is_adult: p.isAdult,
        birthdate: p.birthdate,
        grade: p.grade,
        guardian_name: p.isAdult ? undefined : p.guardianName,
        guardian_phone: p.isAdult ? undefined : p.guardianPhone,
        email: p.email,
        note: p.note,
      }),
    }),
  remove: (id: string) =>
    http<never>(`/students/${id}`, { method: "DELETE" }),
};
