using Newtonsoft.Json.Linq;
using UserAPI.Models;

namespace UserAPI.Services
{
    public interface ICertificateAuditService
    {
        Task<Message<JObject>> GetData(long userId,CancellationToken ct);
        Task<Message<JObject>> SaveData(long userId,string role,PortalChangesRequest request,CancellationToken ct);
    }
    public class CertificateAuditService : ICertificateAuditService
    {
        private readonly PortalService _portalService;
        public CertificateAuditService(PortalService portalService) { _portalService=portalService; }
        public Task<Message<JObject>> GetData(long userId,CancellationToken ct)
        {
            return _portalService.GetData(userId,ct);
        }
        public Task<Message<JObject>> SaveData(long userId,string role,PortalChangesRequest request,CancellationToken ct)
        {
            return _portalService.SaveData(userId,role,"teacher-training-certificate-audit",request,ct);
        }
    }
}
