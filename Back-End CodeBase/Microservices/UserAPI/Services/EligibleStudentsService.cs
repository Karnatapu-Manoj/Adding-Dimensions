using Newtonsoft.Json.Linq;
using UserAPI.Models;

namespace UserAPI.Services
{
    public interface IEligibleStudentsService
    {
        Task<Message<JObject>> GetData(long userId,CancellationToken ct);
        Task<Message<JObject>> SaveData(long userId,string role,PortalChangesRequest request,CancellationToken ct);
    }
    public class EligibleStudentsService : IEligibleStudentsService
    {
        private readonly PortalService _portalService;
        public EligibleStudentsService(PortalService portalService) { _portalService=portalService; }
        public Task<Message<JObject>> GetData(long userId,CancellationToken ct)
        {
            return _portalService.GetData(userId,ct);
        }
        public Task<Message<JObject>> SaveData(long userId,string role,PortalChangesRequest request,CancellationToken ct)
        {
            return _portalService.SaveData(userId,role,"teacher-training-eligible-students",request,ct);
        }
    }
}
