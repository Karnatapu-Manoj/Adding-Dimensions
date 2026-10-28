CREATE OR REPLACE FUNCTION public.portal_project_access(p_user_id bigint,p_project_id integer)
RETURNS boolean LANGUAGE sql STABLE AS $function$
    SELECT EXISTS (
        SELECT 1 FROM public.app_user u JOIN public.m_role r ON r.role_id=u.role_id
        WHERE u.user_id=p_user_id AND u.is_active AND r.is_active
        AND (r.data_scope='ALL' OR EXISTS (
            SELECT 1 FROM public.user_access_scope s
            WHERE s.user_id=u.user_id AND s.is_active
            AND (s.project_id IS NULL OR s.project_id=p_project_id)
            AND (s.valid_from IS NULL OR s.valid_from<=CURRENT_DATE)
            AND (s.valid_to IS NULL OR s.valid_to>=CURRENT_DATE)
        ))
        AND (u.stakeholder_id IS NULL OR p_project_id IS NULL OR EXISTS (
            SELECT 1 FROM public.project p WHERE p.project_id=p_project_id AND p.stakeholder_id=u.stakeholder_id
        ))
    );
$function$;

CREATE OR REPLACE FUNCTION public.portal_row_access(p_user_id bigint,p_project_id integer,p_owner_id bigint,p_batch_id bigint)
RETURNS boolean LANGUAGE plpgsql STABLE AS $function$
DECLARE current_user_record public.app_user; actor_role_code text;
BEGIN
    SELECT * INTO current_user_record FROM public.app_user WHERE user_id=p_user_id AND is_active;
    IF NOT FOUND THEN RETURN false; END IF;
    SELECT role_code INTO actor_role_code FROM public.m_role WHERE role_id=current_user_record.role_id AND is_active;
    IF actor_role_code='schoolnet-super-admin' THEN RETURN true; END IF;
    IF actor_role_code='trainee' THEN
        RETURN (p_owner_id IS NULL AND p_batch_id IS NULL AND p_project_id IS NULL) OR p_owner_id=p_user_id OR (p_batch_id IS NOT NULL AND EXISTS (
            SELECT 1 FROM public.batch_enrollment e WHERE e.batch_id=p_batch_id
            AND e.trainee_id=current_user_record.trainee_id AND NOT e.portal_deleted
        )) OR (p_batch_id IS NULL AND p_project_id IS NOT NULL AND EXISTS (
            SELECT 1 FROM public.batch_enrollment e JOIN public.training_batch b ON b.batch_id=e.batch_id
            WHERE e.trainee_id=current_user_record.trainee_id AND b.project_id=p_project_id AND NOT e.portal_deleted
        ));
    END IF;
    IF actor_role_code='trainer' AND p_batch_id IS NOT NULL THEN
        RETURN EXISTS (SELECT 1 FROM public.training_batch b WHERE b.batch_id=p_batch_id
            AND b.trainer_id=current_user_record.trainer_id AND NOT b.portal_deleted);
    END IF;
    IF p_project_id IS NULL THEN RETURN true; END IF;
    IF NOT public.portal_project_access(p_user_id,p_project_id) THEN RETURN false; END IF;
    IF p_batch_id IS NULL THEN RETURN true; END IF;
    RETURN EXISTS (
        SELECT 1 FROM public.training_batch b JOIN public.m_school school ON school.school_id=b.school_id
        JOIN public.user_access_scope s ON s.user_id=p_user_id AND s.is_active
        WHERE b.batch_id=p_batch_id AND (s.project_id IS NULL OR s.project_id=b.project_id)
        AND (s.valid_from IS NULL OR s.valid_from<=CURRENT_DATE) AND (s.valid_to IS NULL OR s.valid_to>=CURRENT_DATE)
        AND (s.state_id IS NULL OR s.state_id=school.state_id)
        AND (s.district_id IS NULL OR s.district_id=school.district_id)
        AND (s.block_id IS NULL OR s.block_id=school.block_id)
        AND (s.cluster_id IS NULL OR s.cluster_id=school.cluster_id)
        AND (s.school_id IS NULL OR s.school_id=school.school_id)
    );
END;
$function$;

