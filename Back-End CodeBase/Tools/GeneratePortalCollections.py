from pathlib import Path
import json

ROOT=Path(__file__).resolve().parent.parent
ALL=['sponsor-admin','schoolnet-super-admin','schoolnet-project-admin','state-admin','school-admin','trainer','trainee','reporting-audit-user']
ADMIN=['schoolnet-super-admin','schoolnet-project-admin']
LOCAL_ADMIN=ADMIN+['state-admin','school-admin']
TRAINER=LOCAL_ADMIN+['trainer']
# Key, table, identity column, controller/service name, readable roles, writable roles.
collections=[
 ('projects','project','project_id','Projects',ALL,ADMIN),
 ('plans','training_plan','plan_id','TrainingPlans',ALL,LOCAL_ADMIN),
 ('project-plan-associations','project_plan_association','association_id','ProjectPlans',ALL,ADMIN),
 ('batch-plan-uses','training_batch','batch_id','Batches',ALL,TRAINER),
 ('trainer-profiles','trainer','trainer_id','Trainers',ALL,ADMIN+['trainer']),
 ('trainer-availability','trainer_availability','availability_id','TrainerAvailability',ALL,ADMIN+['trainer']),
 ('trainees','trainee','trainee_id','Trainees',TRAINER+['trainee'],TRAINER),
 ('registrations','batch_enrollment','enrollment_id','Registrations',ALL,TRAINER),
 ('attendance-records','attendance','attendance_id','Attendance',ALL,ADMIN+['trainer']),
 ('attendance-exclusions','attendance_exclusion','exclusion_id','AttendanceExclusions',ALL,ADMIN+['trainer']),
 ('assessment-form-master','learning_resource','resource_id','AssessmentForms',ALL,ADMIN),
 ('assessment-records','assessment_attempt','attempt_id','Assessments',ALL,['trainee']),
 ('feedback-records','assessment_attempt','attempt_id','Feedback',ALL,['trainee']),
 ('certificate-templates','certificate_template','template_id','CertificateTemplates',ALL,ADMIN+['sponsor-admin']),
 ('certificates','certificate_record','certificate_id','Certificates',ALL,ADMIN+['sponsor-admin','trainer']),
 ('holidays','m_holiday','holiday_id','Holidays',ALL,['schoolnet-super-admin']),
 ('users','app_user','user_id','Users',ALL,['schoolnet-super-admin']),
 ('odoo-project-catalog','odoo_project_catalog','catalog_id','OdooProjects',ALL,['schoolnet-super-admin']),
 ('schools','m_school','school_id','Schools',ALL,['schoolnet-super-admin']),
 ('learning-resources','learning_resource','resource_id','Resources',ALL,ADMIN+['trainer']),
 ('resource-usage','resource_progress','progress_id','ResourceProgress',ALL,['trainee','trainer']),
 ('external-course-records','external_course_record','record_id','ExternalCourses',ALL,ADMIN+['trainee']),
 ('eligible-teachers','school_eligibility','eligibility_id','EligibleTeachers',ALL,ADMIN),
 ('eligible-students','school_eligibility','eligibility_id','EligibleStudents',ALL,ADMIN),
 ('audit','audit_log','audit_id','Audit',ALL,ALL),
 ('trainer-audit','audit_log','audit_id','TrainerAudit',TRAINER,TRAINER),
 ('certificate-audit','audit_log','audit_id','CertificateAudit',ALL,ADMIN+['sponsor-admin','trainer']),
]
for key in ['school-assignments','school-access','school-admin-assignments','state-access','cluster-master','approved-venues','school-eligibility','eligible-participants','holiday-policy','batch-dependent-records']:
 collections.append((key,'portal_setting','portal_setting_id','Settings',ALL,['schoolnet-super-admin']))

def quoted(values):return 'ARRAY['+','.join("'"+x+"'" for x in values)+']::text[]'
sql=['-- Collection allowlist. Only server-defined table names and role lists can be used.']
for key,table,pk,module,reads,writes in collections:
 sql.append(f"INSERT INTO public.portal_collection VALUES ('teacher-training-{key}','{table}','{pk}',{quoted(reads)},{quoted(writes)}) ON CONFLICT(collection_key) DO UPDATE SET table_name=excluded.table_name,pk_column=excluded.pk_column,read_roles=excluded.read_roles,write_roles=excluded.write_roles;")
(ROOT/'DB Scripts/Stored Procedures/105_PortalCollections.sql').write_text('\n'.join(sql)+'\n',encoding='utf-8')
(ROOT/'Microservices/TeachersAPI/Models/PortalCollections.cs').write_text('''namespace TeachersAPI.Models
{
    public static class PortalCollections
    {
        public static readonly Dictionary<string,string> Tables = new Dictionary<string,string>
        {
'''+',\n'.join(f'            ["teacher-training-{k}"]="{t}"' for k,t,*_ in collections)+'''
        };
    }
}
''',encoding='utf-8')

