CREATE OR REPLACE PROCEDURE public.usp_check_database_health
(
    INOUT p_result jsonb DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    PERFORM 1 FROM public.teachers LIMIT 1;
    PERFORM 1 FROM public.teacher_auth_tokens LIMIT 1;
    p_result := jsonb_build_array(jsonb_build_object('is_healthy', true));
END;
$$;
