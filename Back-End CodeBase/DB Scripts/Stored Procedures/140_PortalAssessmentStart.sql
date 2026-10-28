CREATE OR REPLACE PROCEDURE public.usp_portal_begin_assessment(IN p_user_id bigint,IN p_form_id varchar,IN p_batch_id varchar,
    INOUT p_result jsonb DEFAULT NULL)
LANGUAGE plpgsql AS $procedure$
DECLARE enrollment_key bigint; form_key bigint; limit_count integer; minutes integer; existing_start public.assessment_start;
    form_data jsonb; batch_data jsonb; business_today date:=(now() AT TIME ZONE 'Asia/Kolkata')::date;
BEGIN
    SELECT e.enrollment_id INTO enrollment_key FROM public.batch_enrollment e JOIN public.training_batch b ON b.batch_id=e.batch_id
    JOIN public.app_user u ON u.trainee_id=e.trainee_id WHERE u.user_id=p_user_id AND b.external_id=p_batch_id
    AND e.approval_status='APPROVED' AND NOT e.portal_deleted FOR UPDATE OF e;
    SELECT resource_id,COALESCE((ui_data->>'attemptLimit')::integer,1),COALESCE((ui_data->>'timeLimit')::integer,0)
    INTO form_key,limit_count,minutes FROM public.learning_resource WHERE external_id=p_form_id AND NOT portal_deleted;
    IF enrollment_key IS NULL OR form_key IS NULL THEN RAISE EXCEPTION 'This form or registration is unavailable.' USING ERRCODE='42501'; END IF;
    SELECT ui_data INTO form_data FROM public.learning_resource WHERE resource_id=form_key;
    SELECT ui_data INTO batch_data FROM public.training_batch WHERE external_id=p_batch_id;
    IF COALESCE(form_data->>'planCode','*') NOT IN ('*',batch_data->>'trainingPlanCode') THEN
        RAISE EXCEPTION 'This form is not assigned to the batch plan.' USING ERRCODE='42501';
    END IF;
    IF COALESCE((form_data->>'day')::integer,0)<1 OR
        (form_data->>'day')::integer>jsonb_array_length(COALESCE(batch_data->'trainingDates','[]')) OR
        (batch_data->'trainingDates'->>((form_data->>'day')::integer-1))::date>business_today OR
        NULLIF(form_data->>'availableFrom','')::date>business_today OR
        NULLIF(form_data->>'availableUntil','')::date<business_today THEN
        RAISE EXCEPTION 'This form is outside its availability window.' USING ERRCODE='22023';
    END IF;
    SELECT * INTO existing_start FROM public.assessment_start WHERE user_id=p_user_id AND enrollment_id=enrollment_key
        AND resource_id=form_key AND consumed_at IS NULL AND expires_at>now() ORDER BY started_at DESC LIMIT 1;
    IF NOT FOUND THEN
        IF (SELECT count(*) FROM public.assessment_start WHERE enrollment_id=enrollment_key AND resource_id=form_key)>=limit_count THEN
            RAISE EXCEPTION 'The attempt limit has been reached.' USING ERRCODE='22023';
        END IF;
        INSERT INTO public.assessment_start(user_id,enrollment_id,resource_id,expires_at)
        VALUES(p_user_id,enrollment_key,form_key,now()+make_interval(mins=>CASE WHEN minutes>0 THEN minutes ELSE 1440 END))
        RETURNING * INTO existing_start;
    END IF;
    p_result:=jsonb_build_array(jsonb_build_object('payload',jsonb_build_object('attemptToken',existing_start.start_id,
        'startedAt',existing_start.started_at,'expiresAt',existing_start.expires_at)::text));
END;
$procedure$;
