import './styles.css';
import './content-library.css';
import './reports/reports.css';
import './theme.css';
import './holiday-master.css';
import './projects.css';
import React from 'react';
import { createRoot } from 'react-dom/client';
import DashboardApp from './App';
import { hydrateData } from './dataStore';
import { setAccessToken } from './api';

try { document.documentElement.dataset.theme = window.localStorage.getItem('teacher-training-theme') === 'dark' ? 'dark' : 'light'; } catch { document.documentElement.dataset.theme = 'light'; }
async function start() {
  try {
    const snapshot = await hydrateData();
    const current = snapshot?._current as { userId: string; role: string } | undefined;
    if (current) localStorage.setItem('teacher-training-session', JSON.stringify({ userId: current.userId, role: current.role }));
  } catch (error) {
    setAccessToken(null);
    (window as Window & { portalInitError?: string }).portalInitError = error instanceof Error ? error.message : 'Could not connect to the local API.';
  }
  createRoot(document.getElementById('root')!).render(<DashboardApp />);
}
void start();
