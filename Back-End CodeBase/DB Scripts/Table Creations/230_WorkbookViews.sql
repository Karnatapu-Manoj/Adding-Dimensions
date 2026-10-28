CREATE OR REPLACE VIEW public.v_school_geography AS
SELECT school.school_id,school.udise_code,school.school_name,school.actual_location,
    state.state_id,state.state_name,district.district_id,district.district_name,
    block.block_id,block.block_name,cluster.cluster_id,cluster.cluster_name
FROM public.m_school school JOIN public.m_state state ON state.state_id=school.state_id
JOIN public.m_district district ON district.district_id=school.district_id
LEFT JOIN public.m_block block ON block.block_id=school.block_id
LEFT JOIN public.m_cluster cluster ON cluster.cluster_id=school.cluster_id;

CREATE OR REPLACE VIEW public.v_trainer_assignment_history AS
SELECT b.batch_id,b.batch_code,b.project_id,b.trainer_id,t.trainer_name,b.start_date,b.end_date,b.school_id,
    b.ui_data->>'status' AS batch_status FROM public.training_batch b
JOIN public.trainer t ON t.trainer_id=b.trainer_id WHERE NOT b.portal_deleted;

CREATE OR REPLACE VIEW public.v_batch_progress AS
SELECT b.batch_id,b.external_id,b.batch_code,b.project_id,b.plan_id,b.school_id,b.trainer_id,b.start_date,b.end_date,
    b.ui_data,b.capacity,school.state_name,school.district_name,school.block_name,school.school_name,school.udise_code,
    trainer.trainer_name,plan.plan_name,
    (SELECT count(*) FROM public.batch_enrollment e WHERE e.batch_id=b.batch_id AND NOT e.portal_deleted AND e.approval_status<>'REJECTED') AS registered_count,
    (SELECT count(*) FROM public.batch_enrollment e WHERE e.batch_id=b.batch_id AND NOT e.portal_deleted AND e.approval_status='APPROVED') AS approved_count,
    (SELECT count(DISTINCT e.enrollment_id) FROM public.batch_enrollment e JOIN public.attendance a ON a.enrollment_id=e.enrollment_id
        WHERE e.batch_id=b.batch_id AND NOT e.portal_deleted AND NOT a.portal_deleted AND a.status='PRESENT') AS attended_count,
    (SELECT count(DISTINCT e.enrollment_id) FROM public.batch_enrollment e JOIN public.completion_review c ON c.enrollment_id=e.enrollment_id
        WHERE e.batch_id=b.batch_id AND NOT e.portal_deleted AND c.is_eligible) AS completed_count,
    (SELECT count(*) FROM public.batch_enrollment e JOIN public.certificate_record c ON c.enrollment_id=e.enrollment_id
        WHERE e.batch_id=b.batch_id AND NOT e.portal_deleted AND NOT c.portal_deleted AND COALESCE(c.ui_data->>'status','Issued')<>'Revoked') AS certified_count,
    COALESCE((SELECT 100.0*count(*) FILTER(WHERE a.status='PRESENT')/NULLIF(count(*),0)
        FROM public.attendance a JOIN public.batch_enrollment e ON e.enrollment_id=a.enrollment_id
        WHERE e.batch_id=b.batch_id AND NOT a.portal_deleted AND NOT e.portal_deleted),0) AS attendance_pct
FROM public.training_batch b JOIN public.v_school_geography school ON school.school_id=b.school_id
JOIN public.trainer trainer ON trainer.trainer_id=b.trainer_id JOIN public.training_plan plan ON plan.plan_id=b.plan_id
WHERE NOT b.portal_deleted AND COALESCE(b.ui_data->>'status','') NOT IN ('Cancelled','Archived');

CREATE OR REPLACE VIEW public.v_project_status AS
SELECT p.project_id,p.project_code,p.project_name,p.start_date,p.end_date,
    CASE WHEN CURRENT_DATE<p.start_date THEN 'Upcoming' WHEN CURRENT_DATE>p.end_date THEN 'Completed' ELSE 'Ongoing' END AS project_status,
    count(b.batch_id) AS batch_count
FROM public.project p LEFT JOIN public.training_batch b ON b.project_id=p.project_id AND NOT b.portal_deleted
WHERE NOT p.portal_deleted GROUP BY p.project_id;

CREATE OR REPLACE VIEW public.v_batch_schedule AS
SELECT b.batch_id,b.batch_code,day.batch_day_id,day.day_no,day.day_date,day.day_title,
    activity.seq_no,activity.activity_type,activity.title,activity.start_time,activity.duration_minutes,activity.resource_id
FROM public.training_batch b JOIN public.batch_day day ON day.batch_id=b.batch_id
LEFT JOIN public.batch_day_activity activity ON activity.batch_day_id=day.batch_day_id WHERE NOT b.portal_deleted;

CREATE OR REPLACE VIEW public.v_trainee_resource_access AS
SELECT DISTINCT e.trainee_id,e.batch_id,resource.resource_id FROM public.batch_enrollment e
JOIN public.training_batch b ON b.batch_id=e.batch_id
JOIN public.learning_resource resource ON NOT resource.portal_deleted
WHERE NOT e.portal_deleted AND e.approval_status='APPROVED' AND (
    (resource.access_mode='REPOSITORY' AND (resource.is_common OR resource.project_id=b.project_id)) OR
    EXISTS(SELECT 1 FROM public.plan_resource_link link WHERE link.plan_id=b.plan_id AND link.resource_id=resource.resource_id AND link.is_active) OR
    EXISTS(SELECT 1 FROM public.resource_audience audience WHERE audience.resource_id=resource.resource_id AND audience.is_active
        AND (audience.trainee_id=e.trainee_id OR audience.batch_id=b.batch_id))
);
