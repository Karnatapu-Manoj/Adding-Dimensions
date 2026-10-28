-- Manual local-test maintenance only. Never deployed by DeployLocalDatabase.py.
-- Keep business records and audit history; hide only the reserved TEST-* fixtures.
DO $block$
DECLARE target text;
BEGIN
    FOREACH target IN ARRAY ARRAY['project','training_plan','project_plan_association','training_batch',
        'batch_enrollment','attendance','assessment_attempt','learning_resource','certificate_record'] LOOP
        EXECUTE format('UPDATE public.%I SET portal_deleted=true,row_version=row_version+1 '
            'WHERE external_id LIKE ''TEST-%%'' AND NOT portal_deleted',target);
    END LOOP;
END;
$block$;
