CREATE OR REPLACE PROCEDURE public.usp_delete_teacher
(
    IN p_teacher_id integer,
    INOUT p_result jsonb DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    affected_count integer;
BEGIN
    DELETE FROM public.teachers WHERE id = p_teacher_id;
    GET DIAGNOSTICS affected_count = ROW_COUNT;
    p_result := jsonb_build_array(jsonb_build_object('affected_count', affected_count));
END;
$$;
