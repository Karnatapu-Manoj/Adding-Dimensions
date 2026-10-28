-- Source: design thinking Db and partition.xlsx / Data Dictionary
CREATE TABLE IF NOT EXISTS public.role_permission
(
    role_permission_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    role_id SMALLINT NOT NULL,
    module_id SMALLINT NOT NULL,
    can_view BOOLEAN DEFAULT false NOT NULL,
    can_create BOOLEAN DEFAULT false NOT NULL,
    can_edit BOOLEAN DEFAULT false NOT NULL,
    can_delete BOOLEAN DEFAULT false NOT NULL,
    can_approve BOOLEAN DEFAULT false NOT NULL,
    can_export BOOLEAN DEFAULT false NOT NULL,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    created_by BIGINT,
    updated_at TIMESTAMPTZ,
    updated_by BIGINT
);
