-- Preview validates the mobile code without consuming it. Submit revalidates and
-- atomically consumes the original REGISTRATION challenge before creating records.
CREATE OR REPLACE PROCEDURE public.usp_portal_check_registration_otp(IN p_id uuid,IN p_purpose varchar,
    IN p_otp_hash varchar,INOUT p_result jsonb DEFAULT NULL)
LANGUAGE plpgsql AS $procedure$
DECLARE challenge public.portal_otp_challenge;
BEGIN
    p_result:='[{"payload":"{\"verified\":false}"}]';
    IF p_purpose<>'REGISTRATION' THEN RETURN; END IF;
    SELECT * INTO challenge FROM public.portal_otp_challenge WHERE challenge_id=p_id AND purpose='REGISTRATION' FOR UPDATE;
    IF NOT FOUND OR challenge.consumed_at IS NOT NULL OR challenge.expires_at<=now() OR challenge.attempt_count>=3 THEN RETURN; END IF;
    IF challenge.otp_hash<>p_otp_hash THEN
        UPDATE public.portal_otp_challenge SET attempt_count=attempt_count+1,
            locked_until=CASE WHEN attempt_count+1>=3 THEN now()+interval '15 minutes' ELSE locked_until END WHERE challenge_id=p_id;
        RETURN;
    END IF;
    p_result:=jsonb_build_array(jsonb_build_object('payload',jsonb_build_object('verified',true,
        'protectedPayload',challenge.protected_payload)::text));
END;
$procedure$;

CREATE OR REPLACE PROCEDURE public.usp_portal_standardize_batch_codes()
LANGUAGE plpgsql AS $procedure$
DECLARE item record; code text; aliases jsonb;
BEGIN
    FOR item IN SELECT * FROM public.training_batch WHERE NOT portal_deleted
        AND batch_code !~ '^TTB-[0-9]{4}-[A-F0-9]{20}$' FOR UPDATE LOOP
        code:='TTB-'||COALESCE(to_char(item.start_date,'YYYY'),to_char(now(),'YYYY'))||'-'||upper(substr(md5(item.batch_id::text||clock_timestamp()::text||random()::text),1,20));
        aliases:=COALESCE(item.ui_data->'legacyBatchCodes','[]')||jsonb_build_array(item.batch_code,item.external_id);
        UPDATE public.training_batch SET batch_code=code,ui_data=ui_data||jsonb_build_object('batchCode',code,'legacyBatchCodes',aliases)
        WHERE batch_id=item.batch_id;
    END LOOP;
END;
$procedure$;
CALL public.usp_portal_standardize_batch_codes();
