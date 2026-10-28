using Newtonsoft.Json.Linq;
using TeachersAPI.Models;

namespace TeachersAPI.Services
{
    public interface IAttendanceService
    {
        Task<Message<JObject>> GetData(long userId,CancellationToken ct);
        Task<Message<JObject>> SaveData(long userId,string role,PortalChangesRequest request,CancellationToken ct);
    }
    public class AttendanceService : IAttendanceService
    {
        private readonly PortalService _portalService;
        public AttendanceService(PortalService portalService) { _portalService=portalService; }
        public Task<Message<JObject>> GetData(long userId,CancellationToken ct)
        {
            return _portalService.GetData(userId,ct);
        }
        public Task<Message<JObject>> SaveData(long userId,string role,PortalChangesRequest request,CancellationToken ct)
        {
            return _portalService.SaveData(userId,role,"teacher-training-attendance-records",request,ct);
        }
    }
}
