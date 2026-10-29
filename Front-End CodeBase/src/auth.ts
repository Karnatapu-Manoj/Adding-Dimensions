import { accessToken, apiPost, setAccessToken } from './api';
import { dataStore, hydrateData } from './dataStore';
export type UserRole =
  | 'sponsor-admin'
  | 'schoolnet-super-admin'
  | 'schoolnet-project-admin'
  | 'state-admin'
  | 'school-admin'
  | 'trainer'
  | 'trainee'
  | 'reporting-audit-user';

export type MenuKey =
  | 'dashboard'
  | 'projects'
  | 'training-plans'
  | 'batches'
  | 'attendance'
  | 'content-library'
  | 'assessments'
  | 'assessment-feedback'
  | 'certificates'
  | 'mis-reports'
  | 'holiday-master'
  | 'trainer-repository';

export type UserRecord = { userId: string; role: UserRole; active: boolean };
export type SessionUser = Pick<UserRecord, 'userId' | 'role'>;

export const DEMO_PASSWORD = 'demo1@123';
export const ROLE_LABELS: Record<UserRole, string> = {
  'sponsor-admin': 'Sponsor Admin',
  'schoolnet-super-admin': 'Schoolnet Super Admin',
  'schoolnet-project-admin': 'Schoolnet Project Admin',
  'state-admin': 'State Admin',
  'school-admin': 'School Admin',
  trainer: 'Trainer',
  trainee: 'Trainee',
  'reporting-audit-user': 'Reporting/Audit User',
};

export const ROLES = Object.keys(ROLE_LABELS) as UserRole[];

const ROLE_MENUS: Record<UserRole, readonly MenuKey[]> = {
  'sponsor-admin': ['dashboard', 'projects', 'batches', 'content-library', 'assessment-feedback', 'certificates', 'mis-reports', 'trainer-repository'],
  'schoolnet-super-admin': ['dashboard', 'projects', 'training-plans', 'batches', 'attendance', 'content-library', 'assessment-feedback', 'certificates', 'mis-reports', 'holiday-master', 'trainer-repository'],
  'schoolnet-project-admin': ['dashboard', 'projects', 'training-plans', 'batches', 'attendance', 'content-library', 'assessment-feedback', 'certificates', 'mis-reports', 'trainer-repository'],
  'state-admin': ['dashboard', 'projects', 'training-plans', 'batches', 'attendance', 'assessment-feedback', 'mis-reports', 'trainer-repository'],
  'school-admin': ['dashboard', 'projects', 'training-plans', 'batches', 'attendance', 'content-library', 'assessment-feedback', 'trainer-repository'],
  trainer: ['dashboard', 'projects', 'batches', 'attendance', 'content-library', 'assessment-feedback', 'trainer-repository'],
  trainee: ['dashboard', 'projects', 'content-library', 'assessments', 'assessment-feedback', 'certificates'],
  'reporting-audit-user': ['dashboard', 'projects', 'mis-reports'],
};

export function canAccessMenu(role: UserRole, menu: MenuKey) {
  return ROLE_MENUS[role].includes(menu);
}

export function canAccessRoute(role: UserRole, path: string) {
  if (path === '/certificates') return ['sponsor-admin', 'schoolnet-super-admin', 'schoolnet-project-admin', 'trainee'].includes(role);
  if (path === '/assessments') return canAccessMenu(role, 'assessment-feedback');
  if (path === '/trainers') return canAccessMenu(role, 'trainer-repository');
  if (path === '/registration-requests') return ['schoolnet-super-admin', 'schoolnet-project-admin', 'state-admin', 'school-admin', 'trainer'].includes(role);
  if (!path || path === '/') return canAccessMenu(role, 'dashboard');
  if (path === '/holiday-master') return canAccessMenu(role, 'holiday-master');
  if (path === '/content-library') return canAccessMenu(role, 'content-library');
  if (path === '/projects') return canAccessMenu(role, 'projects');
  if (path === '/training-plans') return canAccessMenu(role, 'training-plans');
  if (path === '/batches') return canAccessMenu(role, 'batches');
  if (path === '/attendance') return canAccessMenu(role, 'attendance');
  if (path.startsWith('/reports/')) return canAccessMenu(role, 'mis-reports');
  return canAccessMenu(role, 'dashboard');
}

const USERS_KEY = 'teacher-training-users';
const SESSION_KEY = 'teacher-training-session';

export function getUsers(): UserRecord[] {
  try { return JSON.parse(dataStore.getItem(USERS_KEY) ?? '[]') as UserRecord[]; }
  catch { return []; }
}
export async function saveUsers(users: UserRecord[]) { await dataStore.setItem(USERS_KEY, JSON.stringify(users)); }
export function getSession(): SessionUser | null {
  try {
    const token = accessToken();
    if (!token) return null;
    const payload = JSON.parse(atob(token.split('.')[1].replaceAll('-', '+').replaceAll('_', '/'))) as { exp: number };
    if (payload.exp * 1000 <= Date.now()) { setAccessToken(null); return null; }
    return JSON.parse(localStorage.getItem(SESSION_KEY) ?? 'null') as SessionUser | null;
  } catch { return null; }
}
export type OtpChallenge = { challengeId: string; expiresAt: string; message: string; outboxPath: string; requiresOtp: boolean };
export async function signIn(userId: string, password: string): Promise<OtpChallenge> {
  return apiPost<OtpChallenge>('Account/Login', { userName: userId.trim(), password });
}
export async function verifySignIn(challengeId: string, otp: string): Promise<SessionUser> {
  const response = await apiPost<{ user: SessionUser; jwtToken: string }>('Account/VerifyLogin', { challengeId, otp });
  setAccessToken(response.jwtToken);
  const session = { userId: response.user.userId, role: response.user.role };
  localStorage.setItem(SESSION_KEY, JSON.stringify(session));
  await hydrateData();
  return session;
}
export async function signOut() {
  try { await dataStore.flush(); await apiPost('Account/Logout'); }
  finally { setAccessToken(null); localStorage.removeItem(SESSION_KEY); dataStore.clear(); }
}
