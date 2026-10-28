-- Each procedure returns a JSON array through p_result. SqlHelper converts it
-- to a DataTable without additional SQL or cursor queries.
CREATE OR REPLACE PROCEDURE public.usp_get_teachers_list
(
    IN p_page_number integer,
    IN p_page_size integer,
    INOUT p_result jsonb DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_page_number < 1 OR p_page_size < 1 OR p_page_size > 100 THEN
        RAISE EXCEPTION 'Invalid pagination.' USING ERRCODE = '22023';
    END IF;
    SELECT COALESCE(jsonb_agg(to_jsonb(result) ORDER BY result.id), '[]'::jsonb) INTO p_result
    FROM
    (
        SELECT id, first_name, last_name, email, subject, phone_number,
               role, is_active, created_at, count(*) OVER () AS total_count
        FROM public.teachers ORDER BY id
        LIMIT p_page_size OFFSET ((p_page_number::bigint - 1) * p_page_size)
    ) result;
END;
$$;
