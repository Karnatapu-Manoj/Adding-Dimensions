-- Workbook foreign keys. Applied after every workbook table exists.

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.m_role'::regclass
                   AND conname = 'fk_m_role_created_by') THEN
        ALTER TABLE public.m_role ADD CONSTRAINT fk_m_role_created_by
            FOREIGN KEY (created_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_m_role_created_by ON public.m_role (created_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.m_role'::regclass
                   AND conname = 'fk_m_role_updated_by') THEN
        ALTER TABLE public.m_role ADD CONSTRAINT fk_m_role_updated_by
            FOREIGN KEY (updated_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_m_role_updated_by ON public.m_role (updated_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.m_module'::regclass
                   AND conname = 'fk_m_module_created_by') THEN
        ALTER TABLE public.m_module ADD CONSTRAINT fk_m_module_created_by
            FOREIGN KEY (created_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_m_module_created_by ON public.m_module (created_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.m_module'::regclass
                   AND conname = 'fk_m_module_updated_by') THEN
        ALTER TABLE public.m_module ADD CONSTRAINT fk_m_module_updated_by
            FOREIGN KEY (updated_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_m_module_updated_by ON public.m_module (updated_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.role_permission'::regclass
                   AND conname = 'fk_role_permission_role_id') THEN
        ALTER TABLE public.role_permission ADD CONSTRAINT fk_role_permission_role_id
            FOREIGN KEY (role_id) REFERENCES public.m_role (role_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_role_permission_role_id ON public.role_permission (role_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.role_permission'::regclass
                   AND conname = 'fk_role_permission_module_id') THEN
        ALTER TABLE public.role_permission ADD CONSTRAINT fk_role_permission_module_id
            FOREIGN KEY (module_id) REFERENCES public.m_module (module_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_role_permission_module_id ON public.role_permission (module_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.role_permission'::regclass
                   AND conname = 'fk_role_permission_created_by') THEN
        ALTER TABLE public.role_permission ADD CONSTRAINT fk_role_permission_created_by
            FOREIGN KEY (created_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_role_permission_created_by ON public.role_permission (created_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.role_permission'::regclass
                   AND conname = 'fk_role_permission_updated_by') THEN
        ALTER TABLE public.role_permission ADD CONSTRAINT fk_role_permission_updated_by
            FOREIGN KEY (updated_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_role_permission_updated_by ON public.role_permission (updated_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.m_stakeholder'::regclass
                   AND conname = 'fk_m_stakeholder_created_by') THEN
        ALTER TABLE public.m_stakeholder ADD CONSTRAINT fk_m_stakeholder_created_by
            FOREIGN KEY (created_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_m_stakeholder_created_by ON public.m_stakeholder (created_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.m_stakeholder'::regclass
                   AND conname = 'fk_m_stakeholder_updated_by') THEN
        ALTER TABLE public.m_stakeholder ADD CONSTRAINT fk_m_stakeholder_updated_by
            FOREIGN KEY (updated_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_m_stakeholder_updated_by ON public.m_stakeholder (updated_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.role_creation_rule'::regclass
                   AND conname = 'fk_role_creation_rule_creator_role_id') THEN
        ALTER TABLE public.role_creation_rule ADD CONSTRAINT fk_role_creation_rule_creator_role_id
            FOREIGN KEY (creator_role_id) REFERENCES public.m_role (role_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_role_creation_rule_creator_role_id ON public.role_creation_rule (creator_role_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.role_creation_rule'::regclass
                   AND conname = 'fk_role_creation_rule_creatable_role_id') THEN
        ALTER TABLE public.role_creation_rule ADD CONSTRAINT fk_role_creation_rule_creatable_role_id
            FOREIGN KEY (creatable_role_id) REFERENCES public.m_role (role_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_role_creation_rule_creatable_role_id ON public.role_creation_rule (creatable_role_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.role_creation_rule'::regclass
                   AND conname = 'fk_role_creation_rule_created_by') THEN
        ALTER TABLE public.role_creation_rule ADD CONSTRAINT fk_role_creation_rule_created_by
            FOREIGN KEY (created_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_role_creation_rule_created_by ON public.role_creation_rule (created_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.role_creation_rule'::regclass
                   AND conname = 'fk_role_creation_rule_updated_by') THEN
        ALTER TABLE public.role_creation_rule ADD CONSTRAINT fk_role_creation_rule_updated_by
            FOREIGN KEY (updated_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_role_creation_rule_updated_by ON public.role_creation_rule (updated_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.app_user'::regclass
                   AND conname = 'fk_app_user_role_id') THEN
        ALTER TABLE public.app_user ADD CONSTRAINT fk_app_user_role_id
            FOREIGN KEY (role_id) REFERENCES public.m_role (role_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_app_user_role_id ON public.app_user (role_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.app_user'::regclass
                   AND conname = 'fk_app_user_stakeholder_id') THEN
        ALTER TABLE public.app_user ADD CONSTRAINT fk_app_user_stakeholder_id
            FOREIGN KEY (stakeholder_id) REFERENCES public.m_stakeholder (stakeholder_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_app_user_stakeholder_id ON public.app_user (stakeholder_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.app_user'::regclass
                   AND conname = 'fk_app_user_parent_user_id') THEN
        ALTER TABLE public.app_user ADD CONSTRAINT fk_app_user_parent_user_id
            FOREIGN KEY (parent_user_id) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_app_user_parent_user_id ON public.app_user (parent_user_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.app_user'::regclass
                   AND conname = 'fk_app_user_trainer_id') THEN
        ALTER TABLE public.app_user ADD CONSTRAINT fk_app_user_trainer_id
            FOREIGN KEY (trainer_id) REFERENCES public.trainer (trainer_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_app_user_trainer_id ON public.app_user (trainer_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.app_user'::regclass
                   AND conname = 'fk_app_user_trainee_id') THEN
        ALTER TABLE public.app_user ADD CONSTRAINT fk_app_user_trainee_id
            FOREIGN KEY (trainee_id) REFERENCES public.trainee (trainee_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_app_user_trainee_id ON public.app_user (trainee_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.app_user'::regclass
                   AND conname = 'fk_app_user_created_by') THEN
        ALTER TABLE public.app_user ADD CONSTRAINT fk_app_user_created_by
            FOREIGN KEY (created_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_app_user_created_by ON public.app_user (created_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.app_user'::regclass
                   AND conname = 'fk_app_user_updated_by') THEN
        ALTER TABLE public.app_user ADD CONSTRAINT fk_app_user_updated_by
            FOREIGN KEY (updated_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_app_user_updated_by ON public.app_user (updated_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.m_state'::regclass
                   AND conname = 'fk_m_state_created_by') THEN
        ALTER TABLE public.m_state ADD CONSTRAINT fk_m_state_created_by
            FOREIGN KEY (created_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_m_state_created_by ON public.m_state (created_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.m_state'::regclass
                   AND conname = 'fk_m_state_updated_by') THEN
        ALTER TABLE public.m_state ADD CONSTRAINT fk_m_state_updated_by
            FOREIGN KEY (updated_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_m_state_updated_by ON public.m_state (updated_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.m_district'::regclass
                   AND conname = 'fk_m_district_state_id') THEN
        ALTER TABLE public.m_district ADD CONSTRAINT fk_m_district_state_id
            FOREIGN KEY (state_id) REFERENCES public.m_state (state_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_m_district_state_id ON public.m_district (state_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.m_district'::regclass
                   AND conname = 'fk_m_district_created_by') THEN
        ALTER TABLE public.m_district ADD CONSTRAINT fk_m_district_created_by
            FOREIGN KEY (created_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_m_district_created_by ON public.m_district (created_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.m_district'::regclass
                   AND conname = 'fk_m_district_updated_by') THEN
        ALTER TABLE public.m_district ADD CONSTRAINT fk_m_district_updated_by
            FOREIGN KEY (updated_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_m_district_updated_by ON public.m_district (updated_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.m_block'::regclass
                   AND conname = 'fk_m_block_district_id') THEN
        ALTER TABLE public.m_block ADD CONSTRAINT fk_m_block_district_id
            FOREIGN KEY (district_id) REFERENCES public.m_district (district_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_m_block_district_id ON public.m_block (district_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.m_block'::regclass
                   AND conname = 'fk_m_block_created_by') THEN
        ALTER TABLE public.m_block ADD CONSTRAINT fk_m_block_created_by
            FOREIGN KEY (created_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_m_block_created_by ON public.m_block (created_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.m_block'::regclass
                   AND conname = 'fk_m_block_updated_by') THEN
        ALTER TABLE public.m_block ADD CONSTRAINT fk_m_block_updated_by
            FOREIGN KEY (updated_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_m_block_updated_by ON public.m_block (updated_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.m_cluster'::regclass
                   AND conname = 'fk_m_cluster_district_id') THEN
        ALTER TABLE public.m_cluster ADD CONSTRAINT fk_m_cluster_district_id
            FOREIGN KEY (district_id) REFERENCES public.m_district (district_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_m_cluster_district_id ON public.m_cluster (district_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.m_cluster'::regclass
                   AND conname = 'fk_m_cluster_block_id') THEN
        ALTER TABLE public.m_cluster ADD CONSTRAINT fk_m_cluster_block_id
            FOREIGN KEY (block_id) REFERENCES public.m_block (block_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_m_cluster_block_id ON public.m_cluster (block_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.m_cluster'::regclass
                   AND conname = 'fk_m_cluster_created_by') THEN
        ALTER TABLE public.m_cluster ADD CONSTRAINT fk_m_cluster_created_by
            FOREIGN KEY (created_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_m_cluster_created_by ON public.m_cluster (created_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.m_cluster'::regclass
                   AND conname = 'fk_m_cluster_updated_by') THEN
        ALTER TABLE public.m_cluster ADD CONSTRAINT fk_m_cluster_updated_by
            FOREIGN KEY (updated_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_m_cluster_updated_by ON public.m_cluster (updated_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.user_access_scope'::regclass
                   AND conname = 'fk_user_access_scope_user_id') THEN
        ALTER TABLE public.user_access_scope ADD CONSTRAINT fk_user_access_scope_user_id
            FOREIGN KEY (user_id) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_user_access_scope_user_id ON public.user_access_scope (user_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.user_access_scope'::regclass
                   AND conname = 'fk_user_access_scope_project_id') THEN
        ALTER TABLE public.user_access_scope ADD CONSTRAINT fk_user_access_scope_project_id
            FOREIGN KEY (project_id) REFERENCES public.project (project_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_user_access_scope_project_id ON public.user_access_scope (project_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.user_access_scope'::regclass
                   AND conname = 'fk_user_access_scope_state_id') THEN
        ALTER TABLE public.user_access_scope ADD CONSTRAINT fk_user_access_scope_state_id
            FOREIGN KEY (state_id) REFERENCES public.m_state (state_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_user_access_scope_state_id ON public.user_access_scope (state_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.user_access_scope'::regclass
                   AND conname = 'fk_user_access_scope_district_id') THEN
        ALTER TABLE public.user_access_scope ADD CONSTRAINT fk_user_access_scope_district_id
            FOREIGN KEY (district_id) REFERENCES public.m_district (district_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_user_access_scope_district_id ON public.user_access_scope (district_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.user_access_scope'::regclass
                   AND conname = 'fk_user_access_scope_block_id') THEN
        ALTER TABLE public.user_access_scope ADD CONSTRAINT fk_user_access_scope_block_id
            FOREIGN KEY (block_id) REFERENCES public.m_block (block_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_user_access_scope_block_id ON public.user_access_scope (block_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.user_access_scope'::regclass
                   AND conname = 'fk_user_access_scope_cluster_id') THEN
        ALTER TABLE public.user_access_scope ADD CONSTRAINT fk_user_access_scope_cluster_id
            FOREIGN KEY (cluster_id) REFERENCES public.m_cluster (cluster_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_user_access_scope_cluster_id ON public.user_access_scope (cluster_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.user_access_scope'::regclass
                   AND conname = 'fk_user_access_scope_school_id') THEN
        ALTER TABLE public.user_access_scope ADD CONSTRAINT fk_user_access_scope_school_id
            FOREIGN KEY (school_id) REFERENCES public.m_school (school_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_user_access_scope_school_id ON public.user_access_scope (school_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.user_access_scope'::regclass
                   AND conname = 'fk_user_access_scope_created_by') THEN
        ALTER TABLE public.user_access_scope ADD CONSTRAINT fk_user_access_scope_created_by
            FOREIGN KEY (created_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_user_access_scope_created_by ON public.user_access_scope (created_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.user_access_scope'::regclass
                   AND conname = 'fk_user_access_scope_updated_by') THEN
        ALTER TABLE public.user_access_scope ADD CONSTRAINT fk_user_access_scope_updated_by
            FOREIGN KEY (updated_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_user_access_scope_updated_by ON public.user_access_scope (updated_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.m_school'::regclass
                   AND conname = 'fk_m_school_state_id') THEN
        ALTER TABLE public.m_school ADD CONSTRAINT fk_m_school_state_id
            FOREIGN KEY (state_id) REFERENCES public.m_state (state_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_m_school_state_id ON public.m_school (state_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.m_school'::regclass
                   AND conname = 'fk_m_school_district_id') THEN
        ALTER TABLE public.m_school ADD CONSTRAINT fk_m_school_district_id
            FOREIGN KEY (district_id) REFERENCES public.m_district (district_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_m_school_district_id ON public.m_school (district_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.m_school'::regclass
                   AND conname = 'fk_m_school_block_id') THEN
        ALTER TABLE public.m_school ADD CONSTRAINT fk_m_school_block_id
            FOREIGN KEY (block_id) REFERENCES public.m_block (block_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_m_school_block_id ON public.m_school (block_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.m_school'::regclass
                   AND conname = 'fk_m_school_cluster_id') THEN
        ALTER TABLE public.m_school ADD CONSTRAINT fk_m_school_cluster_id
            FOREIGN KEY (cluster_id) REFERENCES public.m_cluster (cluster_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_m_school_cluster_id ON public.m_school (cluster_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.m_school'::regclass
                   AND conname = 'fk_m_school_created_by') THEN
        ALTER TABLE public.m_school ADD CONSTRAINT fk_m_school_created_by
            FOREIGN KEY (created_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_m_school_created_by ON public.m_school (created_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.m_school'::regclass
                   AND conname = 'fk_m_school_updated_by') THEN
        ALTER TABLE public.m_school ADD CONSTRAINT fk_m_school_updated_by
            FOREIGN KEY (updated_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_m_school_updated_by ON public.m_school (updated_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.m_holiday'::regclass
                   AND conname = 'fk_m_holiday_state_id') THEN
        ALTER TABLE public.m_holiday ADD CONSTRAINT fk_m_holiday_state_id
            FOREIGN KEY (state_id) REFERENCES public.m_state (state_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_m_holiday_state_id ON public.m_holiday (state_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.m_holiday'::regclass
                   AND conname = 'fk_m_holiday_district_id') THEN
        ALTER TABLE public.m_holiday ADD CONSTRAINT fk_m_holiday_district_id
            FOREIGN KEY (district_id) REFERENCES public.m_district (district_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_m_holiday_district_id ON public.m_holiday (district_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.m_holiday'::regclass
                   AND conname = 'fk_m_holiday_project_id') THEN
        ALTER TABLE public.m_holiday ADD CONSTRAINT fk_m_holiday_project_id
            FOREIGN KEY (project_id) REFERENCES public.project (project_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_m_holiday_project_id ON public.m_holiday (project_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.m_holiday'::regclass
                   AND conname = 'fk_m_holiday_created_by') THEN
        ALTER TABLE public.m_holiday ADD CONSTRAINT fk_m_holiday_created_by
            FOREIGN KEY (created_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_m_holiday_created_by ON public.m_holiday (created_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.m_holiday'::regclass
                   AND conname = 'fk_m_holiday_updated_by') THEN
        ALTER TABLE public.m_holiday ADD CONSTRAINT fk_m_holiday_updated_by
            FOREIGN KEY (updated_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_m_holiday_updated_by ON public.m_holiday (updated_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.trainer'::regclass
                   AND conname = 'fk_trainer_created_by') THEN
        ALTER TABLE public.trainer ADD CONSTRAINT fk_trainer_created_by
            FOREIGN KEY (created_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_trainer_created_by ON public.trainer (created_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.trainer'::regclass
                   AND conname = 'fk_trainer_updated_by') THEN
        ALTER TABLE public.trainer ADD CONSTRAINT fk_trainer_updated_by
            FOREIGN KEY (updated_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_trainer_updated_by ON public.trainer (updated_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.trainer_availability'::regclass
                   AND conname = 'fk_trainer_availability_trainer_id') THEN
        ALTER TABLE public.trainer_availability ADD CONSTRAINT fk_trainer_availability_trainer_id
            FOREIGN KEY (trainer_id) REFERENCES public.trainer (trainer_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_trainer_availability_trainer_id ON public.trainer_availability (trainer_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.trainer_availability'::regclass
                   AND conname = 'fk_trainer_availability_created_by') THEN
        ALTER TABLE public.trainer_availability ADD CONSTRAINT fk_trainer_availability_created_by
            FOREIGN KEY (created_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_trainer_availability_created_by ON public.trainer_availability (created_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.trainer_availability'::regclass
                   AND conname = 'fk_trainer_availability_updated_by') THEN
        ALTER TABLE public.trainer_availability ADD CONSTRAINT fk_trainer_availability_updated_by
            FOREIGN KEY (updated_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_trainer_availability_updated_by ON public.trainer_availability (updated_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.project'::regclass
                   AND conname = 'fk_project_stakeholder_id') THEN
        ALTER TABLE public.project ADD CONSTRAINT fk_project_stakeholder_id
            FOREIGN KEY (stakeholder_id) REFERENCES public.m_stakeholder (stakeholder_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_project_stakeholder_id ON public.project (stakeholder_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.project'::regclass
                   AND conname = 'fk_project_created_by') THEN
        ALTER TABLE public.project ADD CONSTRAINT fk_project_created_by
            FOREIGN KEY (created_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_project_created_by ON public.project (created_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.project'::regclass
                   AND conname = 'fk_project_updated_by') THEN
        ALTER TABLE public.project ADD CONSTRAINT fk_project_updated_by
            FOREIGN KEY (updated_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_project_updated_by ON public.project (updated_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.system_setting'::regclass
                   AND conname = 'fk_system_setting_project_id') THEN
        ALTER TABLE public.system_setting ADD CONSTRAINT fk_system_setting_project_id
            FOREIGN KEY (project_id) REFERENCES public.project (project_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_system_setting_project_id ON public.system_setting (project_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.system_setting'::regclass
                   AND conname = 'fk_system_setting_created_by') THEN
        ALTER TABLE public.system_setting ADD CONSTRAINT fk_system_setting_created_by
            FOREIGN KEY (created_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_system_setting_created_by ON public.system_setting (created_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.system_setting'::regclass
                   AND conname = 'fk_system_setting_updated_by') THEN
        ALTER TABLE public.system_setting ADD CONSTRAINT fk_system_setting_updated_by
            FOREIGN KEY (updated_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_system_setting_updated_by ON public.system_setting (updated_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.training_plan'::regclass
                   AND conname = 'fk_training_plan_project_id') THEN
        ALTER TABLE public.training_plan ADD CONSTRAINT fk_training_plan_project_id
            FOREIGN KEY (project_id) REFERENCES public.project (project_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_training_plan_project_id ON public.training_plan (project_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.training_plan'::regclass
                   AND conname = 'fk_training_plan_created_by') THEN
        ALTER TABLE public.training_plan ADD CONSTRAINT fk_training_plan_created_by
            FOREIGN KEY (created_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_training_plan_created_by ON public.training_plan (created_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.training_plan'::regclass
                   AND conname = 'fk_training_plan_updated_by') THEN
        ALTER TABLE public.training_plan ADD CONSTRAINT fk_training_plan_updated_by
            FOREIGN KEY (updated_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_training_plan_updated_by ON public.training_plan (updated_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.training_plan_day'::regclass
                   AND conname = 'fk_training_plan_day_plan_id') THEN
        ALTER TABLE public.training_plan_day ADD CONSTRAINT fk_training_plan_day_plan_id
            FOREIGN KEY (plan_id) REFERENCES public.training_plan (plan_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_training_plan_day_plan_id ON public.training_plan_day (plan_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.training_plan_day'::regclass
                   AND conname = 'fk_training_plan_day_created_by') THEN
        ALTER TABLE public.training_plan_day ADD CONSTRAINT fk_training_plan_day_created_by
            FOREIGN KEY (created_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_training_plan_day_created_by ON public.training_plan_day (created_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.training_plan_day'::regclass
                   AND conname = 'fk_training_plan_day_updated_by') THEN
        ALTER TABLE public.training_plan_day ADD CONSTRAINT fk_training_plan_day_updated_by
            FOREIGN KEY (updated_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_training_plan_day_updated_by ON public.training_plan_day (updated_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.training_plan_activity'::regclass
                   AND conname = 'fk_training_plan_activity_plan_day_id') THEN
        ALTER TABLE public.training_plan_activity ADD CONSTRAINT fk_training_plan_activity_plan_day_id
            FOREIGN KEY (plan_day_id) REFERENCES public.training_plan_day (plan_day_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_training_plan_activity_plan_day_id ON public.training_plan_activity (plan_day_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.training_plan_activity'::regclass
                   AND conname = 'fk_training_plan_activity_resource_id') THEN
        ALTER TABLE public.training_plan_activity ADD CONSTRAINT fk_training_plan_activity_resource_id
            FOREIGN KEY (resource_id) REFERENCES public.learning_resource (resource_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_training_plan_activity_resource_id ON public.training_plan_activity (resource_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.training_plan_activity'::regclass
                   AND conname = 'fk_training_plan_activity_created_by') THEN
        ALTER TABLE public.training_plan_activity ADD CONSTRAINT fk_training_plan_activity_created_by
            FOREIGN KEY (created_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_training_plan_activity_created_by ON public.training_plan_activity (created_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.training_plan_activity'::regclass
                   AND conname = 'fk_training_plan_activity_updated_by') THEN
        ALTER TABLE public.training_plan_activity ADD CONSTRAINT fk_training_plan_activity_updated_by
            FOREIGN KEY (updated_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_training_plan_activity_updated_by ON public.training_plan_activity (updated_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.learning_resource'::regclass
                   AND conname = 'fk_learning_resource_project_id') THEN
        ALTER TABLE public.learning_resource ADD CONSTRAINT fk_learning_resource_project_id
            FOREIGN KEY (project_id) REFERENCES public.project (project_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_learning_resource_project_id ON public.learning_resource (project_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.learning_resource'::regclass
                   AND conname = 'fk_learning_resource_uploaded_by') THEN
        ALTER TABLE public.learning_resource ADD CONSTRAINT fk_learning_resource_uploaded_by
            FOREIGN KEY (uploaded_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_learning_resource_uploaded_by ON public.learning_resource (uploaded_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.learning_resource'::regclass
                   AND conname = 'fk_learning_resource_created_by') THEN
        ALTER TABLE public.learning_resource ADD CONSTRAINT fk_learning_resource_created_by
            FOREIGN KEY (created_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_learning_resource_created_by ON public.learning_resource (created_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.learning_resource'::regclass
                   AND conname = 'fk_learning_resource_updated_by') THEN
        ALTER TABLE public.learning_resource ADD CONSTRAINT fk_learning_resource_updated_by
            FOREIGN KEY (updated_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_learning_resource_updated_by ON public.learning_resource (updated_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.form_question'::regclass
                   AND conname = 'fk_form_question_resource_id') THEN
        ALTER TABLE public.form_question ADD CONSTRAINT fk_form_question_resource_id
            FOREIGN KEY (resource_id) REFERENCES public.learning_resource (resource_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_form_question_resource_id ON public.form_question (resource_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.form_question'::regclass
                   AND conname = 'fk_form_question_created_by') THEN
        ALTER TABLE public.form_question ADD CONSTRAINT fk_form_question_created_by
            FOREIGN KEY (created_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_form_question_created_by ON public.form_question (created_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.form_question'::regclass
                   AND conname = 'fk_form_question_updated_by') THEN
        ALTER TABLE public.form_question ADD CONSTRAINT fk_form_question_updated_by
            FOREIGN KEY (updated_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_form_question_updated_by ON public.form_question (updated_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.plan_resource_link'::regclass
                   AND conname = 'fk_plan_resource_link_plan_id') THEN
        ALTER TABLE public.plan_resource_link ADD CONSTRAINT fk_plan_resource_link_plan_id
            FOREIGN KEY (plan_id) REFERENCES public.training_plan (plan_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_plan_resource_link_plan_id ON public.plan_resource_link (plan_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.plan_resource_link'::regclass
                   AND conname = 'fk_plan_resource_link_resource_id') THEN
        ALTER TABLE public.plan_resource_link ADD CONSTRAINT fk_plan_resource_link_resource_id
            FOREIGN KEY (resource_id) REFERENCES public.learning_resource (resource_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_plan_resource_link_resource_id ON public.plan_resource_link (resource_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.plan_resource_link'::regclass
                   AND conname = 'fk_plan_resource_link_project_id') THEN
        ALTER TABLE public.plan_resource_link ADD CONSTRAINT fk_plan_resource_link_project_id
            FOREIGN KEY (project_id) REFERENCES public.project (project_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_plan_resource_link_project_id ON public.plan_resource_link (project_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.plan_resource_link'::regclass
                   AND conname = 'fk_plan_resource_link_created_by') THEN
        ALTER TABLE public.plan_resource_link ADD CONSTRAINT fk_plan_resource_link_created_by
            FOREIGN KEY (created_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_plan_resource_link_created_by ON public.plan_resource_link (created_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.plan_resource_link'::regclass
                   AND conname = 'fk_plan_resource_link_updated_by') THEN
        ALTER TABLE public.plan_resource_link ADD CONSTRAINT fk_plan_resource_link_updated_by
            FOREIGN KEY (updated_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_plan_resource_link_updated_by ON public.plan_resource_link (updated_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.plan_resource_day'::regclass
                   AND conname = 'fk_plan_resource_day_link_id') THEN
        ALTER TABLE public.plan_resource_day ADD CONSTRAINT fk_plan_resource_day_link_id
            FOREIGN KEY (link_id) REFERENCES public.plan_resource_link (link_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_plan_resource_day_link_id ON public.plan_resource_day (link_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.resource_access_log'::regclass
                   AND conname = 'fk_resource_access_log_resource_id') THEN
        ALTER TABLE public.resource_access_log ADD CONSTRAINT fk_resource_access_log_resource_id
            FOREIGN KEY (resource_id) REFERENCES public.learning_resource (resource_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_resource_access_log_resource_id ON public.resource_access_log (resource_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.resource_access_log'::regclass
                   AND conname = 'fk_resource_access_log_user_id') THEN
        ALTER TABLE public.resource_access_log ADD CONSTRAINT fk_resource_access_log_user_id
            FOREIGN KEY (user_id) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_resource_access_log_user_id ON public.resource_access_log (user_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.resource_audience'::regclass
                   AND conname = 'fk_resource_audience_resource_id') THEN
        ALTER TABLE public.resource_audience ADD CONSTRAINT fk_resource_audience_resource_id
            FOREIGN KEY (resource_id) REFERENCES public.learning_resource (resource_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_resource_audience_resource_id ON public.resource_audience (resource_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.resource_audience'::regclass
                   AND conname = 'fk_resource_audience_batch_id') THEN
        ALTER TABLE public.resource_audience ADD CONSTRAINT fk_resource_audience_batch_id
            FOREIGN KEY (batch_id) REFERENCES public.training_batch (batch_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_resource_audience_batch_id ON public.resource_audience (batch_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.resource_audience'::regclass
                   AND conname = 'fk_resource_audience_trainee_id') THEN
        ALTER TABLE public.resource_audience ADD CONSTRAINT fk_resource_audience_trainee_id
            FOREIGN KEY (trainee_id) REFERENCES public.trainee (trainee_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_resource_audience_trainee_id ON public.resource_audience (trainee_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.resource_audience'::regclass
                   AND conname = 'fk_resource_audience_created_by') THEN
        ALTER TABLE public.resource_audience ADD CONSTRAINT fk_resource_audience_created_by
            FOREIGN KEY (created_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_resource_audience_created_by ON public.resource_audience (created_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.resource_audience'::regclass
                   AND conname = 'fk_resource_audience_updated_by') THEN
        ALTER TABLE public.resource_audience ADD CONSTRAINT fk_resource_audience_updated_by
            FOREIGN KEY (updated_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_resource_audience_updated_by ON public.resource_audience (updated_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.resource_progress'::regclass
                   AND conname = 'fk_resource_progress_trainee_id') THEN
        ALTER TABLE public.resource_progress ADD CONSTRAINT fk_resource_progress_trainee_id
            FOREIGN KEY (trainee_id) REFERENCES public.trainee (trainee_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_resource_progress_trainee_id ON public.resource_progress (trainee_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.resource_progress'::regclass
                   AND conname = 'fk_resource_progress_resource_id') THEN
        ALTER TABLE public.resource_progress ADD CONSTRAINT fk_resource_progress_resource_id
            FOREIGN KEY (resource_id) REFERENCES public.learning_resource (resource_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_resource_progress_resource_id ON public.resource_progress (resource_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.training_batch'::regclass
                   AND conname = 'fk_training_batch_project_id') THEN
        ALTER TABLE public.training_batch ADD CONSTRAINT fk_training_batch_project_id
            FOREIGN KEY (project_id) REFERENCES public.project (project_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_training_batch_project_id ON public.training_batch (project_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.training_batch'::regclass
                   AND conname = 'fk_training_batch_plan_id') THEN
        ALTER TABLE public.training_batch ADD CONSTRAINT fk_training_batch_plan_id
            FOREIGN KEY (plan_id) REFERENCES public.training_plan (plan_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_training_batch_plan_id ON public.training_batch (plan_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.training_batch'::regclass
                   AND conname = 'fk_training_batch_school_id') THEN
        ALTER TABLE public.training_batch ADD CONSTRAINT fk_training_batch_school_id
            FOREIGN KEY (school_id) REFERENCES public.m_school (school_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_training_batch_school_id ON public.training_batch (school_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.training_batch'::regclass
                   AND conname = 'fk_training_batch_trainer_id') THEN
        ALTER TABLE public.training_batch ADD CONSTRAINT fk_training_batch_trainer_id
            FOREIGN KEY (trainer_id) REFERENCES public.trainer (trainer_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_training_batch_trainer_id ON public.training_batch (trainer_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.training_batch'::regclass
                   AND conname = 'fk_training_batch_created_by') THEN
        ALTER TABLE public.training_batch ADD CONSTRAINT fk_training_batch_created_by
            FOREIGN KEY (created_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_training_batch_created_by ON public.training_batch (created_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.training_batch'::regclass
                   AND conname = 'fk_training_batch_updated_by') THEN
        ALTER TABLE public.training_batch ADD CONSTRAINT fk_training_batch_updated_by
            FOREIGN KEY (updated_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_training_batch_updated_by ON public.training_batch (updated_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.batch_day'::regclass
                   AND conname = 'fk_batch_day_batch_id') THEN
        ALTER TABLE public.batch_day ADD CONSTRAINT fk_batch_day_batch_id
            FOREIGN KEY (batch_id) REFERENCES public.training_batch (batch_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_batch_day_batch_id ON public.batch_day (batch_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.batch_day_activity'::regclass
                   AND conname = 'fk_batch_day_activity_batch_day_id') THEN
        ALTER TABLE public.batch_day_activity ADD CONSTRAINT fk_batch_day_activity_batch_day_id
            FOREIGN KEY (batch_day_id) REFERENCES public.batch_day (batch_day_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_batch_day_activity_batch_day_id ON public.batch_day_activity (batch_day_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.batch_day_activity'::regclass
                   AND conname = 'fk_batch_day_activity_resource_id') THEN
        ALTER TABLE public.batch_day_activity ADD CONSTRAINT fk_batch_day_activity_resource_id
            FOREIGN KEY (resource_id) REFERENCES public.learning_resource (resource_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_batch_day_activity_resource_id ON public.batch_day_activity (resource_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.trainee'::regclass
                   AND conname = 'fk_trainee_created_by') THEN
        ALTER TABLE public.trainee ADD CONSTRAINT fk_trainee_created_by
            FOREIGN KEY (created_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_trainee_created_by ON public.trainee (created_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.trainee'::regclass
                   AND conname = 'fk_trainee_updated_by') THEN
        ALTER TABLE public.trainee ADD CONSTRAINT fk_trainee_updated_by
            FOREIGN KEY (updated_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_trainee_updated_by ON public.trainee (updated_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.batch_enrollment'::regclass
                   AND conname = 'fk_batch_enrollment_batch_id') THEN
        ALTER TABLE public.batch_enrollment ADD CONSTRAINT fk_batch_enrollment_batch_id
            FOREIGN KEY (batch_id) REFERENCES public.training_batch (batch_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_batch_enrollment_batch_id ON public.batch_enrollment (batch_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.batch_enrollment'::regclass
                   AND conname = 'fk_batch_enrollment_trainee_id') THEN
        ALTER TABLE public.batch_enrollment ADD CONSTRAINT fk_batch_enrollment_trainee_id
            FOREIGN KEY (trainee_id) REFERENCES public.trainee (trainee_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_batch_enrollment_trainee_id ON public.batch_enrollment (trainee_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.batch_enrollment'::regclass
                   AND conname = 'fk_batch_enrollment_registration_link_id') THEN
        ALTER TABLE public.batch_enrollment ADD CONSTRAINT fk_batch_enrollment_registration_link_id
            FOREIGN KEY (registration_link_id) REFERENCES public.batch_registration_link (link_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_batch_enrollment_registration_link_id ON public.batch_enrollment (registration_link_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.batch_enrollment'::regclass
                   AND conname = 'fk_batch_enrollment_trainee_school_id') THEN
        ALTER TABLE public.batch_enrollment ADD CONSTRAINT fk_batch_enrollment_trainee_school_id
            FOREIGN KEY (trainee_school_id) REFERENCES public.m_school (school_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_batch_enrollment_trainee_school_id ON public.batch_enrollment (trainee_school_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.batch_enrollment'::regclass
                   AND conname = 'fk_batch_enrollment_trainee_state_id') THEN
        ALTER TABLE public.batch_enrollment ADD CONSTRAINT fk_batch_enrollment_trainee_state_id
            FOREIGN KEY (trainee_state_id) REFERENCES public.m_state (state_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_batch_enrollment_trainee_state_id ON public.batch_enrollment (trainee_state_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.batch_enrollment'::regclass
                   AND conname = 'fk_batch_enrollment_trainee_district_id') THEN
        ALTER TABLE public.batch_enrollment ADD CONSTRAINT fk_batch_enrollment_trainee_district_id
            FOREIGN KEY (trainee_district_id) REFERENCES public.m_district (district_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_batch_enrollment_trainee_district_id ON public.batch_enrollment (trainee_district_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.batch_enrollment'::regclass
                   AND conname = 'fk_batch_enrollment_trainee_block_id') THEN
        ALTER TABLE public.batch_enrollment ADD CONSTRAINT fk_batch_enrollment_trainee_block_id
            FOREIGN KEY (trainee_block_id) REFERENCES public.m_block (block_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_batch_enrollment_trainee_block_id ON public.batch_enrollment (trainee_block_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.batch_enrollment'::regclass
                   AND conname = 'fk_batch_enrollment_trainee_cluster_id') THEN
        ALTER TABLE public.batch_enrollment ADD CONSTRAINT fk_batch_enrollment_trainee_cluster_id
            FOREIGN KEY (trainee_cluster_id) REFERENCES public.m_cluster (cluster_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_batch_enrollment_trainee_cluster_id ON public.batch_enrollment (trainee_cluster_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.batch_enrollment'::regclass
                   AND conname = 'fk_batch_enrollment_approved_by') THEN
        ALTER TABLE public.batch_enrollment ADD CONSTRAINT fk_batch_enrollment_approved_by
            FOREIGN KEY (approved_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_batch_enrollment_approved_by ON public.batch_enrollment (approved_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.batch_enrollment'::regclass
                   AND conname = 'fk_batch_enrollment_created_by') THEN
        ALTER TABLE public.batch_enrollment ADD CONSTRAINT fk_batch_enrollment_created_by
            FOREIGN KEY (created_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_batch_enrollment_created_by ON public.batch_enrollment (created_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.batch_enrollment'::regclass
                   AND conname = 'fk_batch_enrollment_updated_by') THEN
        ALTER TABLE public.batch_enrollment ADD CONSTRAINT fk_batch_enrollment_updated_by
            FOREIGN KEY (updated_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_batch_enrollment_updated_by ON public.batch_enrollment (updated_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.batch_registration_link'::regclass
                   AND conname = 'fk_batch_registration_link_batch_id') THEN
        ALTER TABLE public.batch_registration_link ADD CONSTRAINT fk_batch_registration_link_batch_id
            FOREIGN KEY (batch_id) REFERENCES public.training_batch (batch_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_batch_registration_link_batch_id ON public.batch_registration_link (batch_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.batch_registration_link'::regclass
                   AND conname = 'fk_batch_registration_link_created_by') THEN
        ALTER TABLE public.batch_registration_link ADD CONSTRAINT fk_batch_registration_link_created_by
            FOREIGN KEY (created_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_batch_registration_link_created_by ON public.batch_registration_link (created_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.batch_registration_link'::regclass
                   AND conname = 'fk_batch_registration_link_updated_by') THEN
        ALTER TABLE public.batch_registration_link ADD CONSTRAINT fk_batch_registration_link_updated_by
            FOREIGN KEY (updated_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_batch_registration_link_updated_by ON public.batch_registration_link (updated_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.registration_otp'::regclass
                   AND conname = 'fk_registration_otp_batch_id') THEN
        ALTER TABLE public.registration_otp ADD CONSTRAINT fk_registration_otp_batch_id
            FOREIGN KEY (batch_id) REFERENCES public.training_batch (batch_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_registration_otp_batch_id ON public.registration_otp (batch_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.bulk_upload_log'::regclass
                   AND conname = 'fk_bulk_upload_log_project_id') THEN
        ALTER TABLE public.bulk_upload_log ADD CONSTRAINT fk_bulk_upload_log_project_id
            FOREIGN KEY (project_id) REFERENCES public.project (project_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_bulk_upload_log_project_id ON public.bulk_upload_log (project_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.bulk_upload_log'::regclass
                   AND conname = 'fk_bulk_upload_log_batch_id') THEN
        ALTER TABLE public.bulk_upload_log ADD CONSTRAINT fk_bulk_upload_log_batch_id
            FOREIGN KEY (batch_id) REFERENCES public.training_batch (batch_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_bulk_upload_log_batch_id ON public.bulk_upload_log (batch_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.bulk_upload_log'::regclass
                   AND conname = 'fk_bulk_upload_log_uploaded_by') THEN
        ALTER TABLE public.bulk_upload_log ADD CONSTRAINT fk_bulk_upload_log_uploaded_by
            FOREIGN KEY (uploaded_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_bulk_upload_log_uploaded_by ON public.bulk_upload_log (uploaded_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.attendance'::regclass
                   AND conname = 'fk_attendance_enrollment_id') THEN
        ALTER TABLE public.attendance ADD CONSTRAINT fk_attendance_enrollment_id
            FOREIGN KEY (enrollment_id) REFERENCES public.batch_enrollment (enrollment_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_attendance_enrollment_id ON public.attendance (enrollment_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.attendance'::regclass
                   AND conname = 'fk_attendance_marked_by') THEN
        ALTER TABLE public.attendance ADD CONSTRAINT fk_attendance_marked_by
            FOREIGN KEY (marked_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_attendance_marked_by ON public.attendance (marked_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.attendance'::regclass
                   AND conname = 'fk_attendance_updated_by') THEN
        ALTER TABLE public.attendance ADD CONSTRAINT fk_attendance_updated_by
            FOREIGN KEY (updated_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_attendance_updated_by ON public.attendance (updated_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.form_submission'::regclass
                   AND conname = 'fk_form_submission_enrollment_id') THEN
        ALTER TABLE public.form_submission ADD CONSTRAINT fk_form_submission_enrollment_id
            FOREIGN KEY (enrollment_id) REFERENCES public.batch_enrollment (enrollment_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_form_submission_enrollment_id ON public.form_submission (enrollment_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.form_submission'::regclass
                   AND conname = 'fk_form_submission_question_id') THEN
        ALTER TABLE public.form_submission ADD CONSTRAINT fk_form_submission_question_id
            FOREIGN KEY (question_id) REFERENCES public.form_question (question_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_form_submission_question_id ON public.form_submission (question_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.completion_review'::regclass
                   AND conname = 'fk_completion_review_enrollment_id') THEN
        ALTER TABLE public.completion_review ADD CONSTRAINT fk_completion_review_enrollment_id
            FOREIGN KEY (enrollment_id) REFERENCES public.batch_enrollment (enrollment_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_completion_review_enrollment_id ON public.completion_review (enrollment_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.completion_review'::regclass
                   AND conname = 'fk_completion_review_reviewed_by') THEN
        ALTER TABLE public.completion_review ADD CONSTRAINT fk_completion_review_reviewed_by
            FOREIGN KEY (reviewed_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_completion_review_reviewed_by ON public.completion_review (reviewed_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.certificate_template'::regclass
                   AND conname = 'fk_certificate_template_project_id') THEN
        ALTER TABLE public.certificate_template ADD CONSTRAINT fk_certificate_template_project_id
            FOREIGN KEY (project_id) REFERENCES public.project (project_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_certificate_template_project_id ON public.certificate_template (project_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.certificate_template'::regclass
                   AND conname = 'fk_certificate_template_created_by') THEN
        ALTER TABLE public.certificate_template ADD CONSTRAINT fk_certificate_template_created_by
            FOREIGN KEY (created_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_certificate_template_created_by ON public.certificate_template (created_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.certificate_template'::regclass
                   AND conname = 'fk_certificate_template_updated_by') THEN
        ALTER TABLE public.certificate_template ADD CONSTRAINT fk_certificate_template_updated_by
            FOREIGN KEY (updated_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_certificate_template_updated_by ON public.certificate_template (updated_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.certificate_record'::regclass
                   AND conname = 'fk_certificate_record_enrollment_id') THEN
        ALTER TABLE public.certificate_record ADD CONSTRAINT fk_certificate_record_enrollment_id
            FOREIGN KEY (enrollment_id) REFERENCES public.batch_enrollment (enrollment_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_certificate_record_enrollment_id ON public.certificate_record (enrollment_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.certificate_record'::regclass
                   AND conname = 'fk_certificate_record_template_id') THEN
        ALTER TABLE public.certificate_record ADD CONSTRAINT fk_certificate_record_template_id
            FOREIGN KEY (template_id) REFERENCES public.certificate_template (template_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_certificate_record_template_id ON public.certificate_record (template_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.certificate_record'::regclass
                   AND conname = 'fk_certificate_record_issued_by') THEN
        ALTER TABLE public.certificate_record ADD CONSTRAINT fk_certificate_record_issued_by
            FOREIGN KEY (issued_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_certificate_record_issued_by ON public.certificate_record (issued_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.audit_log'::regclass
                   AND conname = 'fk_audit_log_actor_user_id') THEN
        ALTER TABLE public.audit_log ADD CONSTRAINT fk_audit_log_actor_user_id
            FOREIGN KEY (actor_user_id) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_audit_log_actor_user_id ON public.audit_log (actor_user_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.audit_log'::regclass
                   AND conname = 'fk_audit_log_project_id') THEN
        ALTER TABLE public.audit_log ADD CONSTRAINT fk_audit_log_project_id
            FOREIGN KEY (project_id) REFERENCES public.project (project_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_audit_log_project_id ON public.audit_log (project_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.user_activity_log'::regclass
                   AND conname = 'fk_user_activity_log_user_id') THEN
        ALTER TABLE public.user_activity_log ADD CONSTRAINT fk_user_activity_log_user_id
            FOREIGN KEY (user_id) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_user_activity_log_user_id ON public.user_activity_log (user_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.profile_change_log'::regclass
                   AND conname = 'fk_profile_change_log_user_id') THEN
        ALTER TABLE public.profile_change_log ADD CONSTRAINT fk_profile_change_log_user_id
            FOREIGN KEY (user_id) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_profile_change_log_user_id ON public.profile_change_log (user_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.m_pii_field'::regclass
                   AND conname = 'fk_m_pii_field_created_by') THEN
        ALTER TABLE public.m_pii_field ADD CONSTRAINT fk_m_pii_field_created_by
            FOREIGN KEY (created_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_m_pii_field_created_by ON public.m_pii_field (created_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.m_pii_field'::regclass
                   AND conname = 'fk_m_pii_field_updated_by') THEN
        ALTER TABLE public.m_pii_field ADD CONSTRAINT fk_m_pii_field_updated_by
            FOREIGN KEY (updated_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_m_pii_field_updated_by ON public.m_pii_field (updated_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.role_pii_permission'::regclass
                   AND conname = 'fk_role_pii_permission_role_id') THEN
        ALTER TABLE public.role_pii_permission ADD CONSTRAINT fk_role_pii_permission_role_id
            FOREIGN KEY (role_id) REFERENCES public.m_role (role_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_role_pii_permission_role_id ON public.role_pii_permission (role_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.role_pii_permission'::regclass
                   AND conname = 'fk_role_pii_permission_pii_field_id') THEN
        ALTER TABLE public.role_pii_permission ADD CONSTRAINT fk_role_pii_permission_pii_field_id
            FOREIGN KEY (pii_field_id) REFERENCES public.m_pii_field (pii_field_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_role_pii_permission_pii_field_id ON public.role_pii_permission (pii_field_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.role_pii_permission'::regclass
                   AND conname = 'fk_role_pii_permission_created_by') THEN
        ALTER TABLE public.role_pii_permission ADD CONSTRAINT fk_role_pii_permission_created_by
            FOREIGN KEY (created_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_role_pii_permission_created_by ON public.role_pii_permission (created_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.role_pii_permission'::regclass
                   AND conname = 'fk_role_pii_permission_updated_by') THEN
        ALTER TABLE public.role_pii_permission ADD CONSTRAINT fk_role_pii_permission_updated_by
            FOREIGN KEY (updated_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_role_pii_permission_updated_by ON public.role_pii_permission (updated_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.user_pii_override'::regclass
                   AND conname = 'fk_user_pii_override_user_id') THEN
        ALTER TABLE public.user_pii_override ADD CONSTRAINT fk_user_pii_override_user_id
            FOREIGN KEY (user_id) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_user_pii_override_user_id ON public.user_pii_override (user_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.user_pii_override'::regclass
                   AND conname = 'fk_user_pii_override_pii_field_id') THEN
        ALTER TABLE public.user_pii_override ADD CONSTRAINT fk_user_pii_override_pii_field_id
            FOREIGN KEY (pii_field_id) REFERENCES public.m_pii_field (pii_field_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_user_pii_override_pii_field_id ON public.user_pii_override (pii_field_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.user_pii_override'::regclass
                   AND conname = 'fk_user_pii_override_created_by') THEN
        ALTER TABLE public.user_pii_override ADD CONSTRAINT fk_user_pii_override_created_by
            FOREIGN KEY (created_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_user_pii_override_created_by ON public.user_pii_override (created_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.user_pii_override'::regclass
                   AND conname = 'fk_user_pii_override_updated_by') THEN
        ALTER TABLE public.user_pii_override ADD CONSTRAINT fk_user_pii_override_updated_by
            FOREIGN KEY (updated_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_user_pii_override_updated_by ON public.user_pii_override (updated_by);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.pii_access_log'::regclass
                   AND conname = 'fk_pii_access_log_user_id') THEN
        ALTER TABLE public.pii_access_log ADD CONSTRAINT fk_pii_access_log_user_id
            FOREIGN KEY (user_id) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_pii_access_log_user_id ON public.pii_access_log (user_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.pii_access_log'::regclass
                   AND conname = 'fk_pii_access_log_pii_field_id') THEN
        ALTER TABLE public.pii_access_log ADD CONSTRAINT fk_pii_access_log_pii_field_id
            FOREIGN KEY (pii_field_id) REFERENCES public.m_pii_field (pii_field_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_pii_access_log_pii_field_id ON public.pii_access_log (pii_field_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.consent_record'::regclass
                   AND conname = 'fk_consent_record_trainee_id') THEN
        ALTER TABLE public.consent_record ADD CONSTRAINT fk_consent_record_trainee_id
            FOREIGN KEY (trainee_id) REFERENCES public.trainee (trainee_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_consent_record_trainee_id ON public.consent_record (trainee_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.data_subject_request'::regclass
                   AND conname = 'fk_data_subject_request_trainee_id') THEN
        ALTER TABLE public.data_subject_request ADD CONSTRAINT fk_data_subject_request_trainee_id
            FOREIGN KEY (trainee_id) REFERENCES public.trainee (trainee_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_data_subject_request_trainee_id ON public.data_subject_request (trainee_id);

DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.data_subject_request'::regclass
                   AND conname = 'fk_data_subject_request_handled_by') THEN
        ALTER TABLE public.data_subject_request ADD CONSTRAINT fk_data_subject_request_handled_by
            FOREIGN KEY (handled_by) REFERENCES public.app_user (user_id);
    END IF;
END;
$migration$;
CREATE INDEX IF NOT EXISTS ix_data_subject_request_handled_by ON public.data_subject_request (handled_by);
