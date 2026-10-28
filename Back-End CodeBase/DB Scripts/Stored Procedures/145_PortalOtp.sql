CREATE OR REPLACE PROCEDURE public.usp_portal_create_otp(IN p_id uuid, IN p_purpose varchar,
    IN p_user_id bigint, IN p_recipient_hash varchar, IN p_otp_hash varchar, IN p_payload jsonb,
    INOUT p_result jsonb DEFAULT NULL)
LANGUAGE plpgsql AS $procedure$
BEGIN
    -- Serialize requests for the same recipient, including requests from different application instances.
    PERFORM pg_advisory_xact_lock(hashtextextended(p_recipient_hash,0));
    IF EXISTS (SELECT 1 FROM public.portal_otp_challenge WHERE recipient_hash=p_recipient_hash AND locked_until>now()) THEN
        RAISE EXCEPTION 'Verification is locked for 15 minutes after three incorrect codes.' USING ERRCODE='22023';
    END IF;
    IF (SELECT count(*) FROM public.portal_otp_challenge WHERE recipient_hash=p_recipient_hash
        AND created_at>now()-interval '15 minutes' AND (consumed_at IS NULL OR attempt_count=0))>=10 THEN
        RAISE EXCEPTION 'Too many verification requests. Please try again in 15 minutes.' USING ERRCODE='22023';
    END IF;
    UPDATE public.portal_otp_challenge SET consumed_at=now()
        WHERE recipient_hash=p_recipient_hash AND purpose=p_purpose AND consumed_at IS NULL;
    INSERT INTO public.portal_otp_challenge(challenge_id,purpose,user_id,recipient_hash,otp_hash,protected_payload,expires_at)
        VALUES(p_id,p_purpose,p_user_id,p_recipient_hash,p_otp_hash,p_payload,now()+interval '5 minutes');
    p_result:=jsonb_build_array(jsonb_build_object('payload',jsonb_build_object('challengeId',p_id,
        'expiresAt',now()+interval '5 minutes')::text));
END;
$procedure$;

CREATE OR REPLACE PROCEDURE public.usp_portal_verify_otp(IN p_id uuid,IN p_purpose varchar,
    IN p_otp_hash varchar,INOUT p_result jsonb DEFAULT NULL)
LANGUAGE plpgsql AS $procedure$
DECLARE challenge public.portal_otp_challenge; user_record public.app_user; role_code text;
BEGIN
    p_result:='[{"payload":"{\"verified\":false}"}]';
    SELECT * INTO challenge FROM public.portal_otp_challenge WHERE challenge_id=p_id AND purpose=p_purpose FOR UPDATE;
    IF NOT FOUND OR challenge.consumed_at IS NOT NULL OR challenge.expires_at<=now() OR challenge.attempt_count>=3 THEN RETURN; END IF;
    UPDATE public.portal_otp_challenge SET attempt_count=attempt_count+1,
        locked_until=CASE WHEN attempt_count+1>=3 AND otp_hash<>p_otp_hash THEN now()+interval '15 minutes' ELSE locked_until END WHERE challenge_id=p_id;
    IF challenge.otp_hash<>p_otp_hash THEN RETURN; END IF;
    IF p_purpose='LOGIN' THEN
        SELECT * INTO user_record FROM public.app_user WHERE user_id=challenge.user_id AND is_active AND NOT portal_deleted;
        IF NOT FOUND OR user_record.locked_until>now() THEN RETURN; END IF;
        SELECT r.role_code INTO role_code FROM public.m_role r WHERE r.role_id=user_record.role_id AND r.is_active;
        IF role_code IS NULL THEN RETURN; END IF;
    END IF;
    UPDATE public.portal_otp_challenge SET consumed_at=now() WHERE challenge_id=p_id;
    INSERT INTO public.user_activity_log(user_id,activity_type,result)
        VALUES(challenge.user_id,'OTP_VERIFY','SUCCESS');
    p_result:=jsonb_build_array(jsonb_build_object('payload',jsonb_build_object('verified',true,
        'protectedPayload',challenge.protected_payload,'userId',challenge.user_id,
        'loginId',user_record.login_id,'role',role_code)::text));
END;
$procedure$;
