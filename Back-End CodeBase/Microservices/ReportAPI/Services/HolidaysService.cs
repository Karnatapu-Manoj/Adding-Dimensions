using Newtonsoft.Json.Linq;
using ReportAPI.Models;

namespace ReportAPI.Services
{
    public interface IHolidaysService
    {
        Task<Message<JObject>> GetData(long userId,CancellationToken ct);
        Task<Message<JObject>> SaveData(long userId,string role,PortalChangesRequest request,CancellationToken ct);
    }
    public class HolidaysService : IHolidaysService
    {
        private readonly PortalService _portalService;
        public HolidaysService(PortalService portalService) { _portalService=portalService; }
        public Task<Message<JObject>> GetData(long userId,CancellationToken ct)
        {
            return _portalService.GetData(userId,ct);
        }
        public Task<Message<JObject>> SaveData(long userId,string role,PortalChangesRequest request,CancellationToken ct)
        {
            return _portalService.SaveData(userId,role,"teacher-training-holidays",request,ct);
        }
    }
}
