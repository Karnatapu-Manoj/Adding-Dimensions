using Newtonsoft.Json.Linq;
using BatchAPI.Models;

namespace BatchAPI.Services
{
    public interface IAttendanceExclusionsService
    {
        Task<Message<JObject>> GetData(long userId,CancellationToken ct);
        Task<Message<JObject>> SaveData(long userId,string role,PortalChangesRequest request,CancellationToken ct);
    }
    public class AttendanceExclusionsService : IAttendanceExclusionsService
    {
        private readonly PortalService _portalService;
        public AttendanceExclusionsService(PortalService portalService) { _portalService=portalService; }
        public Task<Message<JObject>> GetData(long userId,CancellationToken ct)
        {
            return _portalService.GetData(userId,ct);
        }
        public Task<Message<JObject>> SaveData(long userId,string role,PortalChangesRequest request,CancellationToken ct)
        {
            return _portalService.SaveData(userId,role,"teacher-training-attendance-exclusions",request,ct);
        }
    }
}
