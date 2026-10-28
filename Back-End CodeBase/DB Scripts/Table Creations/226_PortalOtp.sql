CREATE TABLE IF NOT EXISTS public.portal_otp_challenge (
    challenge_id uuid PRIMARY KEY,
    purpose varchar(20) NOT NULL CONSTRAINT portal_otp_purpose_check CHECK (purpose IN ('LOGIN','REGISTRATION','RECOVERY','PASSWORD_RESET')),
    user_id bigint REFERENCES public.app_user(user_id),
    recipient_hash varchar(64) NOT NULL,
    otp_hash varchar(64) NOT NULL,
    protected_payload jsonb NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    expires_at timestamptz NOT NULL,
    attempt_count integer NOT NULL DEFAULT 0,
    locked_until timestamptz,
    consumed_at timestamptz
);
CREATE INDEX IF NOT EXISTS ix_portal_otp_recipient ON public.portal_otp_challenge(recipient_hash,created_at);

ALTER TABLE public.portal_otp_challenge ADD COLUMN IF NOT EXISTS locked_until timestamptz;
ALTER TABLE public.portal_otp_challenge DROP CONSTRAINT IF EXISTS portal_otp_challenge_purpose_check;
ALTER TABLE public.portal_otp_challenge DROP CONSTRAINT IF EXISTS portal_otp_purpose_check;
ALTER TABLE public.portal_otp_challenge ADD CONSTRAINT portal_otp_purpose_check CHECK (purpose IN ('LOGIN','REGISTRATION','RECOVERY','PASSWORD_RESET'));
