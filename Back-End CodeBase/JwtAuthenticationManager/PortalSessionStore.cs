using System.Data;
using JwtAuthenticationManager.Utility;
using Microsoft.Extensions.Configuration;
using Npgsql;
using NpgsqlTypes;

namespace JwtAuthenticationManager
{
    public class PortalSessionStore
    {
        private readonly IConfiguration _configuration;
        public PortalSessionStore(IConfiguration configuration) { _configuration = configuration; }

        public async Task SaveSession(long userId, string tokenId, DateTime expiresAt, string role, CancellationToken ct)
        {
            List<NpgsqlParameter> sqlParams = Parameters(userId, tokenId);
            sqlParams.Add(new NpgsqlParameter("p_expires_at", NpgsqlDbType.TimestampTz) { Value = expiresAt });
            sqlParams.Add(new NpgsqlParameter("p_role", NpgsqlDbType.Varchar) { Value = role });
            await SqlHelper.ExecuteNonQuery(sqlParams, "public.usp_portal_save_session", ConnectionString, ct);
        }

        public async Task<bool> IsActive(long userId, string tokenId, CancellationToken ct)
        {
            using (DataTable dt = await SqlHelper.ExecuteDataTable(Parameters(userId, tokenId),
                "public.usp_portal_check_session", ConnectionString, ct))
            {
                return dt.Rows.Count > 0 && Convert.ToBoolean(dt.Rows[0]["is_active"]);
            }
        }

        public Task Logout(long userId, string tokenId, CancellationToken ct)
        {
            return SqlHelper.ExecuteNonQuery(Parameters(userId, tokenId), "public.usp_portal_revoke_session", ConnectionString, ct);
        }

        private string ConnectionString { get { return _configuration.GetConnectionString("DBConnection")!; } }
        private static List<NpgsqlParameter> Parameters(long userId, string tokenId)
        {
            return new List<NpgsqlParameter>
            {
                new NpgsqlParameter("p_user_id", NpgsqlDbType.Bigint) { Value = userId },
                new NpgsqlParameter("p_token_id", NpgsqlDbType.Varchar) { Value = tokenId }
            };
        }
    }
}
