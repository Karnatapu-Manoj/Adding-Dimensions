using System.Data;
using JwtAuthenticationManager.Utility;
using Npgsql;
using BatchAPI.Models;

namespace BatchAPI.Services
{
    public class HealthService : IHealthService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<HealthService> _logger;

        public HealthService(IConfiguration configuration, ILogger<HealthService> logger)
        {
            _configuration = configuration;
            _logger = logger;
        }

        public async Task<Message<object>> GetDatabaseHealth(CancellationToken cancellationToken)
        {
            var msg = new Message<object>();
            try
            {
                string connectionString = _configuration.GetConnectionString("DBConnection")!;
                List<NpgsqlParameter> sqlParams = new List<NpgsqlParameter>();
                using (DataTable dt = await SqlHelper.ExecuteDataTable(sqlParams,
                    StoredProcedure.USP_CheckDatabaseHealth, connectionString, cancellationToken))
                {
                    bool isHealthy = dt.Rows.Count > 0 && Convert.ToBoolean(dt.Rows[0]["is_healthy"]);
                    msg.IsSuccess = isHealthy;
                    msg.StatusCode = isHealthy ? 200 : 503;
                    msg.ReturnMessage = isHealthy ? "Healthy" : "Unhealthy";
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Database readiness check failed.");
                msg.StatusCode = 503;
                msg.ReturnMessage = "Unhealthy";
            }
            return msg;
        }
    }
}
