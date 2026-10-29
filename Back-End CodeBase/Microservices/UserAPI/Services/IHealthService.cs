using UserAPI.Models;

namespace UserAPI.Services
{
    public interface IHealthService
    {
        Task<Message<object>> GetDatabaseHealth(CancellationToken cancellationToken);
    }
}
