CREATE TABLE IF NOT EXISTS public.assessment_start (
    start_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id bigint NOT NULL REFERENCES public.app_user(user_id),
    enrollment_id bigint NOT NULL REFERENCES public.batch_enrollment(enrollment_id),
    resource_id bigint NOT NULL REFERENCES public.learning_resource(resource_id),
    started_at timestamptz NOT NULL DEFAULT now(),
    expires_at timestamptz NOT NULL,
    consumed_at timestamptz
);
-- BRD v2 allows traceable reissues. Keep the old immutable certificate snapshot
-- and allow one current certificate per enrollment, rather than deleting history.
ALTER TABLE public.certificate_record DROP CONSTRAINT IF EXISTS certificate_record_enrollment_id_key;
DROP INDEX IF EXISTS public.ux_current_certificate;
CREATE UNIQUE INDEX ux_current_certificate ON public.certificate_record(enrollment_id)
WHERE NOT portal_deleted AND COALESCE(ui_data->>'status','Issued') NOT IN ('Superseded','Reissued','Revoked');

CREATE OR REPLACE FUNCTION public.trg_validate_assessment_attempt()
RETURNS trigger LANGUAGE plpgsql AS $function$
DECLARE form_data jsonb; question jsonb; given_answer text; total numeric:=0; maximum numeric:=0; limit_count integer; start_record public.assessment_start;
BEGIN
    PERFORM 1 FROM public.batch_enrollment WHERE enrollment_id=NEW.enrollment_id FOR UPDATE;
    IF NOT EXISTS(SELECT 1 FROM public.batch_enrollment e JOIN public.app_user u ON u.trainee_id=e.trainee_id
        WHERE e.enrollment_id=NEW.enrollment_id AND u.user_id=NEW.portal_owner_user_id
        AND e.approval_status='APPROVED' AND NOT e.portal_deleted) THEN
        RAISE EXCEPTION 'Only the approved trainee may submit this attempt.' USING ERRCODE='42501';
    END IF;
    SELECT ui_data INTO form_data FROM public.learning_resource WHERE resource_id=NEW.resource_id AND NOT portal_deleted;
    limit_count:=COALESCE((form_data->>'attemptLimit')::integer,1);
    IF (SELECT count(*) FROM public.assessment_attempt WHERE enrollment_id=NEW.enrollment_id AND resource_id=NEW.resource_id)>=limit_count THEN
        RAISE EXCEPTION 'The attempt limit has been reached.' USING ERRCODE='22023';
    END IF;
    IF COALESCE((form_data->>'timeLimit')::integer,0)>0 THEN
        SELECT * INTO start_record FROM public.assessment_start
        WHERE start_id=(NEW.ui_data->>'attemptToken')::uuid AND enrollment_id=NEW.enrollment_id
        AND resource_id=NEW.resource_id AND user_id=NEW.portal_owner_user_id FOR UPDATE;
        IF NOT FOUND OR start_record.consumed_at IS NOT NULL OR start_record.expires_at<now() THEN
            RAISE EXCEPTION 'The attempt time limit has expired or this attempt was not started.' USING ERRCODE='22023';
        END IF;
        UPDATE public.assessment_start SET consumed_at=now() WHERE start_id=start_record.start_id;
    END IF;
    FOR question IN SELECT value FROM jsonb_array_elements(COALESCE(form_data->'questions','[]')) LOOP
        given_answer:=NEW.answers->>(question->>'id');
        IF COALESCE((form_data->>'allowUnanswered')::boolean,false)=false AND COALESCE(trim(given_answer),'')='' THEN
            RAISE EXCEPTION 'Answer all required questions.' USING ERRCODE='22023';
        END IF;
        maximum:=maximum+COALESCE((question->>'points')::numeric,1);
        IF given_answer=question->>'correctIndex' THEN total:=total+COALESCE((question->>'points')::numeric,1); END IF;
    END LOOP;
    IF NEW.kind='assessment' AND form_data->>'grading'='graded' THEN
        NEW.score:=total;NEW.max_marks:=maximum;NEW.passed:=total>=COALESCE((form_data->>'passMarks')::numeric,0);
        NEW.ui_data:=NEW.ui_data||jsonb_build_object('score',NEW.score,'maxMarks',NEW.max_marks,'passed',NEW.passed);
    ELSE
        NEW.score:=NULL;NEW.max_marks:=NULL;NEW.passed:=NULL;
        NEW.ui_data:=NEW.ui_data||jsonb_build_object('score',NULL,'maxMarks',NULL,'passed',NULL);
    END IF;
    RETURN NEW;
END;
$function$;
CREATE OR REPLACE TRIGGER trg_validate_assessment_attempt BEFORE INSERT ON public.assessment_attempt
FOR EACH ROW EXECUTE FUNCTION public.trg_validate_assessment_attempt();
