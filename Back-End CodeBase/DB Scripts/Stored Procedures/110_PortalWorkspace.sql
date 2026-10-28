CREATE OR REPLACE PROCEDURE public.usp_portal_snapshot(IN p_user_id bigint,INOUT p_result jsonb DEFAULT NULL)
LANGUAGE plpgsql AS $procedure$
DECLARE collection record; actor_role_code text; rows_json jsonb; snapshot jsonb:='{}';
BEGIN
    SELECT r.role_code INTO actor_role_code FROM public.app_user u JOIN public.m_role r ON r.role_id=u.role_id
    WHERE u.user_id=p_user_id AND u.is_active AND r.is_active;
    IF actor_role_code IS NULL THEN RAISE EXCEPTION 'Authentication is required.' USING ERRCODE='42501'; END IF;
    FOR collection IN SELECT * FROM public.portal_collection ORDER BY collection_key LOOP
        IF NOT (actor_role_code=ANY(collection.read_roles)) THEN
            snapshot:=snapshot||jsonb_build_object(collection.collection_key,'[]'::jsonb);
            CONTINUE;
        END IF;
        EXECUTE format('SELECT COALESCE(jsonb_agg(ui_data || jsonb_build_object(''_dbId'',%I,''_version'',row_version,''_ownerId'',portal_owner_user_id) ORDER BY %I),''[]''::jsonb) '
            'FROM public.%I WHERE portal_collection=$1 AND NOT portal_deleted '
            'AND public.portal_row_access($2,portal_project_id,portal_owner_user_id,portal_batch_id) '
            'AND ($3<>''trainee'' OR $4 NOT IN (''trainee'',''batch_enrollment'',''attendance'',''assessment_attempt'',''certificate_record'',''resource_progress'',''external_course_record'') OR portal_owner_user_id=$2)',
            collection.pk_column,collection.pk_column,collection.table_name)
        INTO rows_json USING collection.collection_key,p_user_id,actor_role_code,collection.table_name::text;
        snapshot:=snapshot||jsonb_build_object(collection.collection_key,rows_json);
    END LOOP;
    snapshot:=snapshot||jsonb_build_object('_roles',(SELECT COALESCE(jsonb_agg(jsonb_build_object('id',role_id,'role',role_code)),'[]') FROM public.m_role WHERE is_active),
        '_states',(SELECT COALESCE(jsonb_agg(jsonb_build_object('id',state_id,'name',state_name)),'[]') FROM public.m_state),
        '_districts',(SELECT COALESCE(jsonb_agg(jsonb_build_object('id',d.district_id,'name',d.district_name,'state',s.state_name)),'[]') FROM public.m_district d JOIN public.m_state s ON s.state_id=d.state_id),
        '_current',(SELECT jsonb_build_object('id',user_id,'userId',login_id,'role',actor_role_code) FROM public.app_user WHERE user_id=p_user_id));
    p_result:=jsonb_build_array(jsonb_build_object('payload',snapshot::text));
END;
$procedure$;

CREATE OR REPLACE PROCEDURE public.usp_portal_apply(IN p_user_id bigint,IN p_collection varchar,
    IN p_rows jsonb,IN p_deletes jsonb,INOUT p_result jsonb DEFAULT NULL)
LANGUAGE plpgsql AS $procedure$
DECLARE config public.portal_collection; actor_role_code text; row_input jsonb; row_values jsonb;
    old_row jsonb; returned_id bigint; col_names text; col_values text; update_values text;
    ext_id text; old_version bigint; delete_input jsonb; project_id integer; owner_id bigint; batch_id bigint;
