using ReportAPI.Models;

namespace ReportAPI.Services
{
    public interface IHealthService
    {
        Task<Message<object>> GetDatabaseHealth(CancellationToken cancellationToken);
    }
}
