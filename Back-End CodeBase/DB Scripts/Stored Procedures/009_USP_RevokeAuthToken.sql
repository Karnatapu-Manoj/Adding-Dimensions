CREATE OR REPLACE PROCEDURE public.usp_revoke_auth_token
(
    IN p_teacher_id integer,
    IN p_token_id varchar,
    INOUT p_result jsonb DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM public.teacher_auth_tokens
    WHERE teacher_id = p_teacher_id AND token_id = p_token_id;
    p_result := jsonb_build_array(jsonb_build_object('is_success', true));
END;
$$;