BEGIN
    SELECT * INTO config FROM public.portal_collection WHERE collection_key=p_collection;
    SELECT r.role_code INTO actor_role_code FROM public.app_user u JOIN public.m_role r ON r.role_id=u.role_id
    WHERE u.user_id=p_user_id AND u.is_active AND r.is_active;
    IF config.collection_key IS NULL OR actor_role_code IS NULL OR NOT(actor_role_code=ANY(config.write_roles)) THEN
        RAISE EXCEPTION 'You do not have permission to change these records.' USING ERRCODE='42501';
    END IF;
    IF jsonb_typeof(p_rows)<>'array' OR jsonb_array_length(p_rows)>2000 THEN
        RAISE EXCEPTION 'Invalid change set.' USING ERRCODE='22023';
    END IF;
    FOR row_input IN SELECT value FROM jsonb_array_elements(p_rows) LOOP
        ext_id:=row_input->>'id';
        IF ext_id IS NULL OR length(ext_id)>100 THEN RAISE EXCEPTION 'Invalid record identifier.' USING ERRCODE='22023'; END IF;
        EXECUTE format('SELECT to_jsonb(t) FROM public.%I t WHERE external_id=$1 FOR UPDATE',config.table_name)
        INTO old_row USING ext_id;
        project_id:=(row_input->>'projectId')::integer;
        owner_id:=(row_input->>'ownerId')::bigint;
        batch_id:=(row_input->>'batchId')::bigint;
        IF old_row IS NOT NULL AND (old_row->>'portal_collection') IS DISTINCT FROM p_collection THEN
            RAISE EXCEPTION 'Record belongs to another collection.' USING ERRCODE='22023';
        END IF;
        IF NOT public.portal_row_access(p_user_id,project_id,owner_id,batch_id) OR
            (old_row IS NOT NULL AND NOT public.portal_row_access(p_user_id,
                (old_row->>'portal_project_id')::integer,(old_row->>'portal_owner_user_id')::bigint,
                (old_row->>'portal_batch_id')::bigint)) THEN
            RAISE EXCEPTION 'Record is outside your assigned scope.' USING ERRCODE='42501';
        END IF;
        old_version:=(old_row->>'row_version')::bigint;
        IF old_row IS NOT NULL AND COALESCE((row_input->>'version')::bigint,0)<>old_version THEN
            RAISE EXCEPTION 'This record changed. Reload and try again.' USING ERRCODE='40001';
        END IF;
        IF config.table_name='audit_log' AND old_row IS NOT NULL THEN
            RAISE EXCEPTION 'Audit records cannot be changed.' USING ERRCODE='42501';
        END IF;
        row_values:=(row_input->'values')||jsonb_build_object('external_id',ext_id,'ui_data',row_input->'data',
            'portal_collection',p_collection,'portal_project_id',project_id,'portal_owner_user_id',owner_id,
            'portal_batch_id',batch_id,'portal_deleted',false,'row_version',COALESCE(old_version,0)+1);
        -- Column identifiers come from actual database metadata, never from SQL supplied by a client.
        IF EXISTS (SELECT 1 FROM jsonb_object_keys(row_values) k WHERE NOT EXISTS (
            SELECT 1 FROM information_schema.columns c WHERE c.table_schema='public'
            AND c.table_name=config.table_name AND c.column_name=k AND c.is_identity='NO')) THEN
            RAISE EXCEPTION 'Invalid record columns.' USING ERRCODE='22023';
        END IF;
        SELECT string_agg(format('%I',key),','),string_agg(format('r.%I',key),','),
            string_agg(format('%I=EXCLUDED.%I',key,key),',')
        INTO col_names,col_values,update_values FROM jsonb_object_keys(row_values) key;
        IF old_row IS NULL THEN
            EXECUTE format('INSERT INTO public.%I (%s) SELECT %s FROM jsonb_populate_record(NULL::public.%I,$1) r RETURNING %I',
                config.table_name,col_names,col_values,config.table_name,config.pk_column) INTO returned_id USING row_values;
        ELSE
            SELECT string_agg(format('%I=r.%I',key,key),',') INTO update_values FROM jsonb_object_keys(row_values) key;
            EXECUTE format('UPDATE public.%I target SET %s FROM jsonb_populate_record(NULL::public.%I,$1) r '
                'WHERE target.external_id=$2 RETURNING target.%I',config.table_name,update_values,config.table_name,config.pk_column)
                INTO returned_id USING row_values,ext_id;
        END IF;
        IF config.table_name<>'audit_log' THEN
            INSERT INTO public.audit_log(actor_user_id,action,entity_type,entity_id,project_id,before_json,after_json)
            VALUES(p_user_id,CASE WHEN old_row IS NULL THEN 'CREATE' ELSE 'UPDATE' END,
                config.table_name,returned_id::text,project_id,
                CASE WHEN old_row IS NULL THEN NULL ELSE jsonb_build_object('id',ext_id,'version',old_version) END,
                jsonb_build_object('id',ext_id,'version',COALESCE(old_version,0)+1));
        END IF;
        CALL public.usp_portal_sync_children(p_user_id,p_collection,returned_id,row_input->'data');
    END LOOP;
    FOR delete_input IN SELECT value FROM jsonb_array_elements(p_deletes) LOOP
        ext_id:=delete_input->>'id';
        EXECUTE format('SELECT to_jsonb(t) FROM public.%I t WHERE external_id=$1 AND NOT portal_deleted FOR UPDATE',config.table_name)
        INTO old_row USING ext_id;
        IF old_row IS NULL THEN CONTINUE; END IF;
        IF config.table_name='audit_log' OR (old_row->>'portal_collection') IS DISTINCT FROM p_collection OR
            NOT public.portal_row_access(p_user_id,(old_row->>'portal_project_id')::integer,
                (old_row->>'portal_owner_user_id')::bigint,(old_row->>'portal_batch_id')::bigint) THEN
            RAISE EXCEPTION 'You do not have permission to remove this record.' USING ERRCODE='42501';
        END IF;
        IF COALESCE((delete_input->>'version')::bigint,0)<>(old_row->>'row_version')::bigint THEN
            RAISE EXCEPTION 'This record changed. Reload and try again.' USING ERRCODE='40001';
        END IF;
        returned_id:=(old_row->>config.pk_column)::bigint;
        IF config.table_name='training_batch' AND EXISTS(SELECT 1 FROM public.batch_enrollment e WHERE e.batch_id=returned_id AND NOT e.portal_deleted) THEN
            RAISE EXCEPTION 'A batch with registrations cannot be deleted; cancel it instead.' USING ERRCODE='22023';
        END IF;
        IF config.table_name='project' AND EXISTS(SELECT 1 FROM public.training_batch b WHERE b.project_id=returned_id AND NOT b.portal_deleted) THEN
            RAISE EXCEPTION 'A project with batches cannot be deleted.' USING ERRCODE='22023';
        END IF;
        IF config.table_name='training_plan' AND EXISTS(SELECT 1 FROM public.training_batch b WHERE b.plan_id=returned_id AND NOT b.portal_deleted) THEN
            RAISE EXCEPTION 'A plan with batches cannot be deleted.' USING ERRCODE='22023';
        END IF;
        EXECUTE format('UPDATE public.%I SET portal_deleted=true,row_version=row_version+1 WHERE external_id=$1',config.table_name) USING ext_id;
        INSERT INTO public.audit_log(actor_user_id,action,entity_type,entity_id,project_id)
        VALUES(p_user_id,'DELETE',config.table_name,returned_id::text,(old_row->>'portal_project_id')::integer);
    END LOOP;
    CALL public.usp_portal_snapshot(p_user_id,p_result);
END;
$procedure$;
