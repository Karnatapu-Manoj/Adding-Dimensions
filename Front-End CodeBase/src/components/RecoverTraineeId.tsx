import { apiBase, apiPost } from '../api';
import { useState, type FormEvent } from 'react';
import { Alert, Box, Button, Card, CardContent, Container, Stack, TextField, Typography } from '@mui/material';
import { Footer, Topbar } from './DashboardParts';

const base = import.meta.env.BASE_URL;

export default function RecoverTraineeId() {
  const [contact, setContact] = useState('');
  const [otp, setOtp] = useState('');
  const [requestId, setRequestId] = useState('');
  const [outboxPath, setOutboxPath] = useState('');
  const [traineeId, setTraineeId] = useState('');
  const [message, setMessage] = useState('');
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);

  async function requestCode(event: FormEvent<HTMLFormElement>) {
    event.preventDefault(); setError(''); setMessage(''); setTraineeId('');
    setBusy(true);
    try {
      const payload = await apiPost<{ requestId: string; message: string; outboxPath: string }>('Public/RequestRecovery', { contact: contact.trim() });
      setRequestId(String(payload.requestId)); setOutboxPath(payload.outboxPath);
      setMessage(payload.message);
    } catch (reason) { setError(reason instanceof Error ? reason.message : 'Could not start verification. Try again later.'); }
    finally { setBusy(false); }
  }

  async function verifyCode(event: FormEvent<HTMLFormElement>) {
    event.preventDefault(); setError(''); setMessage(''); setTraineeId('');
    if (!requestId) return;
    setBusy(true);
    try {
      const payload = await apiPost<{ verified: boolean; traineeIds: string[] }>('Public/VerifyRecovery', { requestId, otp: otp.trim() });
      setTraineeId(String(payload.traineeIds[0])); setOtp('');
    } catch (reason) { setError(reason instanceof Error ? reason.message : 'The code could not be verified.'); }
    finally { setBusy(false); }
  }

  return <Box sx={{ minHeight: '100vh', bgcolor: '#f4f7fb', display: 'flex', flexDirection: 'column' }}><Box sx={{ px: { xs: 2, md: 4 } }}><Topbar title="Recover Trainee ID" logoSrc={`${base}assets/AddingDimensions.png`} /></Box><Box sx={{ flex: 1, py: { xs: 3, md: 6 } }}><Container maxWidth="sm"><Card elevation={0} sx={{ border: '1px solid #e2eaf2', borderRadius: 3 }}><CardContent sx={{ p: { xs: 2.5, md: 4 } }}><Typography variant="h4" fontWeight={800} color="#173553">Recover your Trainee ID</Typography><Typography color="text.secondary" sx={{ mt: .75, mb: 3 }}>Verify an email address or mobile number already associated with your trainee record.</Typography>
    {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}{message && <Alert severity="info" sx={{ mb: 2 }}>{message}</Alert>}{traineeId && <Alert severity="success" sx={{ mb: 2 }}>Your Trainee ID is <strong>{traineeId}</strong>. Keep it for future training registrations.</Alert>}
    {!requestId ? <Box component="form" onSubmit={requestCode}><Stack spacing={2}><TextField fullWidth required label="Email address or mobile number" value={contact} onChange={event => setContact(event.target.value)} autoComplete="email tel" /><Button type="submit" variant="contained" disabled={busy}>Send verification code</Button></Stack></Box> : !traineeId && <Box component="form" onSubmit={verifyCode}><Stack spacing={2}><TextField fullWidth required label="One-time verification code" value={otp} onChange={event => setOtp(event.target.value)} inputProps={{ inputMode: 'numeric', autoComplete: 'one-time-code' }} /><Button href={`${apiBase}${outboxPath}`} target="_blank" rel="noopener noreferrer">Open local email outbox</Button><Button type="submit" variant="contained" disabled={busy}>Verify and retrieve ID</Button><Button type="button" onClick={() => { setRequestId(''); setOtp(''); setMessage(''); }} disabled={busy}>Use a different contact</Button></Stack></Box>}
    {traineeId && <Stack direction={{ xs: 'column', sm: 'row' }} spacing={1} sx={{ mt: 2 }}><Button href={`${base}register`} variant="contained">Continue to registration</Button><Button href={`${base}login`}>Login</Button></Stack>}
    <Typography variant="caption" display="block" color="text.secondary" sx={{ mt: 3 }}>Your ID is shown only after the verification service confirms the one-time code. If you no longer have access to the registered contact, ask an authorized administrator to verify your identity.</Typography>
  </CardContent></Card></Container></Box><Footer /></Box>;
}
