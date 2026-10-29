using System.ComponentModel.DataAnnotations;
using System.Text;
using Microsoft.AspNetCore.Identity;
using Newtonsoft.Json.Linq;
using UserAPI.Models;
using UserAPI.Utility;

namespace UserAPI.Services
{
    // Maps the existing screen contracts to the workbook's relational columns.
    // ui_data retains presentation-only fields; keys, dates, statuses and relations
    // are stored in typed columns and checked by the stored procedures.
    public class PortalRecordMapper
    {
        private readonly PortalPii _pii;
        private readonly IPasswordHasher<PortalUserModel> _passwordHasher;
        private readonly IHttpContextAccessor _httpContext;
        private readonly IWebHostEnvironment _environment;
        public PortalRecordMapper(PortalPii pii,IPasswordHasher<PortalUserModel> passwordHasher,IHttpContextAccessor httpContext,IWebHostEnvironment environment)
        {
            _pii=pii;_passwordHasher=passwordHasher;
            _httpContext=httpContext;_environment=environment;
        }
        public static string Text(JToken? row,string key,string fallback="") { return row?[key]?.ToString() ?? fallback; }
        public static JArray Rows(JObject snapshot,string key) { return snapshot["teacher-training-"+key] as JArray ?? new JArray(); }
        public static JObject? Find(JObject snapshot,string key,string? id)
        {
            if(string.IsNullOrWhiteSpace(id))return null;
            return Rows(snapshot,key).OfType<JObject>().FirstOrDefault(row=>new[]{"id","userId","traineeId","code","trainerCode","udise","batchCode","uniqueId","reference"}
                .Any(field=>string.Equals(Text(row,field),id,StringComparison.OrdinalIgnoreCase)));
        }
        public JObject Prepare(long userId,string role,string collection,JObject input,JObject snapshot)
        {
            JObject data=(JObject)input.DeepClone();
            string key=collection.Replace("teacher-training-","");
            string id=Text(data,"id",Text(data,"userId",Text(data,"traineeId")));
            if(string.IsNullOrWhiteSpace(id))throw new ValidationException("A record identifier is required.");
            JObject? previous=Find(snapshot,key,id);
            JObject values=new JObject();
            long? projectId=null,ownerId=null,batchId=null;
            JObject? project=Find(snapshot,"projects",Text(data,"projectId"));
            JObject? batch=Find(snapshot,"batch-plan-uses",Text(data,"batchId",Text(data,"batchCode")));
            if(batch!=null)
            {
                batchId=batch.Value<long>("_dbId");
                project=Find(snapshot,"projects",Text(batch,"projectId"));
            }
            projectId=project?.Value<long>("_dbId");
            JObject? owner=Find(snapshot,"users",Text(data,"userId"));
            ownerId=owner?.Value<long>("_dbId");
            Func<string,string,bool,long?> reference=(name,external,required)=>
            {
                JObject? found=Find(snapshot,name,external);
                if(found==null && required)throw new ValidationException("A valid "+name+" reference is required.");
                return found?.Value<long>("_dbId");
            };
            Func<JObject> enrollment=()=>
            {
                JObject? found=Find(snapshot,"registrations",Text(data,"registrationId"));
                if(found==null && batch!=null)
                {
                    string traineeRef=Text(data,"traineeId",Text(data,"userId"));
                    JObject? person=Find(snapshot,"trainees",traineeRef);
                    found=Rows(snapshot,"registrations").OfType<JObject>().FirstOrDefault(r=>
                        (Text(r,"batchId")==Text(batch,"id") || Text(r,"batchCode")==Text(batch,"batchCode")) &&
                        (Text(r,"traineeId")==traineeRef || Text(r,"userId")==traineeRef ||
                            (person!=null && Text(r,"traineeId")==Text(person,"id"))));
                }
                if(found==null)throw new ValidationException("The trainee must be registered in this batch.");
                ownerId=found.Value<long?>("_ownerId");
                return found;
            };

            switch(key)
            {
                case "projects":
                    values["project_code"]=Text(data,"code");values["project_name"]=Text(data,"name");
                    values["start_date"]=data["startDate"];values["end_date"]=data["endDate"];
                    values["description"]=data["description"];values["odoo_ref"]=data["odooReference"];
                    projectId=previous?.Value<long>("_dbId");
                    break;
                case "plans":
                    values["project_id"]=projectId;values["plan_code"]=Text(data,"code");values["plan_name"]=Text(data,"name");
                    values["training_type"]=Text(data,"trainingCycle").Contains("Refresher")?"REFRESHER_1":"INDUCTION";
                    values["total_days"]=data["days"];values["description"]=data["description"];
                    values["status"]=Text(data,"status","Draft").ToUpperInvariant();
                    break;
                case "project-plan-associations":
                    values["project_id"]=reference("projects",Text(data,"projectId"),true);
                    values["plan_id"]=reference("plans",Text(data,"trainingPlanId"),true);
                    values["is_active"]=Text(data,"status","Active")=="Active";
                    break;
                case "batch-plan-uses":
                    JObject? association=Find(snapshot,"project-plan-associations",Text(data,"projectPlanAssociationId"));
                    values["project_id"]=reference("projects",Text(data,"projectId"),true);
                    values["plan_id"]=reference("plans",Text(association,"trainingPlanId",Text(data,"trainingPlanCode")),true);
                    values["school_id"]=reference("schools",Text(data,"schoolUdiseVenue"),true);
                    values["trainer_id"]=reference("trainer-profiles",Text(data,"trainerProfileCode",Text(data,"trainerCode")),true);
                    values["batch_code"]=Text(data,"batchCode",id);values["start_date"]=data["trainingStartDate"];
                    values["end_date"]=data["trainingEndAuto"];values["capacity"]=data["registrationCapacity"] ?? new JValue(100000);
                    values["reference_location"]=data["location"];values["actual_location"]=Text(Find(snapshot,"schools",Text(data,"schoolUdiseVenue")),"school");
                    values["open_registration"]=data["openRegistration"] ?? new JValue(false);
                    values["is_closed"]=Text(data,"status")=="Archived";
                    values["plan_code_snapshot"]=data["trainingPlanCode"];values["plan_snapshot_json"]=Find(snapshot,"plans",Text(data,"trainingPlanCode"));
                    batchId=previous?.Value<long>("_dbId");
                    break;
                case "trainer-profiles":
                    values["trainer_code"]=data["trainerCode"];values["trainer_name"]=data["name"];
                    values["category"]=Text(data,"category","Employee").ToUpperInvariant();
                    values["is_active"]=data["active"] ?? new JValue(true);
                    break;
                case "trainer-availability":
                    values["trainer_id"]=reference("trainer-profiles",Text(data,"trainerCode"),true);
                    values["start_date"]=data["date"] ?? data["startDate"];values["end_date"]=data["date"] ?? data["endDate"];
                    ownerId=Find(snapshot,"users",Text(Find(snapshot,"trainer-profiles",Text(data,"trainerCode")),"userId"))?.Value<long>("_dbId");
                    break;
                case "trainees":
                    string traineeCode=Text(data,"traineeId",id);
                    foreach(string field in new[]{"gender","designation"})if(data[field]!=null)values[field]=data[field];
                    if(data["classesTaught"]!=null)values["classes_taught"]=data["classesTaught"];
                    if(data["subjectsTaught"]!=null)values["subjects_taught"]=data["subjectsTaught"];
                    if(data["teachingExperience"]!=null)values["teaching_experience"]=data["teachingExperience"];
                    if(data["schoolUdise"]!=null)values["school_id"]=reference("schools",Text(data,"schoolUdise"),true);
                    values["trainee_code"]=traineeCode.Length>30?traineeCode[..30]:traineeCode;values["full_name"]=Text(data,"name",Text(data,"traineeName"));
                    values["is_active"]=data["active"] ?? new JValue(true);
                    break;
                case "registrations":
                    values["batch_id"]=reference("batch-plan-uses",Text(data,"batchId",Text(data,"batchCode")),true);
                    values["trainee_id"]=reference("trainees",Text(data,"traineeId"),true);
                    JObject? trainee=Find(snapshot,"trainees",Text(data,"traineeId"));
                    ownerId=trainee?.Value<long?>("_ownerId") ?? Find(snapshot,"users",Text(trainee,"userId"))?.Value<long>("_dbId");
                    values["registration_mode"]=Text(data,"source").Contains("Excel")?"EXCEL":"SELF";
                    values["approval_status"]=Text(data,"status","Approved").ToUpperInvariant();
                    if(Text(data,"status")=="Approved"){values["approved_by"]=userId;values["approved_at"]=DateTime.UtcNow;}
                    values["trainee_school_id"]=reference("schools",Text(trainee,"schoolUdise"),false);
                    break;
                case "attendance-records":
                    values["enrollment_id"]=enrollment().Value<long>("_dbId");values["attendance_date"]=data["trainingDate"];
                    values["status"]=Text(data,"status").ToUpperInvariant();values["marked_by"]=userId;
                    break;
                case "attendance-exclusions":
                    values["enrollment_id"]=enrollment().Value<long>("_dbId");values["training_date"]=data["trainingDate"];
                    values["reason"]=data["reason"] ?? data["revocationReason"];values["approved"]=data["approved"] ?? new JValue(true);
                    values["changed_by"]=userId;
                    break;
                case "assessment-form-master":
                case "learning-resources":
                    if (_httpContext.HttpContext != null && !_httpContext.HttpContext.Request.Path.Equals("/api/Resources/Upload") &&
                        Text(data,"storagePath") != Text(previous,"storagePath"))
                        throw new ValidationException("Use the resource upload endpoint to add or replace a file.");
                    values["resource_code"]=Text(data,"code",id.Length>30?id[..30]:id);
                    values["resource_name"]=Text(data,"title",Text(data,"name"));
                    values["resource_type"]=key=="assessment-form-master"?"FORM":Text(data,"format","PDF").ToUpperInvariant();
                    values["project_id"]=projectId;values["is_common"]=projectId==null;
                    values["uploaded_by"]=userId;values["access_mode"]="REPOSITORY";
                    values["file_name"]=data["file"];values["storage_path"]=data["storagePath"];
                    if(key=="assessment-form-master")
                    {
                        values["form_type"]=Text(data,"kind","assessment").ToUpperInvariant();
                        values["form_purpose"]=Text(data,"stage")=="pre"?"PRE_ASSESSMENT":Text(data,"stage")=="post"?"POST_ASSESSMENT":"DAILY_FEEDBACK";
                    }
                    break;
                case "assessment-records":
                case "feedback-records":
                    values["enrollment_id"]=enrollment().Value<long>("_dbId");
                    values["resource_id"]=reference("assessment-form-master",Text(data,"formId"),true);
                    values["kind"]=key=="feedback-records"?"feedback":"assessment";values["answers"]=data["answers"] ?? new JObject();
                    values["rating_score"]=data["ratingScore"];values["rating_max_marks"]=data["ratingMaxMarks"];
                    values["score"]=data["score"];values["max_marks"]=data["maxMarks"];values["passed"]=data["passed"];
                    ownerId=userId;
                    break;
                case "certificate-templates":
                    values["template_code"]=id.Length>30?id[..30]:id;
                    values["project_id"]=projectId ?? Rows(snapshot,"projects").FirstOrDefault()?.Value<long>("_dbId")
                        ?? throw new ValidationException("Create a project before configuring certificate templates.");
                    values["program_name"]=data["title"];values["signatory_name"]=data["signatory"];
                    values["colour_scheme"]=data["primary"] ?? new JValue("#17365D");
                    break;
                case "certificates":
                    JObject registration=enrollment();
                    values["enrollment_id"]=registration.Value<long>("_dbId");
                    JObject? template=Find(snapshot,"certificate-templates",Text(data["templateSnapshot"],"id"));
                    values["template_id"]=template?.Value<long>("_dbId") ?? throw new ValidationException("Save the certificate template first.");
                    values["certificate_number"]=data["certificateNumber"];values["trainee_name"]=data["traineeName"];
                    values["training_name"]=Text(data,"trainingPlanName","Training");values["duration_days"]=batch?["trainingDuration"] ?? new JValue(1);
                    values["completion_date"]=Text(data,"issuedAt",DateTime.UtcNow.ToString("O"))[..10];
                    values["is_provisional"]=false;values["template_snapshot_json"]=data["templateSnapshot"];values["issued_by"]=userId;
                    break;
                case "holidays":
                    values["holiday_name"]=data["name"];values["holiday_date"]=data["date"];values["scope"]=Text(data,"scope","National").ToUpperInvariant();
                    values["state_id"]=StateId(snapshot,Text(data,"state"));values["is_active"]=data["active"] ?? new JValue(true);
                    break;
                case "users":
                    values["login_id"]=data["userId"];values["full_name"]=Text(data,"name",Text(data,"userId"));
                    values["role_id"]=(snapshot["_roles"] as JArray)?.OfType<JObject>().FirstOrDefault(r=>Text(r,"role")==Text(data,"role"))?.Value<long>("id")
                        ?? throw new ValidationException("Select a valid role.");
                    values["is_active"]=data["active"] ?? new JValue(true);ownerId=previous?.Value<long>("_dbId");
                    if(previous==null)
                    {
                        if (!_environment.IsDevelopment()) throw new ValidationException("New accounts require the configured account invitation workflow outside local development.");
                        values["password_hash"]=_passwordHasher.HashPassword(new PortalUserModel(),"demo1@123");
                    }
                    break;
                case "odoo-project-catalog":
                    values["reference"]=data["reference"];values["project_name"]=data["name"];values["sponsor_name"]=data["sponsor"];
                    break;
                case "schools":
                    values["udise_code"]=data["udise"];values["school_name"]=data["school"];
                    values["state_id"]=StateId(snapshot,Text(data,"state"));
                    values["district_id"]=(snapshot["_districts"] as JArray)?.OfType<JObject>().FirstOrDefault(r=>Text(r,"name")==Text(data,"district") && Text(r,"state")==Text(data,"state"))?.Value<long>("id")
                        ?? throw new ValidationException("Select a valid district.");
                    values["actual_location"]=Text(data,"school");
                    break;
                case "eligible-teachers":case "eligible-students":
                    values["school_id"]=reference("schools",Text(data,"schoolUdise"),true);values["project_id"]=projectId;
                    values["beneficiary_type"]=key=="eligible-teachers"?"teacher":"student";values["eligible_count"]=data["count"] ?? new JValue(0);
                    break;
                case "external-course-records":
                    values["enrollment_id"]=enrollment().Value<long>("_dbId");values["course_name"]=Text(data,"name","External course");
                    values["completed"]=data["completed"] ?? new JValue(false);
                    break;
                case "resource-usage":
                    values["trainee_id"]=reference("trainees",Text(data,"traineeId",Text(data,"userId")),true);
                    values["resource_id"]=reference("learning-resources",Text(data,"resourceId"),true);
                    values["percent_viewed"]=data["percentViewed"] ?? new JValue(0);
                    ownerId=userId;
                    break;
                case "audit":case "trainer-audit":case "certificate-audit":
                    values["actor_user_id"]=userId;values["action"]=Text(data,"action","Change");values["entity_type"]=Text(data,"entity","portal");
                    values["entity_id"]=Text(data,"entityId",id).Length>50?id[..Math.Min(id.Length,50)]:Text(data,"entityId",id);
                    values["project_id"]=projectId;ownerId=userId;
                    break;
                default:
                    values["setting_key"]=key;
                    break;
            }
            data["id"]=id;data.Remove("_dbId");data.Remove("_version");data.Remove("_ownerId");
            JObject protectedData=_pii.Protect(data,previous);
            if(key is "trainees" or "trainer-profiles" or "users")
            {
                foreach(var pair in new[]{("email","email"),("phone","mobile")})
                {
                    if(protectedData["_contacts"]?[pair.Item1] is JObject contact)
                    {
                        values[pair.Item2+"_enc"]="\\x"+Convert.ToHexString(Encoding.UTF8.GetBytes(contact.ToString()));
                        values[pair.Item2+"_hash"]=string.IsNullOrEmpty(contact.Value<string>("mask"))?JValue.CreateNull():contact["hash"];values[pair.Item2+"_mask"]=contact["mask"];
                    }
                }
            }
            return new JObject
            {
                ["id"]=id,["version"]=input["_version"] ?? new JValue(0),["values"]=values,["data"]=protectedData,
                ["projectId"]=projectId,["ownerId"]=ownerId,["batchId"]=batchId
            };
        }
        private static long? StateId(JObject snapshot,string state)
        {
            return (snapshot["_states"] as JArray)?.OfType<JObject>().FirstOrDefault(s=>Text(s,"name")==state)?.Value<long>("id");
        }
    }
}
