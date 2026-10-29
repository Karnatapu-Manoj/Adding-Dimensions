import { useEffect, useState, type FormEvent } from 'react';
import './login.css';
import { signIn, verifySignIn, type OtpChallenge } from './auth';
import { apiBase, apiPost, setAccessToken } from './api';

export default function Login() {
  const [showPassword, setShowPassword] = useState(false);
  const [challenge, setChallenge] = useState<OtpChallenge | null>(null);
  const [otp, setOtp] = useState('');
  const [busy, setBusy] = useState(false);
  const [resetMode, setResetMode] = useState(false);
  const [newPassword, setNewPassword] = useState('');
  const [message, setMessage] = useState((window as Window & { portalInitError?: string }).portalInitError ?? '');
  const [slide, setSlide] = useState(0);
  const slides = [
    { eyebrow: 'TRAINING PROGRESS', title: 'Empowering Teachers, Transforming Classrooms', text: 'One connected platform to plan training, build teaching skills, track progress, and recognize achievements through certification.' },
    { eyebrow: 'CLASSROOM PRACTICE', title: 'Every Training Session Builds a Better Tomorrow', text: 'From training plans to classroom implementation, assessments, and certification—supporting every step of a teacher\'s professional growth' },
    { eyebrow: 'YOUR IMPACT', title: 'Learn. Practice. Grow. Inspire.', text: 'A unified training experience that helps teachers develop digital skills, strengthen classroom practices, and achieve measurable learning outcomes' },
  ];
  useEffect(() => {
    const timer = window.setInterval(() => setSlide(current => (current + 1) % slides.length), 30_000);
    return () => window.clearInterval(timer);
  }, [slides.length]);
  const active = slides[slide];
  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const formData = new FormData(event.currentTarget);
    const identity = String(formData.get('identity') ?? '').trim();
    const password = String(formData.get('password') ?? '');
    setBusy(true); setMessage('');
    try {
    if (resetMode) {
      if (!challenge) {
        const next = await apiPost<OtpChallenge>('Account/RequestPasswordReset', { userName: identity });
        setChallenge(next); setMessage(next.message);
      } else {
        const result = await apiPost<{ message: string }>('Account/ResetPassword', { challengeId: challenge.challengeId, otp, newPassword });
        setAccessToken(null); localStorage.removeItem('teacher-training-session');
        setResetMode(false); setChallenge(null); setOtp(''); setNewPassword(''); setMessage(result.message);
      }
      return;
    }
    if (challenge) {
      await verifySignIn(challenge.challengeId, otp);
      window.location.assign(import.meta.env.BASE_URL);
      return;
    }
    const next = await signIn(identity, password);
    setChallenge(next); setMessage(next.message);
    } catch (error) { setMessage(error instanceof Error ? error.message : 'Could not connect to the local API.'); }
    finally { setBusy(false); }
  }

  return <main className="login-page">
    <section className="login-story" aria-label="About the learning platform">
      <div className="story-orbit orbit-one" /><div className="story-orbit orbit-two" />
      <img className="learning-art" src="/TeacherTraining/assets/empowering-education-learning-cards.png" alt="Learning cards: Empowering Teachers, Transforming Classrooms; Every Training Session Builds a Better Tomorrow; Learn. Practice. Grow. Inspire." />
      <div className="story-copy"><h1>{active.title}</h1><p>{active.text}</p>
        <div className="story-dots" aria-label="Choose a story slide">{slides.map((item, index) => <button key={item.eyebrow} type="button" aria-label={`Show slide ${index + 1}`} aria-pressed={slide === index} onClick={() => setSlide(index)} />)}</div>
      </div>
      <img className="adding-dimensions" src="/TeacherTraining/assets/AddingDimensions.png" alt="Adding Dimensions — Enhancing Teaching for Tomorrow" />
    </section>
    <section className="login-panel">
      <div className="login-content">
        <img className="ernet-logo" src="/TeacherTraining/assets/ernet-client-logo.jpeg" alt="ERNet India — Education & Research Network" />
        <h2>{resetMode ? 'Reset password' : 'Sign in'}</h2><p className="login-intro">{resetMode ? 'Verify your account to set a new password.' : 'Welcome back. Enter your details to continue.'}</p>
        <form onSubmit={submit}>
          <label htmlFor="login-identity">Email address or mobile number <span>*</span></label>
          <div className="login-input-wrap"><input id="login-identity" name="identity" type="text" placeholder="you@example.com" autoComplete="username" defaultValue="Demo1" required /><svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="9"/><circle cx="12" cy="9" r="3"/><path d="M5.7 18c1.4-2.6 3.5-3.9 6.3-3.9s4.9 1.3 6.3 3.9"/></svg></div>
          {!resetMode && <><div className="password-label"><label htmlFor="login-password">Password <span>*</span></label><button type="button" onClick={() => { setResetMode(true); setChallenge(null); setOtp(''); setMessage('Enter your account ID, registered email or mobile number.'); }}>Forgot password?</button></div>
          <div className="login-input-wrap"><input id="login-password" name="password" type={showPassword ? 'text' : 'password'} placeholder="Enter your password" autoComplete="current-password" defaultValue="demo1@123" required /><button className="password-toggle" type="button" aria-label={showPassword ? 'Hide password' : 'Show password'} onClick={() => setShowPassword(!showPassword)}><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M2.5 12s3.2-6 9.5-6 9.5 6 9.5 6-3.2 6-9.5 6-9.5-6-9.5-6Z"/><circle cx="12" cy="12" r="2.7"/></svg></button></div></>}
          {resetMode && challenge && <><label htmlFor="new-password">New password <span>*</span></label><div className="login-input-wrap"><input id="new-password" type="password" autoComplete="new-password" minLength={10} maxLength={128} required value={newPassword} onChange={event => setNewPassword(event.target.value)} /></div></>}
          {challenge && <><label htmlFor="login-otp">Verification code <span>*</span></label>
            <div className="login-input-wrap"><input id="login-otp" name="otp" inputMode="numeric" autoComplete="one-time-code" pattern="[0-9]{6}" maxLength={6} required value={otp} onChange={event => setOtp(event.target.value.replace(/\D/g, ''))} autoFocus /></div>
            {challenge.outboxPath && <p><a href={`${apiBase}${challenge.outboxPath}`} target="_blank" rel="noopener noreferrer">Open local email outbox</a></p>}
            <button type="button" disabled={busy} onClick={() => { setChallenge(null); setOtp(''); setMessage('Sign in again to request a new code.'); }}>Use a different account / request a new code</button></>}
          <button className="login-submit" type="submit" disabled={busy}>{busy ? 'Please wait…' : challenge ? (resetMode ? 'Verify and reset password' : 'Verify and sign in') : (resetMode ? 'Send reset code' : 'Sign in')}</button>
          {resetMode && <button type="button" disabled={busy} onClick={() => { setResetMode(false); setChallenge(null); setOtp(''); setMessage(''); }}>Back to sign in</button>}
          {message && <p className="login-message" role="status">{message}</p>}
        </form>
        <p className="register-prompt">Click here to register. <a href={`${import.meta.env.BASE_URL}register`}>Open Registration</a><br /><a href={`${import.meta.env.BASE_URL}recover-trainee`}>Forgot your Trainee ID? Recover it with OTP</a></p>
      </div>
      <footer className="login-footer"><nav><a href="#privacy">Privacy policy</a><a href="#consent">Consent form</a></nav><span>© 2026 Schoolnet India Limited</span></footer>
    </section>
  </main>;
}
