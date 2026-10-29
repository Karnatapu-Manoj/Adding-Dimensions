import { formatDate } from '../dateFormat';
import { kgbvSchools } from './kgbvSchools';

export { locations } from './locations';

export const phaseNames = ['Orientation', 'Device & Content Use', 'Digital Skills', 'Refresher I', 'Refresher II'] as const;
const phaseDates: [number, number, number][] = [[2026, 9, 20], [2026, 9, 24], [2026, 9, 28], [2026, 10, 4], [2026, 10, 10]];
export const trainers = ['Asha Reddy', 'Ravi Kumar', 'Meera Nair', 'Suresh Rao', 'Kavitha Devi', 'Arun Das', 'Neha Sharma', 'Vikram Singh', 'Farah Khan', 'Joseph Mathew', 'Pooja Iyer', 'Mohan Das'] as const;
export type ReportStatus = 'Scheduled' | 'Ongoing' | 'Completed';
export type BatchRecord = {
  index: number; batch: string; udise: string; school: string; state: string; district: string; phase: string; trainingPlan: string; participant: 'Teacher' | 'Student'; plan: string; trainer: string;
  dashboardStatus: ReportStatus; dashboardAttendance: number; dashboardCompletion: number; teacherParticipants: number; studentParticipants: number;
  startDate: Date; endDate: Date | null; dateText: string; capacity: number; registered: number; attended: number; completed: number;
  attendance: number; status: ReportStatus;
};
export let batchRecords: BatchRecord[] = [];
window.addEventListener('portal:hydrated', event => {
  const detail = (event as CustomEvent).detail;
  const batches = (detail?._dashboard?.batches ?? []) as Record<string, any>[];
  batchRecords = batches.map((row, index) => ({
    phase: row.phase || '', trainingPlan: row.plan || '', participant: 'Teacher' as const,
    dashboardStatus: (row.status === 'upcoming' ? 'Scheduled' : row.status === 'completed' ? 'Completed' : 'Ongoing') as ReportStatus,
    dashboardAttendance: row.attendance || 0, dashboardCompletion: row.completion || 0, teacherParticipants: row.capacity || 0, studentParticipants: 0,
    index, batch: row.batch, udise: row.udise, school: row.school, state: row.state,
    district: row.district, plan: row.plan, trainer: row.trainer,
    startDate: new Date(`${row.startDate}T00:00:00`), endDate: row.endDate ? new Date(`${row.endDate}T00:00:00`) : null,
    dateText: row.date, capacity: row.capacity, registered: row.registered, attended: row.attended,
    completed: row.completed, attendance: row.attendance,
    status: row.status === 'upcoming' ? 'Scheduled' : row.status === 'completed' ? 'Completed' : 'Ongoing'
  }));
});
export const isoDate = (date: Date) => `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;
export const uniqueSorted = (values: string[]) => [...new Set(values)].sort((a, b) => a.localeCompare(b));
export const statusNames = ['Scheduled', 'Ongoing', 'Completed'] as const;
