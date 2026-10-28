CREATE OR REPLACE PROCEDURE public.usp_portal_public_data(INOUT p_result jsonb DEFAULT NULL)
LANGUAGE plpgsql AS $procedure$
DECLARE snapshot jsonb;
BEGIN
    snapshot:=jsonb_build_object('teacher-training-batch-plan-uses',
        (SELECT COALESCE(jsonb_agg(ui_data-'_contacts'),'[]') FROM public.training_batch WHERE NOT portal_deleted),
        'teacher-training-schools',(SELECT COALESCE(jsonb_agg(ui_data),'[]') FROM public.m_school WHERE NOT portal_deleted),
        'teacher-training-plans',(SELECT COALESCE(jsonb_agg(jsonb_build_object('id',external_id,'code',plan_code,'name',plan_name)),'[]') FROM public.training_plan WHERE NOT portal_deleted));
    p_result:=jsonb_build_array(jsonb_build_object('payload',snapshot::text));
END;
$procedure$;

CREATE OR REPLACE PROCEDURE public.usp_portal_public_register(IN p_batch_code varchar,IN p_person jsonb,
    IN p_password_hash varchar,INOUT p_result jsonb DEFAULT NULL)
LANGUAGE plpgsql AS $procedure$
DECLARE batch_row public.training_batch; person_row public.trainee; email_person bigint; phone_person bigint;
    registration_id text; person_id bigint; reg_id bigint; person_external text; local_today date; created_account boolean:=false;
BEGIN
    SELECT * INTO batch_row FROM public.training_batch WHERE NOT portal_deleted AND
        (external_id=p_batch_code OR lower(batch_code)=lower(p_batch_code)) FOR UPDATE;
    IF NOT FOUND OR NOT batch_row.open_registration OR batch_row.is_closed OR
        COALESCE(batch_row.ui_data->>'status','') IN ('Cancelled','Archived','Completed') THEN
        RAISE EXCEPTION 'This batch is not accepting registrations.' USING ERRCODE='22023';
    END IF;
    local_today:=(now() AT TIME ZONE 'Asia/Kolkata')::date;
    IF local_today<batch_row.start_date-COALESCE((batch_row.ui_data->>'registrationWindowBeforeDays')::integer,0) OR
        local_today>batch_row.start_date+COALESCE((batch_row.ui_data->>'registrationWindowAfterDays')::integer,0) THEN
        RAISE EXCEPTION 'The registration window is closed.' USING ERRCODE='22023';
    END IF;
    IF (SELECT count(*) FROM public.batch_enrollment WHERE batch_id=batch_row.batch_id AND NOT portal_deleted AND approval_status<>'REJECTED')>=batch_row.capacity THEN
        RAISE EXCEPTION 'This batch has reached its registration capacity.' USING ERRCODE='22023';
    END IF;
    SELECT trainee_id INTO email_person FROM public.trainee WHERE email_hash=p_person->>'emailHash' AND NOT is_erased;
    SELECT trainee_id INTO phone_person FROM public.trainee WHERE mobile_hash=p_person->>'phoneHash' AND NOT is_erased;
    IF email_person IS NULL AND phone_person IS NOT NULL AND p_person->>'emailHash' IS NOT NULL THEN
        RAISE EXCEPTION 'Use the email registered to your trainee record, or verify with your registered mobile number only.' USING ERRCODE='22023';
    END IF;
    IF email_person IS NOT NULL AND phone_person IS NOT NULL AND email_person<>phone_person THEN
        RAISE EXCEPTION 'The contact details match different trainee records. Contact an administrator.' USING ERRCODE='22023';
    END IF;
    person_id:=COALESCE(email_person,phone_person);
    IF person_id IS NULL THEN
        created_account:=true;
        person_external:=p_person->>'id';
        INSERT INTO public.trainee(trainee_code,full_name,email_hash,mobile_hash,email_enc,mobile_enc,email_mask,mobile_mask,
            external_id,ui_data,portal_collection,portal_project_id)
        VALUES(person_external,p_person->>'name',p_person->>'emailHash',p_person->>'phoneHash',
            decode(p_person->>'emailHex','hex'),decode(p_person->>'phoneHex','hex'),p_person->>'emailMask',p_person->>'phoneMask',
            person_external,p_person->'data','teacher-training-trainees',batch_row.project_id) RETURNING trainee_id INTO person_id;
    ELSE
        SELECT external_id INTO person_external FROM public.trainee WHERE trainee_id=person_id;
    END IF;
    -- Imported people may already exist without an application account.
    IF NOT EXISTS(SELECT 1 FROM public.app_user WHERE trainee_id=person_id) THEN
        created_account:=true;
        INSERT INTO public.app_user(login_id,full_name,role_id,password_hash,must_change_password,trainee_id,external_id,ui_data,portal_collection)
        SELECT t.trainee_code,t.full_name,r.role_id,p_password_hash,true,person_id,
            'ACCOUNT-'||md5(person_id::text),jsonb_build_object('id',t.trainee_code,'userId',t.trainee_code,'role','trainee','active',true),'teacher-training-users'
        FROM public.m_role r CROSS JOIN public.trainee t WHERE r.role_code='trainee' AND t.trainee_id=person_id;
        UPDATE public.trainee SET portal_owner_user_id=(SELECT user_id FROM public.app_user WHERE trainee_id=person_id),
            ui_data=ui_data||jsonb_build_object('userId',(SELECT login_id FROM public.app_user WHERE trainee_id=person_id)) WHERE trainee_id=person_id;
        UPDATE public.app_user SET portal_owner_user_id=user_id WHERE trainee_id=person_id;
    END IF;
    IF EXISTS(SELECT 1 FROM public.batch_enrollment WHERE batch_id=batch_row.batch_id AND trainee_id=person_id AND NOT portal_deleted) THEN
        RAISE EXCEPTION 'A registration already exists for this trainee and batch.' USING ERRCODE='23505';
    END IF;
    registration_id:='REG-'||md5(random()::text||clock_timestamp()::text);
    INSERT INTO public.batch_enrollment(batch_id,trainee_id,registration_mode,approval_status,external_id,portal_collection,
        portal_project_id,portal_batch_id,portal_owner_user_id,ui_data)
    VALUES(batch_row.batch_id,person_id,'SELF','PENDING',registration_id,'teacher-training-registrations',batch_row.project_id,
        batch_row.batch_id,(SELECT user_id FROM public.app_user WHERE trainee_id=person_id),
        (p_person->'data')||jsonb_build_object('id',registration_id,'traineeId',person_external,'batchId',batch_row.external_id,
            'userId',(SELECT login_id FROM public.app_user WHERE trainee_id=person_id),
            'batchCode',batch_row.batch_code,'projectId',(SELECT external_id FROM public.project WHERE project_id=batch_row.project_id),
            'traineeName',p_person->>'name','status','Pending','registrationStatus','Pending','submittedAt',now()))
    RETURNING enrollment_id INTO reg_id;
    INSERT INTO public.audit_log(action,entity_type,entity_id,project_id,after_json)
    VALUES('SELF_REGISTER','batch_enrollment',reg_id::text,batch_row.project_id,jsonb_build_object('registrationId',registration_id));
    INSERT INTO public.consent_record(trainee_id,purpose,notice_version,channel,given_by)
        VALUES(person_id,'TRAINING_REGISTRATION','1.0','WEB','SELF');
    p_result:=jsonb_build_array(jsonb_build_object('payload',jsonb_build_object('traineeId',person_external,
        'registrationId',registration_id,'newAccount',created_account,'message','Registration request submitted. The trainer or administrator must review it before your place is confirmed.')::text));
