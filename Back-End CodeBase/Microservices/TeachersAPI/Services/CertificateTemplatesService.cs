using Newtonsoft.Json.Linq;
using TeachersAPI.Models;

namespace TeachersAPI.Services
{
    public interface ICertificateTemplatesService
    {
        Task<Message<JObject>> GetData(long userId,CancellationToken ct);
        Task<Message<JObject>> SaveData(long userId,string role,PortalChangesRequest request,CancellationToken ct);
    }
    public class CertificateTemplatesService : ICertificateTemplatesService
    {
        private readonly PortalService _portalService;
        public CertificateTemplatesService(PortalService portalService) { _portalService=portalService; }
        public Task<Message<JObject>> GetData(long userId,CancellationToken ct)
        {
            return _portalService.GetData(userId,ct);
        }
        public Task<Message<JObject>> SaveData(long userId,string role,PortalChangesRequest request,CancellationToken ct)
        {
            return _portalService.SaveData(userId,role,"teacher-training-certificate-templates",request,ct);
        }
    }
}
