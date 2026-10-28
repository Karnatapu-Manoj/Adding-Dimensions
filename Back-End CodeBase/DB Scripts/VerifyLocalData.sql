SELECT 'schools' entity,count(*) records FROM public.m_school WHERE NOT portal_deleted
UNION ALL SELECT 'projects',count(*) FROM public.project WHERE NOT portal_deleted
UNION ALL SELECT 'plans',count(*) FROM public.training_plan WHERE NOT portal_deleted
UNION ALL SELECT 'batches',count(*) FROM public.training_batch WHERE NOT portal_deleted
UNION ALL SELECT 'trainees',count(*) FROM public.trainee WHERE NOT portal_deleted
UNION ALL SELECT 'registrations',count(*) FROM public.batch_enrollment WHERE NOT portal_deleted
UNION ALL SELECT 'attendance',count(*) FROM public.attendance WHERE NOT portal_deleted
UNION ALL SELECT 'OTP challenges',count(*) FROM public.portal_otp_challenge;
SELECT r.role_code,count(*) active_accounts FROM public.app_user u JOIN public.m_role r ON r.role_id=u.role_id
WHERE u.is_active AND NOT u.portal_deleted GROUP BY r.role_code ORDER BY r.role_code;
