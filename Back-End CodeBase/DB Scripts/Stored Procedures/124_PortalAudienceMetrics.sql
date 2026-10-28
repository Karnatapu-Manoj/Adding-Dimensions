CREATE OR REPLACE FUNCTION public.portal_audience_metrics(p_batch_id bigint,p_audience text)
RETURNS jsonb LANGUAGE sql STABLE AS $function$
WITH participants AS (
    SELECT e.enrollment_id,e.approval_status,
        EXISTS(SELECT 1 FROM public.attendance a WHERE a.enrollment_id=e.enrollment_id AND NOT a.portal_deleted AND a.status='PRESENT') AS attended,
        EXISTS(SELECT 1 FROM public.completion_review c WHERE c.enrollment_id=e.enrollment_id AND c.is_eligible) AS completed,
        EXISTS(SELECT 1 FROM public.certificate_record c WHERE c.enrollment_id=e.enrollment_id AND NOT c.portal_deleted
            AND COALESCE(c.ui_data->>'status','Issued') NOT IN ('Revoked','Superseded')) AS certified
    FROM public.batch_enrollment e JOIN public.trainee t ON t.trainee_id=e.trainee_id
    WHERE e.batch_id=p_batch_id AND NOT e.portal_deleted AND e.approval_status NOT IN ('REJECTED','WITHDRAWN')
        AND lower(COALESCE(t.ui_data->>'category','Teacher'))=lower(p_audience)
), totals AS (
    SELECT count(*) registered,count(*) FILTER(WHERE approval_status='APPROVED') approved,
        count(*) FILTER(WHERE attended) attended,count(*) FILTER(WHERE completed) completed,count(*) FILTER(WHERE certified) certified
    FROM participants
), marks AS (
    SELECT count(*) marked,count(*) FILTER(WHERE a.status='PRESENT') present
    FROM public.attendance a JOIN participants p ON p.enrollment_id=a.enrollment_id WHERE NOT a.portal_deleted
)
SELECT jsonb_build_object('planned',CASE WHEN COALESCE(p.ui_data->'beneficiaries','["Teacher"]') ? p_audience THEN b.capacity ELSE 0 END,
    'registered',x.registered,'approved',x.approved,'attended',x.attended,'completed',x.completed,'certified',x.certified,
    'attendanceMarked',m.marked,'attendancePresent',m.present,
    'attendanceRate',COALESCE(100.0*m.present/NULLIF(m.marked,0),0),
    'completionRate',COALESCE(100.0*x.completed/NULLIF(x.registered,0),0))
FROM totals x CROSS JOIN marks m CROSS JOIN public.training_batch b JOIN public.training_plan p ON p.plan_id=b.plan_id WHERE b.batch_id=p_batch_id;
$function$;
