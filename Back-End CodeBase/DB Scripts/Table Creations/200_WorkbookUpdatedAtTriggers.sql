-- The workbook requires updated_at to be maintained on UPDATE.
CREATE OR REPLACE FUNCTION public.trg_set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$function$;

DO $migration$
DECLARE
    target_table record;
BEGIN
    FOR target_table IN
        SELECT table_name FROM information_schema.columns
        WHERE table_schema = 'public' AND column_name = 'updated_at'
    LOOP
        EXECUTE format('CREATE OR REPLACE TRIGGER trg_set_updated_at BEFORE UPDATE ON public.%I '
                       'FOR EACH ROW EXECUTE FUNCTION public.trg_set_updated_at()', target_table.table_name);
    END LOOP;
END;
$migration$;
