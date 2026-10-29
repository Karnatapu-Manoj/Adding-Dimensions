using System.Data;
using JwtAuthenticationManager.Utility;
using Newtonsoft.Json.Linq;
using Npgsql;
using NpgsqlTypes;

namespace BatchAPI.Services
{
    public class PortalRepository
    {
        private readonly IConfiguration _configuration;
        public PortalRepository(IConfiguration configuration) { _configuration = configuration; }

        public async Task<JObject> GetSnapshot(long userId, CancellationToken ct)
        {
            List<NpgsqlParameter> sqlParams = new List<NpgsqlParameter>
            {
                new NpgsqlParameter("p_user_id", NpgsqlDbType.Bigint) { Value = userId }
            };
            JObject snapshot=await ExecutePayload("public.usp_portal_snapshot", sqlParams, ct);
            var dashboardParams=new List<NpgsqlParameter>{new NpgsqlParameter("p_user_id",NpgsqlDbType.Bigint){Value=userId}};
            snapshot["_dashboard"]=await ExecutePayload("public.usp_portal_dashboard",dashboardParams,ct);
            return snapshot;
        }

        public Task<JObject> ApplyChanges(long userId, string collection, JArray rows, JArray deletes, CancellationToken ct)
        {
            List<NpgsqlParameter> sqlParams = new List<NpgsqlParameter>
            {
                new NpgsqlParameter("p_user_id", NpgsqlDbType.Bigint) { Value = userId },
                new NpgsqlParameter("p_collection", NpgsqlDbType.Varchar) { Value = collection },
                new NpgsqlParameter("p_rows", NpgsqlDbType.Jsonb) { Value = rows.ToString() },
                new NpgsqlParameter("p_deletes", NpgsqlDbType.Jsonb) { Value = deletes.ToString() }
            };
            return ExecutePayload("public.usp_portal_apply", sqlParams, ct);
        }

        public async Task<JObject> ExecutePayload(string procedure, List<NpgsqlParameter> parameters, CancellationToken ct)
        {
            using (DataTable dt = await SqlHelper.ExecuteDataTable(parameters, procedure,
                _configuration.GetConnectionString("DBConnection")!, ct))
            {
                if (dt.Rows.Count == 0) throw new DataException("The procedure returned no result.");
                return JObject.Parse(Convert.ToString(dt.Rows[0]["payload"])!);
            }
        }
    }
}