END;
$procedure$;

CREATE OR REPLACE PROCEDURE public.usp_portal_request_recovery(IN p_request_id uuid,IN p_contact_hash varchar,
    IN p_otp_hash varchar,INOUT p_result jsonb DEFAULT NULL)
LANGUAGE plpgsql AS $procedure$
DECLARE person_id bigint;
BEGIN
    SELECT trainee_id INTO person_id FROM public.trainee WHERE NOT is_erased AND is_active AND
        (email_hash=p_contact_hash OR mobile_hash=p_contact_hash);
    INSERT INTO public.portal_recovery_request(request_id,trainee_id,otp_hash,expires_at)
    VALUES(p_request_id,person_id,p_otp_hash,now()+interval '5 minutes');
    p_result:=jsonb_build_array(jsonb_build_object('payload',jsonb_build_object('matched',person_id IS NOT NULL)::text));
END;
$procedure$;

CREATE OR REPLACE PROCEDURE public.usp_portal_verify_recovery(IN p_request_id uuid,IN p_otp_hash varchar,
    INOUT p_result jsonb DEFAULT NULL)
LANGUAGE plpgsql AS $procedure$
DECLARE request_row public.portal_recovery_request; identifiers jsonb;
BEGIN
    SELECT * INTO request_row FROM public.portal_recovery_request WHERE request_id=p_request_id FOR UPDATE;
    IF NOT FOUND OR request_row.consumed_at IS NOT NULL OR request_row.expires_at<=now() OR request_row.attempt_count>=3 THEN
        p_result:='[{"payload":"{\"verified\":false}"}]';RETURN;
    END IF;
    UPDATE public.portal_recovery_request SET attempt_count=attempt_count+1 WHERE request_id=p_request_id;
    IF request_row.trainee_id IS NULL OR request_row.otp_hash<>p_otp_hash THEN
        p_result:='[{"payload":"{\"verified\":false}"}]';RETURN;
    END IF;
    UPDATE public.portal_recovery_request SET consumed_at=now() WHERE request_id=p_request_id;
    SELECT jsonb_agg(trainee_code) INTO identifiers FROM public.trainee WHERE trainee_id=request_row.trainee_id;
    p_result:=jsonb_build_array(jsonb_build_object('payload',jsonb_build_object('verified',true,'traineeIds',identifiers)::text));
END;
$procedure$;
