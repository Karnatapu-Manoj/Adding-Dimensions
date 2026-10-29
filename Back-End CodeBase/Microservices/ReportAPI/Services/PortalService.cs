using Newtonsoft.Json.Linq;
using ReportAPI.Models;
using ReportAPI.Utility;
using static ReportAPI.Services.PortalRecordMapper;

namespace ReportAPI.Services
{
    public class PortalService
    {
        private readonly PortalRepository _repository;
        private readonly PortalRecordMapper _mapper;
        private readonly PortalBusinessRules _businessRules;
        private readonly PortalPii _pii;
        private readonly ILogger<PortalService> _logger;
        private readonly ResourceFileService _files;
        public PortalService(PortalRepository repository,PortalRecordMapper mapper,PortalBusinessRules businessRules,
            PortalPii pii,ILogger<PortalService> logger,ResourceFileService files)
        {
            _repository=repository;_mapper=mapper;_businessRules=businessRules;_pii=pii;_logger=logger;_files=files;
        }
        public async Task<Message<JObject>> GetData(long userId,CancellationToken ct)
        {
            var msg=new Message<JObject>();
            try
            {
                msg.Data=ClientSnapshot(await _repository.GetSnapshot(userId,ct));
                msg.IsSuccess=true;msg.StatusCode=200;msg.ReturnMessage="Success.";
            }
            catch(Exception ex){ResponseHelper.SetError(msg,ex,_logger,nameof(GetData));}
            return msg;
        }
        public async Task<Message<JObject>> SaveData(long userId,string role,string collection,PortalChangesRequest request,CancellationToken ct)
        {
            var msg=new Message<JObject>();
            try
            {
                if(!PortalCollections.Tables.ContainsKey(collection))throw new System.ComponentModel.DataAnnotations.ValidationException("Unknown collection.");
                JObject snapshot=await _repository.GetSnapshot(userId,ct);
                JArray prepared=new JArray();
                foreach(JObject record in request.Upserts)
                {
                    _businessRules.Validate(collection,record,snapshot,userId,role);
                    prepared.Add(_mapper.Prepare(userId,role,collection,record,snapshot));
                }
                await _repository.ApplyChanges(userId,collection,prepared,request.Deletes,ct);
                JObject saved=await _repository.GetSnapshot(userId,ct);
                msg.Data=ClientSnapshot(saved);msg.StatusCode=200;msg.IsSuccess=true;msg.ReturnMessage="Changes saved.";
            }
            catch(Exception ex){ResponseHelper.SetError(msg,ex,_logger,nameof(SaveData));}
            return msg;
        }
        public JObject ClientSnapshot(JObject snapshot)
        {
            JObject result=(JObject)snapshot.DeepClone();
            string role=Text(snapshot["_current"],"role"),loginId=Text(snapshot["_current"],"userId");
            long userId=snapshot["_current"]?.Value<long>("id") ?? 0;
            foreach(var collection in result.Properties().Where(p=>p.Name.StartsWith("teacher-training-")).ToArray())
            {
                if(collection.Value is not JArray rows)continue;
                for(int index=0;index<rows.Count;index++)
                {
                    JObject row=(JObject)rows[index];
                    bool full=role=="schoolnet-super-admin" || row.Value<long?>("_ownerId")==userId || Text(row,"userId")==loginId;
                    JObject clientRow=_pii.Reveal(row,full);
                    if(collection.Name=="teacher-training-assessment-form-master" && role=="trainee" && clientRow["questions"] is JArray questions)
                        foreach(JObject question in questions){question.Remove("correctIndex");question.Remove("expectedAnswer");}
                    rows[index]=clientRow;
                }
            }
            _files.AddDownloadUrls(result);
            return result;
        }
    }
}
