CREATE OR REPLACE PROCEDURE public.usp_get_user_auth_token
(
    IN p_teacher_id integer,
    IN p_token_id varchar,
    INOUT p_result jsonb DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_result := jsonb_build_array(jsonb_build_object('is_active', EXISTS
    (
        SELECT 1 FROM public.teacher_auth_tokens a
        INNER JOIN public.teachers t ON t.id = a.teacher_id
        WHERE a.teacher_id = p_teacher_id AND a.token_id = p_token_id
          AND a.expires_at > now() AND t.is_active
    )));
END;
$$;
