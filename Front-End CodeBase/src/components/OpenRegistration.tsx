import { apiBase, apiPost } from '../api';
import { dataStore } from '../dataStore';
import { useMemo, useState, type FormEvent } from 'react';
import { Alert, Box, Button, Card, CardContent, Checkbox, Chip, Container, FormControlLabel, MenuItem, Stack, TextField, Typography } from '@mui/material';
import { Footer, Topbar } from './DashboardParts';
import { formatDate } from '../dateFormat';
import { businessDateToday, registrationWindow, registrationWindowError } from '../registrationRules';

type Row = Record<string, any>;
type Batch = Row & { id: string; batchCode?: string; name?: string; openRegistration?: boolean; trainingDates?: string[]; trainingStartDate?: string; trainingEndAuto?: string; trainingPlanName?: string };
const BATCHES = 'teacher-training-batch-plan-uses';
const REGISTRATIONS = 'teacher-training-registrations';
const TRAINEES = 'teacher-training-trainees';
const read = <T,>(key: string): T[] => { try { const parsed = JSON.parse(dataStore.getItem(key) || '[]'); return Array.isArray(parsed) ? parsed : []; } catch { return []; } };
const clean = (value: unknown) => String(value ?? '').trim();
const normalizedName = (value: unknown) => clean(value).normalize('NFKD').replace(/[\u0300-\u036f]/g, '').toLowerCase().replace(/[^a-z0-9]/g, '');
const normalizedPhone = (value: unknown) => clean(value).replace(/\D/g, '');
const active = (row: Row) => !['rejected', 'cancelled', 'withdrawn'].includes(clean(row.status ?? row.registrationStatus).toLowerCase());
const base = import.meta.env.BASE_URL;

