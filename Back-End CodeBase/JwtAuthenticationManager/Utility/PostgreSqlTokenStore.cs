using System.Data;
using Microsoft.Extensions.Configuration;
using Npgsql;
using NpgsqlTypes;

namespace JwtAuthenticationManager.Utility
{
    public class PostgreSqlTokenStore
    {
        private readonly IConfiguration _configuration;

        public PostgreSqlTokenStore(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        public async Task SaveAsync(int teacherId, string tokenId, DateTime expiresAt, CancellationToken cancellationToken)
        {
            string connectionString = _configuration.GetConnectionString("DBConnection")!;
            List<NpgsqlParameter> sqlParams = new List<NpgsqlParameter>
            {
                new NpgsqlParameter("p_teacher_id", NpgsqlDbType.Integer) { Value = teacherId },
                new NpgsqlParameter("p_token_id", NpgsqlDbType.Varchar) { Value = tokenId },
                new NpgsqlParameter("p_expires_at", NpgsqlDbType.TimestampTz) { Value = expiresAt }
            };
            await SqlHelper.ExecuteNonQuery(sqlParams, StoredProcedure.USP_SaveAuthToken, connectionString, cancellationToken);
        }

        public async Task<bool> IsActiveAsync(int teacherId, string tokenId, CancellationToken cancellationToken)
        {
            string connectionString = _configuration.GetConnectionString("DBConnection")!;
            List<NpgsqlParameter> sqlParams = new List<NpgsqlParameter>
            {
                new NpgsqlParameter("p_teacher_id", NpgsqlDbType.Integer) { Value = teacherId },
                new NpgsqlParameter("p_token_id", NpgsqlDbType.Varchar) { Value = tokenId }
            };
            using (DataTable dt = await SqlHelper.ExecuteDataTable(sqlParams, StoredProcedure.USP_GetUserAuthToken,
                connectionString, cancellationToken))
            {
                return dt.Rows.Count > 0 && Convert.ToBoolean(dt.Rows[0]["is_active"]);
            }
        }

        public async Task RevokeAsync(int teacherId, string tokenId, CancellationToken cancellationToken)
        {
            string connectionString = _configuration.GetConnectionString("DBConnection")!;
            List<NpgsqlParameter> sqlParams = new List<NpgsqlParameter>
            {
                new NpgsqlParameter("p_teacher_id", NpgsqlDbType.Integer) { Value = teacherId },
                new NpgsqlParameter("p_token_id", NpgsqlDbType.Varchar) { Value = tokenId }
            };
            await SqlHelper.ExecuteNonQuery(sqlParams, StoredProcedure.USP_RevokeAuthToken, connectionString, cancellationToken);
        }
    }
}
