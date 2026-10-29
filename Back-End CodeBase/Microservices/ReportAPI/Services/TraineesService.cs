using Newtonsoft.Json.Linq;
using ReportAPI.Models;

namespace ReportAPI.Services
{
    public interface ITraineesService
    {
        Task<Message<JObject>> GetData(long userId,CancellationToken ct);
        Task<Message<JObject>> SaveData(long userId,string role,PortalChangesRequest request,CancellationToken ct);
    }
    public class TraineesService : ITraineesService
    {
        private readonly PortalService _portalService;
        public TraineesService(PortalService portalService) { _portalService=portalService; }
        public Task<Message<JObject>> GetData(long userId,CancellationToken ct)
        {
            return _portalService.GetData(userId,ct);
        }
        public Task<Message<JObject>> SaveData(long userId,string role,PortalChangesRequest request,CancellationToken ct)
        {
            return _portalService.SaveData(userId,role,"teacher-training-trainees",request,ct);
        }
    }
}
