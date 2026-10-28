CREATE OR REPLACE PROCEDURE public.usp_save_auth_token
(
    IN p_teacher_id integer,
    IN p_token_id varchar,
    IN p_expires_at timestamptz,
    INOUT p_result jsonb DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO public.teacher_auth_tokens (teacher_id, token_id, expires_at)
    VALUES (p_teacher_id, p_token_id, p_expires_at)
    ON CONFLICT (teacher_id) DO UPDATE
    SET token_id = EXCLUDED.token_id, expires_at = EXCLUDED.expires_at;
    p_result := jsonb_build_array(jsonb_build_object('is_success', true));
END;
$$;
