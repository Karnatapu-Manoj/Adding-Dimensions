using TeachersAPI.Models;

namespace TeachersAPI.Services
{
    public interface IHealthService
    {
        Task<Message<object>> GetDatabaseHealth(CancellationToken cancellationToken);
    }
}
