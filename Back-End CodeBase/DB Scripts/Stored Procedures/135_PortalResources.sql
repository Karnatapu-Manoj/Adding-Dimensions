CREATE OR REPLACE PROCEDURE public.usp_portal_resource_access(IN p_user_id bigint,IN p_resource_id bigint,INOUT p_result jsonb DEFAULT NULL)
LANGUAGE plpgsql AS $procedure$
BEGIN
    INSERT INTO public.resource_access_log(resource_id,user_id) VALUES(p_resource_id,p_user_id);
    p_result:='[{"is_success":true}]';
END;
$procedure$;
