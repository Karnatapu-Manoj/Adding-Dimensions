using Newtonsoft.Json.Linq;
using BatchAPI.Models;

namespace BatchAPI.Services
{
    public interface ISchoolsService
    {
        Task<Message<JObject>> GetData(long userId,CancellationToken ct);
        Task<Message<JObject>> SaveData(long userId,string role,PortalChangesRequest request,CancellationToken ct);
    }
    public class SchoolsService : ISchoolsService
    {
        private readonly PortalService _portalService;
        public SchoolsService(PortalService portalService) { _portalService=portalService; }
        public Task<Message<JObject>> GetData(long userId,CancellationToken ct)
        {
            return _portalService.GetData(userId,ct);
        }
        public Task<Message<JObject>> SaveData(long userId,string role,PortalChangesRequest request,CancellationToken ct)
        {
            return _portalService.SaveData(userId,role,"teacher-training-schools",request,ct);
        }
    }
}
