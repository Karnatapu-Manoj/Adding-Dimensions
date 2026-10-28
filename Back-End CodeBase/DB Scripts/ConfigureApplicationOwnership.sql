-- Administrator-only setup for this dedicated local development database.
-- Assign application objects to the dedicated non-superuser application owner.
DO $ownership$
DECLARE
    target_object record;
BEGIN
    IF current_database() <> 'adding_dimensions' THEN
        RAISE EXCEPTION 'This script may run only in the adding_dimensions database.';
    END IF;
    FOR target_object IN
        SELECT tablename FROM pg_tables WHERE schemaname = 'public'
    LOOP
        EXECUTE format('ALTER TABLE public.%I OWNER TO adding_dimensions', target_object.tablename);
    END LOOP;
    FOR target_object IN
        SELECT p.oid::regprocedure AS signature
        FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE n.nspname = 'public' AND p.prokind IN ('p', 'f')
    LOOP
        EXECUTE format('ALTER ROUTINE %s OWNER TO adding_dimensions', target_object.signature);
    END LOOP;
END;
$ownership$;
