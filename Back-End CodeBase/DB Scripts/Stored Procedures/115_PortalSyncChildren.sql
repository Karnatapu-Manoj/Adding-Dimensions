CREATE OR REPLACE PROCEDURE public.usp_portal_sync_children(IN p_user_id bigint,IN p_collection varchar,
    IN p_record_id bigint,IN p_data jsonb)
LANGUAGE plpgsql AS $procedure$
DECLARE item jsonb; day_number integer; child_id bigint; target_id bigint;
BEGIN
    CASE p_collection
    WHEN 'teacher-training-projects' THEN
        UPDATE public.project SET portal_project_id=p_record_id WHERE project_id=p_record_id;
        FOR item IN SELECT value FROM jsonb_array_elements(COALESCE(p_data->'phases','[]')) LOOP
            INSERT INTO public.project_phase(project_id,phase_name,sequence_number,start_date,end_date,status,external_id,ui_data,portal_project_id)
            VALUES(p_record_id,item->>'name',(item->>'sequence')::integer,(item->>'startDate')::date,
                (item->>'endDate')::date,item->>'status',item->>'id',item,p_record_id)
            ON CONFLICT(external_id) DO UPDATE SET phase_name=excluded.phase_name,sequence_number=excluded.sequence_number,
                start_date=excluded.start_date,end_date=excluded.end_date,status=excluded.status,ui_data=excluded.ui_data;
        END LOOP;
        UPDATE public.user_access_scope SET is_active=false
        WHERE project_id=p_record_id AND portal_collection='project-assignment';
        FOR target_id IN SELECT user_id FROM public.app_user WHERE login_id IN
            (SELECT jsonb_array_elements_text(COALESCE(p_data->'assignedUsers','[]'))) OR user_id=p_user_id LOOP
            IF EXISTS(SELECT 1 FROM public.user_access_scope WHERE user_id=target_id AND project_id=p_record_id AND portal_collection='project-assignment') THEN
                UPDATE public.user_access_scope SET is_active=true WHERE user_id=target_id AND project_id=p_record_id AND portal_collection='project-assignment';
            ELSE
                INSERT INTO public.user_access_scope(user_id,project_id,created_by,portal_collection)
                VALUES(target_id,p_record_id,p_user_id,'project-assignment');
            END IF;
        END LOOP;
    WHEN 'teacher-training-plans' THEN
        FOR day_number IN 1..(p_data->>'days')::integer LOOP
            INSERT INTO public.training_plan_day(plan_id,day_no,day_title,created_by)
            VALUES(p_record_id,day_number,'Day '||day_number,p_user_id)
            ON CONFLICT(plan_id,day_no) DO NOTHING;
        END LOOP;
    WHEN 'teacher-training-batch-plan-uses' THEN
        UPDATE public.training_batch SET portal_batch_id=p_record_id WHERE batch_id=p_record_id;
        day_number:=0;
        FOR item IN SELECT value FROM jsonb_array_elements(COALESCE(p_data->'trainingDates','[]')) LOOP
            day_number:=day_number+1;
            INSERT INTO public.batch_day(batch_id,day_no,day_date,day_title)
            VALUES(p_record_id,day_number,(item#>>'{}')::date,'Day '||day_number)
            ON CONFLICT(batch_id,day_no) DO UPDATE SET day_date=excluded.day_date;
        END LOOP;
    WHEN 'teacher-training-trainer-profiles' THEN
        UPDATE public.app_user SET trainer_id=p_record_id WHERE login_id=p_data->>'userId';
    WHEN 'teacher-training-trainees' THEN
        UPDATE public.app_user SET trainee_id=p_record_id WHERE login_id=p_data->>'userId';
    WHEN 'teacher-training-users' THEN
        UPDATE public.app_user SET portal_owner_user_id=p_record_id WHERE user_id=p_record_id;
    WHEN 'teacher-training-assessment-form-master' THEN
        UPDATE public.form_question SET is_active=false WHERE resource_id=p_record_id;
        day_number:=0;
        FOR item IN SELECT value FROM jsonb_array_elements(COALESCE(p_data->'questions','[]')) LOOP
            day_number:=day_number+1;
            INSERT INTO public.form_question(resource_id,question_text,expected_answer,options_json,marks,sort_order,
                external_id,ui_data,created_by)
            VALUES(p_record_id,item->>'prompt',item->>'correctIndex',item->'options',COALESCE((item->>'points')::numeric,1),
                day_number,left((p_data->>'id')||':'||(item->>'id'),100),item,p_user_id)
            ON CONFLICT(external_id) DO UPDATE SET question_text=excluded.question_text,expected_answer=excluded.expected_answer,
                options_json=excluded.options_json,marks=excluded.marks,sort_order=excluded.sort_order,is_active=true,ui_data=excluded.ui_data;
        END LOOP;
    WHEN 'teacher-training-registrations' THEN
        IF COALESCE((p_data->>'consentProvided')::boolean,false) THEN
            INSERT INTO public.consent_record(trainee_id,purpose,notice_version,channel)
            SELECT trainee_id,'TRAINING_ENROLMENT','1.0',CASE WHEN p_data->>'source' LIKE '%Excel%' THEN 'EXCEL' ELSE 'ADMIN' END
            FROM public.batch_enrollment e WHERE e.enrollment_id=p_record_id
            AND NOT EXISTS(SELECT 1 FROM public.consent_record c WHERE c.trainee_id=e.trainee_id AND c.purpose='TRAINING_ENROLMENT');
        END IF;
    WHEN 'teacher-training-assessment-records','teacher-training-feedback-records' THEN
        FOR item IN SELECT jsonb_build_object('question_id',q.question_id,'answer',p_data->'answers'->>(q.ui_data->>'id'),
            'expected',q.expected_answer,'marks',q.marks) FROM public.form_question q
            WHERE q.resource_id=(SELECT resource_id FROM public.assessment_attempt WHERE attempt_id=p_record_id) AND q.is_active LOOP
            INSERT INTO public.form_submission(enrollment_id,question_id,answer,score)
            SELECT a.enrollment_id,(item->>'question_id')::bigint,COALESCE(item->>'answer',''),
                CASE WHEN a.kind='feedback' THEN NULL WHEN item->>'answer'=item->>'expected' THEN (item->>'marks')::numeric ELSE 0 END
            FROM public.assessment_attempt a WHERE a.attempt_id=p_record_id;
        END LOOP;
    WHEN 'teacher-training-certificates' THEN
        INSERT INTO public.completion_review(enrollment_id,is_eligible,remarks,reviewed_by)
        SELECT enrollment_id,true,'Completion rules verified by the application service.',p_user_id
        FROM public.certificate_record WHERE certificate_id=p_record_id
        ON CONFLICT(enrollment_id) DO UPDATE SET is_eligible=true,remarks=excluded.remarks,
            reviewed_by=excluded.reviewed_by,reviewed_at=now();
    ELSE NULL;
    END CASE;
END;
$procedure$;