DROP PROCEDURE IF EXISTS public.usp_portal_login_lookup(varchar,jsonb);
CREATE OR REPLACE PROCEDURE public.usp_portal_login_lookup(IN p_login_id varchar,IN p_contact_hash varchar,INOUT p_result jsonb DEFAULT NULL)
LANGUAGE plpgsql AS $procedure$
BEGIN
    SELECT COALESCE(jsonb_agg(jsonb_build_object('user_id',u.user_id,'login_id',u.login_id,
        'password_hash',u.password_hash,'role',r.role_code,'is_active',u.is_active AND r.is_active,
        'locked_until',u.locked_until,'failed_login_count',u.failed_login_count,
        'contact_data',COALESCE((SELECT t.ui_data FROM public.trainee t WHERE t.trainee_id=u.trainee_id),
            (SELECT t.ui_data FROM public.trainer t WHERE t.trainer_id=u.trainer_id),u.ui_data)::text)), '[]'::jsonb)
    INTO p_result FROM public.app_user u JOIN public.m_role r ON r.role_id=u.role_id
    WHERE NOT u.portal_deleted AND (lower(u.login_id)=lower(trim(p_login_id)) OR
        (position('@' IN p_login_id)>0 OR length(regexp_replace(p_login_id,'[^0-9]','','g'))>=10) AND (
            u.email_hash=p_contact_hash OR u.mobile_hash=p_contact_hash OR
            u.ui_data->'_contacts'->'email'->>'hash'=p_contact_hash OR
            u.ui_data->'_contacts'->'phone'->>'hash'=p_contact_hash OR
            EXISTS(SELECT 1 FROM public.trainee t WHERE t.trainee_id=u.trainee_id AND NOT t.is_erased AND
                (t.email_hash=p_contact_hash OR t.mobile_hash=p_contact_hash)) OR
            EXISTS(SELECT 1 FROM public.trainer t WHERE t.trainer_id=u.trainer_id AND
                (t.email_hash=p_contact_hash OR t.mobile_hash=p_contact_hash))));
END;
$procedure$;

CREATE OR REPLACE PROCEDURE public.usp_portal_login_result(IN p_user_id bigint,IN p_success boolean,
    IN p_login_id varchar,INOUT p_result jsonb DEFAULT NULL)
LANGUAGE plpgsql AS $procedure$
BEGIN
    IF p_user_id IS NOT NULL THEN
        UPDATE public.app_user SET failed_login_count=CASE WHEN p_success THEN 0 ELSE failed_login_count+1 END,
            locked_until=CASE WHEN p_success THEN NULL WHEN failed_login_count+1>=3
                THEN now()+interval '15 minutes' ELSE locked_until END,
            last_login_at=CASE WHEN p_success THEN now() ELSE last_login_at END
        WHERE user_id=p_user_id;
    END IF;
    INSERT INTO public.user_activity_log(user_id,login_id_tried,activity_type,result)
    VALUES(p_user_id,left(p_login_id,30),'LOGIN',CASE WHEN p_success THEN 'SUCCESS' ELSE 'FAILED' END);
    p_result:='[{"is_success":true}]'::jsonb;
END;
$procedure$;

CREATE OR REPLACE PROCEDURE public.usp_portal_save_session(IN p_user_id bigint,IN p_token_id varchar,
    IN p_expires_at timestamptz,IN p_role varchar,INOUT p_result jsonb DEFAULT NULL)
LANGUAGE plpgsql AS $procedure$
BEGIN
    INSERT INTO public.app_auth_session(user_id,token_id,expires_at,role_code)
    VALUES(p_user_id,p_token_id,p_expires_at,p_role)
    ON CONFLICT(user_id) DO UPDATE SET token_id=excluded.token_id,expires_at=excluded.expires_at,role_code=excluded.role_code;
    p_result:='[{"is_success":true}]'::jsonb;
END;
$procedure$;

CREATE OR REPLACE PROCEDURE public.usp_portal_check_session(IN p_user_id bigint,IN p_token_id varchar,
    INOUT p_result jsonb DEFAULT NULL)
LANGUAGE plpgsql AS $procedure$
BEGIN
    p_result:=jsonb_build_array(jsonb_build_object('is_active',EXISTS (
        SELECT 1 FROM public.app_auth_session s JOIN public.app_user u ON u.user_id=s.user_id
        JOIN public.m_role r ON r.role_id=u.role_id WHERE s.user_id=p_user_id AND s.token_id=p_token_id
        AND s.expires_at>now() AND u.is_active AND r.is_active AND s.role_code=r.role_code
    )));
END;
$procedure$;

CREATE OR REPLACE PROCEDURE public.usp_portal_revoke_session(IN p_user_id bigint,IN p_token_id varchar,
    INOUT p_result jsonb DEFAULT NULL)
LANGUAGE plpgsql AS $procedure$
BEGIN
    DELETE FROM public.app_auth_session WHERE user_id=p_user_id AND token_id=p_token_id;
    INSERT INTO public.user_activity_log(user_id,activity_type,result) VALUES(p_user_id,'LOGOUT','SUCCESS');
    p_result:='[{"is_success":true}]'::jsonb;
END;
$procedure$;
