-- Repair/maintain identity links for both imported trainees and public registrations.
UPDATE public.trainee t SET portal_owner_user_id=u.user_id,
    ui_data=t.ui_data||jsonb_build_object('userId',u.login_id),row_version=t.row_version+1
FROM public.app_user u WHERE u.trainee_id=t.trainee_id AND
    (t.portal_owner_user_id IS DISTINCT FROM u.user_id OR t.ui_data->>'userId' IS DISTINCT FROM u.login_id);
UPDATE public.batch_enrollment e SET portal_owner_user_id=u.user_id,
    ui_data=e.ui_data||jsonb_build_object('userId',u.login_id),row_version=e.row_version+1
FROM public.app_user u WHERE u.trainee_id=e.trainee_id AND
    (e.portal_owner_user_id IS DISTINCT FROM u.user_id OR e.ui_data->>'userId' IS DISTINCT FROM u.login_id);
