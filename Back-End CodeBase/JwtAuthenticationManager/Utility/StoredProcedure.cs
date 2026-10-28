namespace JwtAuthenticationManager.Utility
{
    public static class StoredProcedure
    {
        public const string USP_GetTeachersList = "public.usp_get_teachers_list";
        public const string USP_GetTeacherById = "public.usp_get_teacher_by_id";
        public const string USP_GetLoginUser = "public.usp_get_login_user";
        public const string USP_SaveTeacher = "public.usp_save_teacher";
        public const string USP_UpdateTeacher = "public.usp_update_teacher";
        public const string USP_DeleteTeacher = "public.usp_delete_teacher";
        public const string USP_SaveAuthToken = "public.usp_save_auth_token";
        public const string USP_GetUserAuthToken = "public.usp_get_user_auth_token";
        public const string USP_RevokeAuthToken = "public.usp_revoke_auth_token";
        public const string USP_CheckDatabaseHealth = "public.usp_check_database_health";
    }
}
