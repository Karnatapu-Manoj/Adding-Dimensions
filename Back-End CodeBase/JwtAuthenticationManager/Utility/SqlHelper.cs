using System.Data;
using Newtonsoft.Json;
using Npgsql;
using NpgsqlTypes;

namespace JwtAuthenticationManager.Utility
{
    public static class SqlHelper
    {
        // PostgreSQL procedures return rows as a JSON array in p_result.
        // Convert it to a DataTable, preserving the reference service pattern.
        public static async Task<DataTable> ExecuteDataTable(List<NpgsqlParameter> sqlParams,
            string storedProcedure, string connectionString, CancellationToken cancellationToken = default)
        {
            using (NpgsqlConnection con = new NpgsqlConnection(connectionString))
            {
                await con.OpenAsync(cancellationToken);
                using (NpgsqlCommand sqlCmd = new NpgsqlCommand(storedProcedure, con))
                {
                    sqlCmd.CommandType = CommandType.StoredProcedure;
                    sqlCmd.CommandTimeout = 30;
                    sqlCmd.Parameters.AddRange(sqlParams.ToArray());
                    sqlCmd.Parameters.Add(new NpgsqlParameter("p_result", NpgsqlDbType.Jsonb)
                    {
                        Direction = ParameterDirection.InputOutput,
                        Value = DBNull.Value
                    });
                    using (NpgsqlDataReader reader = await sqlCmd.ExecuteReaderAsync(cancellationToken))
                    {
                        if (!await reader.ReadAsync(cancellationToken) || reader.IsDBNull(0))
                        {
                            throw new DataException("The stored procedure did not return p_result.");
                        }
                        string jsonResult = reader.GetString(0);
                        return JsonConvert.DeserializeObject<DataTable>(jsonResult)
                            ?? throw new DataException("The stored procedure returned an invalid result.");
                    }
                }
            }
        }

        public static async Task ExecuteNonQuery(List<NpgsqlParameter> sqlParams,
            string storedProcedure, string connectionString, CancellationToken cancellationToken = default)
        {
            using (DataTable result = await ExecuteDataTable(sqlParams, storedProcedure,
                connectionString, cancellationToken))
            {
                // Let failures reach the caller rather than returning a false success.
            }
        }
    }
}
