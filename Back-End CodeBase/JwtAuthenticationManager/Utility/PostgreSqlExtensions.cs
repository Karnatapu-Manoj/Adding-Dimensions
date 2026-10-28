using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Npgsql;

namespace JwtAuthenticationManager.Utility;

public static class PostgreSqlExtensions
{
    public static IServiceCollection AddPostgreSql(this IServiceCollection services, IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("DBConnection")
            ?? throw new InvalidOperationException("ConnectionStrings:DBConnection must be configured.");
        // NpgsqlConnection (used by SqlHelper) already provides connection pooling.
        // Validate configuration here without opening a connection at startup.
        _ = new NpgsqlConnectionStringBuilder(connectionString);
        return services;
    }
}
