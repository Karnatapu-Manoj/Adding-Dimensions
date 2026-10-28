CREATE OR REPLACE PROCEDURE public.usp_portal_dashboard(IN p_user_id bigint,INOUT p_result jsonb DEFAULT NULL)
LANGUAGE plpgsql AS $procedure$
DECLARE result jsonb;
BEGIN
    SELECT COALESCE(jsonb_agg(jsonb_build_object(
        'index',b.batch_id,'id',b.batch_code,'batch',b.batch_code,'externalId',b.external_id,
        'status',CASE WHEN b.ui_data->>'status'='Completed' THEN 'completed' WHEN CURRENT_DATE<b.start_date THEN 'upcoming' ELSE 'ongoing' END,
        'phaseNumber',COALESCE((SELECT sequence_number FROM public.project_phase WHERE external_id=b.ui_data->>'phaseId'),1),
        'project',(SELECT project_name FROM public.project WHERE project_id=b.project_id),
        'phase',b.plan_name,'plan',b.plan_name,'state',b.state_name,'district',b.district_name,'block',COALESCE(b.block_name,''),
        'school',b.school_name,'udise',b.udise_code,'trainer',b.trainer_name,'location',b.district_name||', '||b.state_name,
        'date',to_char(b.start_date,'DD-Mon-YYYY'),'startDate',b.start_date,'endDate',b.end_date,
        'capacity',b.capacity,'teacherParticipants',b.capacity,'studentParticipants',0,'participants',b.registered_count,
        'teacherMetrics',public.portal_audience_metrics(b.batch_id,'Teacher'),
        'studentMetrics',public.portal_audience_metrics(b.batch_id,'Student'),
        'attendanceDays',(SELECT COALESCE(jsonb_agg(to_jsonb(d) ORDER BY d.date),'[]') FROM (
            SELECT a.attendance_date AS date,COALESCE(t.ui_data->>'category','Teacher') AS audience,
                count(*) AS marked,count(*) FILTER(WHERE a.status='PRESENT') AS present
            FROM public.attendance a JOIN public.batch_enrollment e ON e.enrollment_id=a.enrollment_id
            JOIN public.trainee t ON t.trainee_id=e.trainee_id
            WHERE e.batch_id=b.batch_id AND NOT a.portal_deleted AND NOT e.portal_deleted
            GROUP BY a.attendance_date,COALESCE(t.ui_data->>'category','Teacher')) d),
        'registered',b.registered_count,'approved',b.approved_count,'attended',b.attended_count,'completed',b.completed_count,
        'certified',b.certified_count,'attendance',round(b.attendance_pct,1),
        'completion',CASE WHEN b.registered_count=0 THEN 0 ELSE round(100.0*b.completed_count/b.registered_count,1) END,
        'participantRows',(SELECT COALESCE(jsonb_agg(jsonb_build_object('name',t.full_name,
            'type',COALESCE(t.ui_data->>'category','Teacher'),'status',initcap(e.approval_status),'school',b.school_name,
            'id',t.trainee_code)),'[]') FROM public.batch_enrollment e JOIN public.trainee t ON t.trainee_id=e.trainee_id
            WHERE e.batch_id=b.batch_id AND NOT e.portal_deleted)
    ) ORDER BY b.batch_id),'[]') INTO result FROM public.v_batch_progress b
    WHERE public.portal_row_access(p_user_id,b.project_id,NULL,b.batch_id);
    p_result:=jsonb_build_array(jsonb_build_object('payload',jsonb_build_object('batches',result,
        'phases',(SELECT COALESCE(jsonb_agg(jsonb_build_object('name',phase_name,'number',sequence_number,
            'startDate',start_date,'endDate',end_date,'status',status) ORDER BY sequence_number),'[]')
            FROM public.project_phase WHERE NOT portal_deleted AND public.portal_project_access(p_user_id,project_id)))::text));
END;
$procedure$;
