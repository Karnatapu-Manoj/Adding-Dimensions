-- Only the authentication service receives this password hash. It is never returned to clients.
CREATE OR REPLACE PROCEDURE public.usp_get_login_user
(
    IN p_email varchar,
    INOUT p_result jsonb DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT COALESCE(jsonb_agg(to_jsonb(result)), '[]'::jsonb) INTO p_result
    FROM
    (
        SELECT id, first_name, last_name, email, subject, phone_number,
               role, is_active, created_at, password_hash
        FROM public.teachers WHERE lower(email) = lower(trim(p_email))
    ) result;
END;
$$;
