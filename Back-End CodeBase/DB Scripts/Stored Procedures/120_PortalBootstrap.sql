CREATE OR REPLACE PROCEDURE public.usp_portal_bootstrap(IN p_users jsonb,IN p_schools jsonb,INOUT p_result jsonb DEFAULT NULL)
LANGUAGE plpgsql AS $procedure$
DECLARE item jsonb; role_number integer; state_number integer; state_key integer; district_key integer; block_key integer; target_role_id integer;
    role_names text[]:=ARRAY['schoolnet-super-admin','sponsor-admin','schoolnet-project-admin','state-admin','school-admin','trainer','trainee','reporting-audit-user'];
BEGIN
    FOR role_number IN 1..array_length(role_names,1) LOOP
        INSERT INTO public.m_role(role_code,role_name,role_rank,role_category,data_scope)
        VALUES(role_names[role_number],initcap(replace(role_names[role_number],'-',' ')),role_number,
            CASE WHEN role_names[role_number]='trainer' THEN 'TRAINER' WHEN role_names[role_number]='trainee' THEN 'TRAINEE' ELSE 'MANAGEMENT' END,
            CASE WHEN role_names[role_number]='schoolnet-super-admin' THEN 'ALL' WHEN role_names[role_number]='trainee' THEN 'SELF' ELSE 'GRANT' END)
        ON CONFLICT(role_code) DO NOTHING;
    END LOOP;
    FOR item IN SELECT value FROM jsonb_array_elements(p_users) LOOP
        SELECT role_id INTO target_role_id FROM public.m_role WHERE role_code=item->>'role';
        INSERT INTO public.app_user(login_id,full_name,role_id,password_hash,must_change_password,external_id,
            portal_collection,ui_data)
        VALUES(item->>'userId',item->>'userId',target_role_id,item->>'passwordHash',false,item->>'userId',
            'teacher-training-users',jsonb_build_object('id',item->>'userId','userId',item->>'userId','role',item->>'role','active',true))
        ON CONFLICT(login_id) DO NOTHING;
    END LOOP;
    UPDATE public.app_user SET portal_owner_user_id=user_id WHERE portal_owner_user_id IS NULL;
    FOR item IN SELECT value FROM jsonb_array_elements(p_schools) LOOP
        SELECT state_id INTO state_key FROM public.m_state WHERE state_name=item->>'state';
        IF state_key IS NULL THEN
            SELECT count(*)+1 INTO state_number FROM public.m_state;
            INSERT INTO public.m_state(state_code,state_name) VALUES('S'||state_number,item->>'state') RETURNING state_id INTO state_key;
        END IF;
        SELECT district_id INTO district_key FROM public.m_district WHERE state_id=state_key AND district_name=item->>'district';
        IF district_key IS NULL THEN
            INSERT INTO public.m_district(state_id,district_name) VALUES(state_key,item->>'district') RETURNING district_id INTO district_key;
        END IF;
        block_key:=NULL;
        IF COALESCE(item->>'block','')<>'' THEN
            SELECT block_id INTO block_key FROM public.m_block WHERE district_id=district_key AND block_name=item->>'block';
            IF block_key IS NULL THEN
                INSERT INTO public.m_block(district_id,block_name) VALUES(district_key,item->>'block') RETURNING block_id INTO block_key;
            END IF;
        END IF;
        INSERT INTO public.m_school(udise_code,school_name,state_id,district_id,block_id,actual_location,external_id,portal_collection,ui_data)
        VALUES(item->>'udise',item->>'school',state_key,district_key,block_key,item->>'school',item->>'udise','teacher-training-schools',item||jsonb_build_object('id',item->>'udise'))
        ON CONFLICT(udise_code) DO NOTHING;
    END LOOP;
    p_result:=jsonb_build_array(jsonb_build_object('payload',jsonb_build_object('adminId',
        (SELECT user_id FROM public.app_user WHERE login_id='Demo2'))::text));
END;
$procedure$;

CREATE OR REPLACE PROCEDURE public.usp_portal_seed_scopes(IN p_project_id integer,INOUT p_result jsonb DEFAULT NULL)
LANGUAGE plpgsql AS $procedure$
DECLARE target record;
BEGIN
    FOR target IN SELECT user_id FROM public.app_user WHERE login_id IN ('Demo1','Demo3','Demo4','Demo5','Demo6','Demo8') LOOP
        IF NOT EXISTS(SELECT 1 FROM public.user_access_scope WHERE user_id=target.user_id AND project_id=p_project_id) THEN
            INSERT INTO public.user_access_scope(user_id,project_id) VALUES(target.user_id,p_project_id);
        END IF;
    END LOOP;
    p_result:='[{"is_success":true}]';
END;
$procedure$;
