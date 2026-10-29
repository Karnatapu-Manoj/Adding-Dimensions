using Newtonsoft.Json.Linq;
using BatchAPI.Models;

namespace BatchAPI.Services
{
    public interface IBatchesService
    {
        Task<Message<JObject>> GetData(long userId,CancellationToken ct);
        Task<Message<JObject>> SaveData(long userId,string role,PortalChangesRequest request,CancellationToken ct);
    }
    public class BatchesService : IBatchesService
    {
        private readonly PortalService _portalService;
        public BatchesService(PortalService portalService) { _portalService=portalService; }
        public Task<Message<JObject>> GetData(long userId,CancellationToken ct)
        {
            return _portalService.GetData(userId,ct);
        }
        public Task<Message<JObject>> SaveData(long userId,string role,PortalChangesRequest request,CancellationToken ct)
        {
            return _portalService.SaveData(userId,role,"teacher-training-batch-plan-uses",request,ct);
        }
    }
}
