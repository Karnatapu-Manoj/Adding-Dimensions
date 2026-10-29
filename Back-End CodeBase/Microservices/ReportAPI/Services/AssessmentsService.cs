using Newtonsoft.Json.Linq;
using ReportAPI.Models;

namespace ReportAPI.Services
{
    public interface IAssessmentsService
    {
        Task<Message<JObject>> GetData(long userId,CancellationToken ct);
        Task<Message<JObject>> SaveData(long userId,string role,PortalChangesRequest request,CancellationToken ct);
    }
    public class AssessmentsService : IAssessmentsService
    {
        private readonly PortalService _portalService;
        public AssessmentsService(PortalService portalService) { _portalService=portalService; }
        public Task<Message<JObject>> GetData(long userId,CancellationToken ct)
        {
            return _portalService.GetData(userId,ct);
        }
        public Task<Message<JObject>> SaveData(long userId,string role,PortalChangesRequest request,CancellationToken ct)
        {
            return _portalService.SaveData(userId,role,"teacher-training-assessment-records",request,ct);
        }
    }
}
