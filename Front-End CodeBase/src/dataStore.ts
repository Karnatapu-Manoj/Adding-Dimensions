import { accessToken, apiPost } from './api';

type Row = Record<string, unknown>;
export type Snapshot = Record<string, unknown>;
declare global { interface Window { PORTAL_DASHBOARD?: { batches: Record<string, unknown>[] }; } }
const cache = new Map<string, string>();
const routes: Record<string, string> = {
  "teacher-training-projects": "Projects",
  "teacher-training-plans": "TrainingPlans",
  "teacher-training-project-plan-associations": "ProjectPlans",
  "teacher-training-batch-plan-uses": "Batches",
  "teacher-training-trainer-profiles": "Trainers",
  "teacher-training-trainer-availability": "TrainerAvailability",
  "teacher-training-trainees": "Trainees",
  "teacher-training-registrations": "Registrations",
  "teacher-training-attendance-records": "Attendance",
  "teacher-training-attendance-exclusions": "AttendanceExclusions",
  "teacher-training-assessment-form-master": "AssessmentForms",
  "teacher-training-assessment-records": "Assessments",
  "teacher-training-feedback-records": "Feedback",
  "teacher-training-certificate-templates": "CertificateTemplates",
  "teacher-training-certificates": "Certificates",
  "teacher-training-holidays": "Holidays",
  "teacher-training-users": "Users",
  "teacher-training-odoo-project-catalog": "OdooProjects",
  "teacher-training-schools": "Schools",
  "teacher-training-learning-resources": "Resources",
  "teacher-training-resource-usage": "ResourceProgress",
  "teacher-training-external-course-records": "ExternalCourses",
  "teacher-training-eligible-teachers": "EligibleTeachers",
  "teacher-training-eligible-students": "EligibleStudents",
  "teacher-training-audit": "Audit",
  "teacher-training-trainer-audit": "TrainerAudit",
  "teacher-training-certificate-audit": "CertificateAudit",
  "teacher-training-school-assignments": "Settings",
  "teacher-training-school-access": "Settings",
  "teacher-training-school-admin-assignments": "Settings",
  "teacher-training-state-access": "Settings",
  "teacher-training-cluster-master": "Settings",
  "teacher-training-approved-venues": "Settings",
  "teacher-training-school-eligibility": "Settings",
  "teacher-training-eligible-participants": "Settings",
  "teacher-training-holiday-policy": "Settings",
  "teacher-training-batch-dependent-records": "Settings"
};
let pending = 0;
let tail: Promise<void> = Promise.resolve();
let failed: Error | null = null;
const scalarKeys = new Set(['teacher-training-holiday-policy', 'teacher-training-state-access', 'teacher-training-school-access']);
const rowId = (row: Row) => String(row.id ?? row.userId ?? row.traineeId ?? '');
const comparable = (row: Row) => JSON.stringify(Object.fromEntries(Object.entries(row).filter(([key]) => !key.startsWith('_')).sort(([a], [b]) => a.localeCompare(b))));

export function installSnapshot(snapshot: Snapshot) {
  window.PORTAL_DASHBOARD = snapshot._dashboard as Window['PORTAL_DASHBOARD'];
  for (const key of Object.keys(routes)) {
    let value = snapshot[key] ?? [];
    if (key === 'teacher-training-feedback-records' && Array.isArray(value)) value = value.map(row => ({...row, score: row.ratingScore ?? row.score, maxMarks: row.ratingMaxMarks ?? row.maxMarks}));
    if (scalarKeys.has(key) && Array.isArray(value)) value = value[0]?.value ?? (key.endsWith('policy') ? 'block' : {});
    cache.set(key, typeof value === 'string' ? value : JSON.stringify(value));
  }
  window.dispatchEvent(new CustomEvent('portal:hydrated', { detail: snapshot }));
}

export async function hydrateData() {
  if (!accessToken()) { installSnapshot(await apiPost<Snapshot>('Public/GetData')); return; }
  const snapshot = { ...await apiPost<Snapshot>('Workspace/GetData'), ...await apiPost<Snapshot>('Reports/GetData') };
  installSnapshot(snapshot);
  return snapshot;
}

export const dataStore = {
  getItem(key: string): string | null { return cache.get(key) ?? null; },
  key(index: number): string | null { return [...cache.keys()][index] ?? null; },
  get length() { return cache.size; },
  clear() { cache.clear(); failed = null; },
  async flush() { await tail; if (failed) throw failed; },
  setItem(key: string, value: string): Promise<void> {
    if (!routes[key]) return Promise.reject(new Error(`No database mapping exists for ${key}.`));
    pending++;
    const operation = tail.then(async () => {
      failed = null;
      const previous = cache.get(key) ?? '[]';
      if (previous === value) return;
      const oldRows: Row[] = scalarKeys.has(key) ? [{ id: key, value: key.endsWith('policy') ? previous : JSON.parse(previous) }] : JSON.parse(previous);
      const nextRows: Row[] = scalarKeys.has(key) ? [{ id: key, value: key.endsWith('policy') ? value : JSON.parse(value) }] : JSON.parse(value);
      const old = new Map(oldRows.map(row => [rowId(row), row]));
      const next = new Set(nextRows.map(rowId));
      const upserts = nextRows.filter(row => !old.has(rowId(row)) || comparable(old.get(rowId(row))!) !== comparable(row))
        .map(row => ({ ...row, _version: old.get(rowId(row))?._version ?? 0 }));
      const deletes = key.includes('audit') ? [] : oldRows.filter(row => !next.has(rowId(row))).map(row => ({ id: rowId(row), version: row._version ?? 0 }));
      if (!upserts.length && !deletes.length) return;
      const snapshot = await apiPost<Snapshot>(`${routes[key]}/SaveData`, { collection: key, upserts, deletes });
      installSnapshot(snapshot);
    });
    tail = operation.catch(error => { failed = error instanceof Error ? error : new Error(String(error)); }).finally(() => { pending--; });
    return operation;
  }
};

window.addEventListener('beforeunload', event => { if (pending) { event.preventDefault(); event.returnValue = ''; } });
window.addEventListener('unhandledrejection', event => {
  event.preventDefault();
  const message = event.reason instanceof Error ? event.reason.message : String(event.reason);
  window.alert(`The change was not saved. ${message}\nThe page will reload the saved database records.`);
  window.location.reload();
});
