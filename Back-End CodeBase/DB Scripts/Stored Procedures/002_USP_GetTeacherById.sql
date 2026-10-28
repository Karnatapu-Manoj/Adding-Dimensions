CREATE OR REPLACE PROCEDURE public.usp_get_teacher_by_id
(
    IN p_teacher_id integer,
    INOUT p_result jsonb DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT COALESCE(jsonb_agg(to_jsonb(result)), '[]'::jsonb) INTO p_result
    FROM
    (
        SELECT id, first_name, last_name, email, subject, phone_number, role, is_active, created_at
        FROM public.teachers WHERE id = p_teacher_id
    ) result;
END;
$$;
