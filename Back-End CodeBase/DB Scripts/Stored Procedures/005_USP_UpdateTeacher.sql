CREATE OR REPLACE PROCEDURE public.usp_update_teacher
(
    IN p_teacher_id integer,
    IN p_first_name varchar,
    IN p_last_name varchar,
    IN p_email varchar,
    IN p_subject varchar,
    IN p_phone_number varchar,
    INOUT p_result jsonb DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    WITH updated AS
    (
        UPDATE public.teachers
        SET first_name = trim(p_first_name), last_name = trim(p_last_name),
            email = lower(trim(p_email)), subject = trim(p_subject),
            phone_number = trim(p_phone_number), updated_at = now()
        WHERE id = p_teacher_id
        RETURNING id, first_name, last_name, email, subject, phone_number, role, is_active, created_at
    )
    SELECT COALESCE(jsonb_agg(to_jsonb(updated)), '[]'::jsonb) INTO p_result FROM updated;
END;
$$;