for module in dict.fromkeys(c[3] for c in collections):
 if module=='Settings':continue
 key=next(c[0] for c in collections if c[3]==module)
 service=f'''using Newtonsoft.Json.Linq;
using TeachersAPI.Models;

namespace TeachersAPI.Services
{{
    public interface I{module}Service
    {{
        Task<Message<JObject>> GetData(long userId,CancellationToken ct);
        Task<Message<JObject>> SaveData(long userId,string role,PortalChangesRequest request,CancellationToken ct);
    }}
    public class {module}Service : I{module}Service
    {{
        private readonly PortalService _portalService;
        public {module}Service(PortalService portalService) {{ _portalService=portalService; }}
        public Task<Message<JObject>> GetData(long userId,CancellationToken ct)
        {{
            return _portalService.GetData(userId,ct);
        }}
        public Task<Message<JObject>> SaveData(long userId,string role,PortalChangesRequest request,CancellationToken ct)
        {{
            return _portalService.SaveData(userId,role,"teacher-training-{key}",request,ct);
        }}
    }}
}}
'''
 (ROOT/f'Microservices/TeachersAPI/Services/{module}Service.cs').write_text(service,encoding='utf-8')
 controller=f'''using System.IdentityModel.Tokens.Jwt;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Newtonsoft.Json.Linq;
using TeachersAPI.Models;
using TeachersAPI.Services;
using TeachersAPI.Utility;

namespace TeachersAPI.Controllers
{{
    [ApiController]
    [Authorize]
    [Route("api/[controller]")]
    public class {module}Controller : Controller
    {{
        private readonly IConfiguration _configuration;
        private readonly ILogger<{module}Controller> _logger;
        private readonly I{module}Service _{module[0].lower()+module[1:]}Service;
        public {module}Controller(IConfiguration configuration,ILogger<{module}Controller> logger,I{module}Service service)
        {{
            _configuration=configuration;_logger=logger;_{module[0].lower()+module[1:]}Service=service;
        }}

        [HttpPost]
        [Route("GetData")]
        public async Task<IActionResult> GetData(EncryptedRequest request,CancellationToken ct)
        {{
            var msg=new Message<JObject>();
            try
            {{
                string decryptedData=AesGcmEncryptionDecryption.Decrypt(request.data,request.salt,request.nonce,request.tag,_configuration["AESPassword"]!);
                RequestModel data=RequestHelper.DeserializeAndValidate<RequestModel>(decryptedData);
                msg=await _{module[0].lower()+module[1:]}Service.GetData(CurrentUserId,ct);msg.ResponseCode=data.RequestCode;
            }}
            catch(Exception ex) {{ ResponseHelper.SetError(msg,ex,_logger,nameof(GetData)); }}
            return StatusCode(msg.StatusCode,ResponseHelper.Encrypt(msg,_configuration["AESPassword"]!));
        }}

        [HttpPost]
        [Route("SaveData")]
        public async Task<IActionResult> SaveData(EncryptedRequest request,CancellationToken ct)
        {{
            var msg=new Message<JObject>();
            try
            {{
                string decryptedData=AesGcmEncryptionDecryption.Decrypt(request.data,request.salt,request.nonce,request.tag,_configuration["AESPassword"]!);
                PortalChangesRequest data=RequestHelper.DeserializeAndValidate<PortalChangesRequest>(decryptedData);
                msg=await _{module[0].lower()+module[1:]}Service.SaveData(CurrentUserId,User.FindFirst("role")!.Value,data,ct);
                msg.ResponseCode=data.RequestCode;
            }}
            catch(Exception ex) {{ ResponseHelper.SetError(msg,ex,_logger,nameof(SaveData)); }}
            return StatusCode(msg.StatusCode,ResponseHelper.Encrypt(msg,_configuration["AESPassword"]!));
        }}
        private long CurrentUserId {{ get {{ return long.Parse(User.FindFirst(JwtRegisteredClaimNames.Sub)!.Value); }} }}
    }}
}}
'''
 (ROOT/f'Microservices/TeachersAPI/Controllers/{module}Controller.cs').write_text(controller,encoding='utf-8')

registrations='\n'.join(f'builder.Services.AddScoped<I{m}Service,{m}Service>();' for m in dict.fromkeys(c[3] for c in collections) if m!='Settings')
(ROOT/'Tools/PortalServiceRegistrations.txt').write_text(registrations,encoding='utf-8')
# Used by the browser data adapter; no component or folder moves are needed.
routes={f'teacher-training-{k}':('Settings' if m=='Settings' else m) for k,t,pk,m,*_ in collections}
(ROOT/'Tools/portal-routes.json').write_text(json.dumps(routes,indent=2)+'\n',encoding='utf-8')
print(f'Generated {len(collections)} collection bindings and {len(set(c[3] for c in collections))-1} module controller/service pairs.')