export default function OpenRegistration() {
  const batches = useMemo(() => read<Batch>(BATCHES), []);
  const [batchRef, setBatchRef] = useState(() => new URLSearchParams(location.search).get('batch') ?? new URLSearchParams(location.search).get('code') ?? '');
  const batch = batches.find(item => [item.id, item.batchCode, item.uniqueId].some(value => clean(value).toLowerCase() === batchRef.trim().toLowerCase()));
  const registrations = read<Row>(REGISTRATIONS);
  const cap = Number(batch?.registrationCapacity ?? batch?.participantCapacity ?? batch?.capacity);
  const occupied = batch ? registrations.filter(row => (clean(row.batchId) === batch.id || clean(row.batchCode).toLowerCase() === clean(batch.batchCode).toLowerCase()) && active(row)).length : 0;
  const window = batch ? registrationWindow(batch) : undefined;
  const closedReason = !batch ? '' : registrationWindowError(batch) || (Number.isFinite(cap) && cap > 0 && occupied >= cap ? 'This batch has reached its registration capacity.' : '');
  const [notice, setNotice] = useState('');
  const [error, setError] = useState('');
  const [challenge, setChallenge] = useState<{ challengeId: string; outboxPath: string } | null>(null);
  const [otp, setOtp] = useState('');
  const [busy, setBusy] = useState(false);
  const [accountMailPath, setAccountMailPath] = useState('');

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault(); setNotice(''); setError('');
    if (!batch || closedReason) { setError(closedReason || 'Enter a valid batch code.'); return; }
    const form = new FormData(event.currentTarget);
    const name = clean(form.get('name')), email = clean(form.get('email')).toLowerCase(), phone = clean(form.get('phone'));
    if (!name || (!email && !phone)) { setError('Enter your name and at least an email address or mobile number.'); return; }
    setBusy(true);
    try {
      const next = await apiPost<{ challengeId: string; outboxPath: string; message: string }>('Public/RequestRegistration', {
        batchCode: batch.batchCode || batch.id, name, email, phone, category: clean(form.get('category')), consentProvided: form.get('consent') === 'on'
      });
      setChallenge(next); setNotice(next.message); setOtp('');
    } catch (reason) { setError(reason instanceof Error ? reason.message : 'Could not request a code.'); }
    finally { setBusy(false); }
  }

  async function verify(event: FormEvent<HTMLFormElement>) {
    event.preventDefault(); if (!challenge) return;
    setBusy(true); setError('');
    try {
      const result = await apiPost<{ traineeId: string; message: string; accountMailPath?: string }>('Public/Register', {
        challengeId: challenge.challengeId, otp
      });
      setNotice(`${result.message} Your Trainee ID is ${result.traineeId}.`);
      setAccountMailPath(result.accountMailPath || ''); setChallenge(null); setOtp('');
    } catch (reason) { setError(reason instanceof Error ? reason.message : 'Registration could not be saved.'); }
    finally { setBusy(false); }
  }

  return <Box sx={{ minHeight: '100vh', bgcolor: '#f4f7fb', display: 'flex', flexDirection: 'column' }}><Box sx={{ width: '100%', px: { xs: 2, md: 4 }, bgcolor: '#f4f7fb' }}><Topbar title="Adding Dimensions — Enhancing Teaching for Tomorrow" logoSrc={`${base}assets/AddingDimensions.png`} /></Box><Box sx={{ flex: 1, py: { xs: 3, md: 6 } }}><Container maxWidth="sm"><Stack spacing={2.5}>
    <Stack direction="row" justifyContent="flex-end" alignItems="center"><Button href={`${base}login`} sx={{ textTransform: 'none' }}>Login</Button></Stack>
    <Card elevation={0} sx={{ border: '1px solid #e2eaf2', borderRadius: 3 }}><CardContent sx={{ p: { xs: 2.5, md: 4 } }}>
      <Typography variant="h4" fontWeight={800} color="#173553">Open registration</Typography><Typography color="text.secondary" sx={{ mt: .5, mb: 3 }}>Enter a batch code to view details and request a place.</Typography>
      <TextField fullWidth label="Batch code" value={batchRef} onChange={event => { setBatchRef(event.target.value); setNotice(''); setError(''); setChallenge(null); setAccountMailPath(''); }} placeholder="Enter the shared batch code" />
      {batch && <Card variant="outlined" sx={{ my: 2, bgcolor: '#f8fbff' }}><CardContent><Stack direction="row" justifyContent="space-between" alignItems="center"><Typography variant="h6" fontWeight={750}>{batch.batchCode || batch.name || 'Training batch'}</Typography><Chip size="small" label={closedReason ? 'Closed' : 'Open'} color={closedReason ? 'default' : 'success'} /></Stack><Typography variant="body2" color="text.secondary">{batch.projectName || 'Training project'} · {batch.trainingPlanName || batch.planName || batch.trainingPlanCode || 'Training plan'}</Typography><Typography variant="body2" sx={{ mt: 1 }}>Dates: {(batch.trainingDates ?? [batch.trainingStartDate, batch.trainingEndAuto].filter(Boolean)).map(formatDate).join(', ') || 'To be confirmed'}</Typography><Typography variant="body2">Registration window: {formatDate(window?.opensOn) || "—"} to {formatDate(window?.closesOn) || "—"} · Today {formatDate(businessDateToday())} ({import.meta.env.VITE_BUSINESS_TIME_ZONE?.trim() || "Asia/Kolkata"})</Typography><Typography variant="body2">Venue: {batch.schoolUdiseVenue || batch.venue || 'To be confirmed'} · Trainer: {batch.trainerName || batch.trainerCode || 'To be confirmed'}</Typography>{Number.isFinite(cap) && cap > 0 && <Typography variant="body2" sx={{ mt: .5 }}>Places remaining: {Math.max(0, cap - occupied)}</Typography>}</CardContent></Card>}
      {error && <Alert severity="error" sx={{ my: 2 }}>{error}</Alert>}{notice && <Alert severity="success" sx={{ my: 2 }}>{notice}</Alert>}
      {batch && !closedReason && !challenge && !accountMailPath && <Box component="form" onSubmit={submit}><Stack spacing={2} sx={{ mt: 2 }}><TextField required fullWidth name="name" label="Full name" /><TextField fullWidth name="email" type="email" label="Email address" /><TextField fullWidth name="phone" label="Mobile number" /><TextField select fullWidth name="category" label="Participant category" defaultValue="Teacher"><MenuItem value="Teacher">Teacher</MenuItem><MenuItem value="Student">Student</MenuItem><MenuItem value="Other">Other</MenuItem></TextField><FormControlLabel control={<Checkbox required name="consent" />} label="I consent to using my contact details for training registration and verification." /><Button variant="contained" type="submit" size="large" sx={{ textTransform: 'none' }} disabled={busy}>Request verification code</Button></Stack></Box>}
      {challenge && <Box component="form" onSubmit={verify}><Stack spacing={2} sx={{ mt: 2 }}>
        <TextField required fullWidth label="Verification code" value={otp} onChange={event => setOtp(event.target.value.replace(/\D/g, '').slice(0, 6))} slotProps={{ htmlInput: { inputMode: 'numeric', autoComplete: 'one-time-code', pattern: '[0-9]{6}' } }} />
        <Button href={`${apiBase}${challenge.outboxPath}`} target="_blank" rel="noopener noreferrer">Open local email outbox</Button>
        <Button type="submit" variant="contained" disabled={busy}>Verify and submit registration</Button>
        <Button disabled={busy} onClick={() => { setChallenge(null); setOtp(''); setNotice('Enter your details again to request a new code.'); }}>Change details / request a new code</Button>
      </Stack></Box>}
      {accountMailPath && <Button href={`${apiBase}${accountMailPath}`} target="_blank" rel="noopener noreferrer">View initial login details in local email outbox</Button>}
      {batch && closedReason && <Alert severity="info" sx={{ mt: 2 }}>{closedReason}</Alert>}
      {!batch && batchRef && <Alert severity="warning" sx={{ mt: 2 }}>No batch matches that code. Check the code with the trainer or administrator.</Alert>}
      <Typography variant="caption" color="text.secondary" display="block" sx={{ mt: 3 }}>Submitting a request does not confirm a place. Your trainer or an authorized administrator will review it.</Typography>
    </CardContent></Card>
  </Stack></Container></Box><Footer /></Box>;
}
