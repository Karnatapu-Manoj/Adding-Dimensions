using BatchAPI.Models;

namespace BatchAPI.Services
{
    public interface IHealthService
    {
        Task<Message<object>> GetDatabaseHealth(CancellationToken cancellationToken);
    }
}
