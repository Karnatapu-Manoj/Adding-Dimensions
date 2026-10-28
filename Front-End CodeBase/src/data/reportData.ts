import { formatDate } from '../dateFormat';
import { kgbvSchools } from './kgbvSchools';

export { locations } from './locations';

export const phaseNames = ['Solution Orientation', 'Pedagogical Training', 'Digital and AI Literacy', 'Refresher Training', 'Refresher Training'] as const;
export const trainers = ['Asha Reddy', 'Ravi Kumar', 'Meera Nair', 'Suresh Rao', 'Kavitha Devi', 'Arun Das', 'Neha Sharma', 'Vikram Singh', 'Farah Khan', 'Joseph Mathew', 'Pooja Iyer', 'Mohan Das'] as const;
export type ReportStatus = 'Scheduled' | 'Ongoing' | 'Completed';
export type BatchRecord = {
  index: number; batch: string; udise: string; school: string; state: string; district: string; plan: string; trainer: string;
  startDate: Date; endDate: Date | null; dateText: string; capacity: number; registered: number; attended: number; completed: number;
  attendance: number; status: ReportStatus;
};
export let batchRecords: BatchRecord[] = [];
window.addEventListener('portal:hydrated', event => {
  const detail = (event as CustomEvent).detail;
  const batches = (detail?._dashboard?.batches ?? []) as Record<string, any>[];
  batchRecords = batches.map((row, index) => ({
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
