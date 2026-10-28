CREATE TABLE IF NOT EXISTS public.portal_recovery_request (
    request_id uuid PRIMARY KEY,
    trainee_id bigint REFERENCES public.trainee(trainee_id),
    otp_hash varchar(64) NOT NULL,
    expires_at timestamptz NOT NULL,
    attempt_count integer NOT NULL DEFAULT 0,
    consumed_at timestamptz
);
CREATE UNIQUE INDEX IF NOT EXISTS ux_trainee_email_hash ON public.trainee(email_hash) WHERE email_hash IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS ux_trainee_mobile_hash ON public.trainee(mobile_hash) WHERE mobile_hash IS NOT NULL;
