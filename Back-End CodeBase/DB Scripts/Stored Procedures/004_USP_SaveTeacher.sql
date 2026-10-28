CREATE OR REPLACE PROCEDURE public.usp_save_teacher
(
    IN p_first_name varchar,
    IN p_last_name varchar,
    IN p_email varchar,
    IN p_subject varchar,
    IN p_phone_number varchar,
    IN p_password_hash text,
    IN p_role varchar,
    INOUT p_result jsonb DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    WITH saved AS
    (
        INSERT INTO public.teachers
            (first_name, last_name, email, subject, phone_number, password_hash, role)
        VALUES (trim(p_first_name), trim(p_last_name), lower(trim(p_email)),
                trim(p_subject), trim(p_phone_number), p_password_hash, p_role)
        RETURNING id, first_name, last_name, email, subject, phone_number, role, is_active, created_at
    )
    SELECT jsonb_agg(to_jsonb(saved)) INTO p_result FROM saved;
END;
$$;
