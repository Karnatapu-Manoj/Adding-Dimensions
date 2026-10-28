-- Source: design thinking Db and partition.xlsx / Data Dictionary
CREATE TABLE IF NOT EXISTS public.consent_record
(
    consent_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    trainee_id BIGINT NOT NULL,
    purpose VARCHAR(30) NOT NULL,
    notice_version VARCHAR(20) NOT NULL,
    channel VARCHAR(10) NOT NULL,
    given_by VARCHAR(10) DEFAULT 'SELF' NOT NULL,
    guardian_verified_at TIMESTAMPTZ,
    consented_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    consent_ip VARCHAR(45),
    withdrawn_at TIMESTAMPTZ
);
