using Newtonsoft.Json.Linq;
using ReportAPI.Models;

namespace ReportAPI.Services
{
    public class ReportsService
    {
        private readonly PortalService _portalService;
        public ReportsService(PortalService portalService) { _portalService=portalService; }
        public async Task<Message<JObject>> GetData(long userId,CancellationToken ct)
        {
            Message<JObject> msg=await _portalService.GetData(userId,ct);
            if(msg.IsSuccess && msg.Data!=null)
            {
                string[] fields={"_dashboard","teacher-training-assessment-records","teacher-training-feedback-records",
                    "teacher-training-attendance-records","teacher-training-certificates"};
                msg.Data=new JObject(msg.Data.Properties().Where(p=>fields.Contains(p.Name)).Select(p=>new JProperty(p.Name,p.Value)));
            }
            return msg;
        }
    }
}
