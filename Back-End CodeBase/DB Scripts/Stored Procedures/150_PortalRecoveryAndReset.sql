CREATE OR REPLACE PROCEDURE public.usp_portal_recovery_lookup(IN p_contact_hash varchar,INOUT p_result jsonb DEFAULT NULL)
LANGUAGE plpgsql AS $procedure$
BEGIN
    p_result:=jsonb_build_array(jsonb_build_object('payload',jsonb_build_object('traineeIds',
        (SELECT COALESCE(jsonb_agg(trainee_code),'[]') FROM public.trainee WHERE NOT is_erased AND is_active AND
            (email_hash=p_contact_hash OR mobile_hash=p_contact_hash)))::text));
END;
$procedure$;

CREATE OR REPLACE PROCEDURE public.usp_portal_reset_password(IN p_user_id bigint,IN p_password_hash varchar,
    INOUT p_result jsonb DEFAULT NULL)
LANGUAGE plpgsql AS $procedure$
BEGIN
    UPDATE public.app_user SET password_hash=p_password_hash,must_change_password=false,failed_login_count=0,
        locked_until=NULL WHERE user_id=p_user_id AND is_active AND NOT portal_deleted AND login_id !~* '^Demo[1-8]$';
    IF NOT FOUND THEN RAISE EXCEPTION 'The password cannot be reset for this account.' USING ERRCODE='22023'; END IF;
    DELETE FROM public.app_auth_session WHERE user_id=p_user_id;
    UPDATE public.portal_otp_challenge SET consumed_at=now() WHERE user_id=p_user_id AND consumed_at IS NULL;
    INSERT INTO public.user_activity_log(user_id,activity_type,result) VALUES(p_user_id,'PASSWORD_RESET','SUCCESS');
    p_result:='[{"is_success":true}]';
END;
$procedure$;
