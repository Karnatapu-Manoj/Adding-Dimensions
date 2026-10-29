using System.Data;
using JwtAuthenticationManager.Utility;
using Microsoft.AspNetCore.Identity;
using Newtonsoft.Json.Linq;
using Npgsql;
using NpgsqlTypes;
using TeachersAPI.Models;
using TeachersAPI.Services;
using static TeachersAPI.Services.PortalRecordMapper;

namespace TeachersAPI.Utility
{
    public static class PortalDemoSeeder
    {
        public static async Task Seed(IServiceProvider services,string sourcePath,CancellationToken ct=default)
        {
            JObject source=JObject.Parse(await File.ReadAllTextAsync(sourcePath,ct));
            PortalRepository repository=services.GetRequiredService<PortalRepository>();
            PortalRecordMapper mapper=services.GetRequiredService<PortalRecordMapper>();
            var hasher=services.GetRequiredService<IPasswordHasher<PortalUserModel>>();
            JArray users=(JArray)source["teacher-training-users"]!;
            foreach(JObject user in users)user["passwordHash"]=hasher.HashPassword(new PortalUserModel(),"demo1@123");
            List<NpgsqlParameter> parameters=new List<NpgsqlParameter>
            {
                new NpgsqlParameter("p_users",NpgsqlDbType.Jsonb){Value=users.ToString()},
                new NpgsqlParameter("p_schools",NpgsqlDbType.Jsonb){Value=source["teacher-training-schools"]!.ToString()}
            };
            JObject bootstrap=await repository.ExecutePayload("public.usp_portal_bootstrap",parameters,ct);
            long adminId=bootstrap.Value<long>("adminId");
            JObject snapshot=await repository.GetSnapshot(adminId,ct);
            foreach(string key in new[]{"projects","plans","project-plan-associations","trainer-profiles","trainer-availability",
                "batch-plan-uses","trainees","registrations","attendance-records","eligible-teachers","eligible-students","holidays","school-assignments"})
            {
                string collection="teacher-training-"+key;
                if(source[collection] is not JArray records)continue;
                foreach(JObject record in records)
                {
                    if(key=="trainer-profiles" && Find(snapshot,key,Text(record,"userId"))!=null)continue;
                    if(key=="batch-plan-uses")
                    {
                        JObject? assignedTrainer=Find(snapshot,"trainer-profiles",Text(record,"trainerCode"));
                        if(assignedTrainer!=null)record["trainerProfileCode"]=assignedTrainer["trainerCode"];
                    }
                    if(Find(snapshot,key,Text(record,"id"))!=null)continue;
                    JObject prepared=mapper.Prepare(adminId,"schoolnet-super-admin",collection,record,snapshot);
                    snapshot=await repository.ApplyChanges(adminId,collection,new JArray(prepared),new JArray(),ct);
                }
            }
            foreach(JObject project in Rows(snapshot,"projects"))
            {
                var scopeParams=new List<NpgsqlParameter>{new NpgsqlParameter("p_project_id",NpgsqlDbType.Integer){Value=project.Value<int>("_dbId")}};
                await SqlHelper.ExecuteNonQuery(scopeParams,"public.usp_portal_seed_scopes",
                    services.GetRequiredService<IConfiguration>().GetConnectionString("DBConnection")!,ct);
            }
            snapshot=await repository.GetSnapshot(adminId,ct);
            string resourceFolder=services.GetRequiredService<ResourceFileService>().StorageRoot;
            Directory.CreateDirectory(resourceFolder);
            string frontendRoot=Path.GetFullPath(Path.Combine(Path.GetDirectoryName(sourcePath)!,"../../Front-End CodeBase"));
            foreach(var spec in new[]{("video","Digital classroom training","sample-training-video.mp4","Video","MP4"),
                ("manual","Teacher training manual","sample-training-manual.pdf","Documents","PDF"),
                ("presentation","Teacher training presentation","sample-training.pptx","Presentation","PPTX"),
                ("guide","Teacher training guide","sample-training-guide.docx","Documents","DOCX"),
                ("workflow","Educator onboarding workflow","educator-onboarding-workflow.json","Documents","WORKFLOW")})
            {
                if(Find(snapshot,"learning-resources",spec.Item1)!=null)continue;
                string target=Path.Combine(resourceFolder,spec.Item3);
                if(spec.Item1=="workflow")await File.WriteAllTextAsync(target,"{\"workflow\":\"Educator onboarding\",\"steps\":[\"Register educator\",\"Assign batch\",\"Complete modules\",\"Record attendance\",\"Review outcomes\"]}",ct);
                else File.Copy(Path.Combine(frontendRoot,"public/content-library-assets",spec.Item3),target,true);
                JObject resource=new JObject{["id"]=spec.Item1,["title"]=spec.Item2,["file"]=spec.Item3,["category"]=spec.Item4,
                    ["format"]=spec.Item5,["language"]="English",["tags"]=new JArray("Training"),["storagePath"]=spec.Item3,
                    ["size"]=$"{new FileInfo(target).Length/1024} KB"};
                JObject prepared=mapper.Prepare(adminId,"schoolnet-super-admin","teacher-training-learning-resources",resource,snapshot);
                snapshot=await repository.ApplyChanges(adminId,"teacher-training-learning-resources",new JArray(prepared),new JArray(),ct);
            }
            foreach(var spec in new[]{("ODOO-PRJ-001","Teacher Training","TT-2026","ERNET India"),("ODOO-PRJ-002","Digital Classrooms","DC-2026","Schoolnet India")})
            {
                if(Find(snapshot,"odoo-project-catalog",spec.Item1)!=null)continue;
                JObject row=new JObject{["id"]=spec.Item1,["name"]=spec.Item2,["reference"]=spec.Item3,["sponsor"]=spec.Item4};
                snapshot=await repository.ApplyChanges(adminId,"teacher-training-odoo-project-catalog",
                    new JArray(mapper.Prepare(adminId,"schoolnet-super-admin","teacher-training-odoo-project-catalog",row,snapshot)),new JArray(),ct);
            }
            foreach(string mode in new[]{"Offline","Online","Hybrid"})
            {
                if(Find(snapshot,"certificate-templates",mode.ToLowerInvariant())!=null)continue;
                JObject template=new JObject{["id"]=mode.ToLowerInvariant(),["mode"]=mode,["title"]=mode+" Training Completion Certificate",
                    ["sponsorName"]="ERNET India",["sponsor"]="ERNET",["primary"]="#173f68",["accent"]="#c79535",
                    ["wording"]="This is to certify that {{traineeName}} has successfully completed {{trainingPlan}} through {{trainingMode}} training held from {{startDate}} to {{endDate}}.",
                    ["signatory"]="Authorized Signatory",["numberFormat"]="CERT-"+mode[..3].ToUpperInvariant()+"-{YYYY}-{####}",
                    ["requiredDetails"]=new JArray("Trainee name","Training plan","Training mode","Training dates","Organization / school","Certificate number","Issue date")};
                snapshot=await repository.ApplyChanges(adminId,"teacher-training-certificate-templates",
                    new JArray(mapper.Prepare(adminId,"schoolnet-super-admin","teacher-training-certificate-templates",template,snapshot)),new JArray(),ct);
            }
            foreach(string kind in new[]{"assessment","feedback"})
            {
                string id="DEMO-FORM-"+kind;
                if(Find(snapshot,"assessment-form-master",id)!=null)continue;
                bool graded=kind=="assessment";
                JObject form=new JObject{["id"]=id,["title"]=graded?"Digital teaching assessment":"Training feedback",["kind"]=kind,
                    ["grading"]=graded?"graded":"non-graded",["source"]="native",["planCode"]="TP-DEMO-001",["day"]=1,
                    ["stage"]=graded?"post":"feedback",["maxMarks"]=graded?1:0,["passMarks"]=graded?1:0,["attemptLimit"]=3,
                    ["allowUnanswered"]=false,["mandatory"]=false,["comparable"]=graded,["createdAt"]=DateTime.UtcNow,
                    ["questions"]=new JArray(new JObject{["id"]="q1",["prompt"]=graded?"Which action supports active learning?":"How useful was this training?",
                        ["options"]=graded?new JArray("Discussion and practice","Passive listening only"):new JArray("Very useful","Useful","Needs improvement"),
                        ["correctIndex"]=graded?new JValue(0):JValue.CreateNull(),["points"]=graded?1:0,["required"]=true})};
                snapshot=await repository.ApplyChanges(adminId,"teacher-training-assessment-form-master",
                    new JArray(mapper.Prepare(adminId,"schoolnet-super-admin","teacher-training-assessment-form-master",form,snapshot)),new JArray(),ct);
            }
            // Import supplied upstream form definitions, without inventing submissions or grades.
            foreach(JObject form in source["teacher-training-assessment-form-master"] as JArray ?? new JArray())
            {
                if(Find(snapshot,"assessment-form-master",Text(form,"id"))!=null)continue;
                snapshot=await repository.ApplyChanges(adminId,"teacher-training-assessment-form-master",
                    new JArray(mapper.Prepare(adminId,"schoolnet-super-admin","teacher-training-assessment-form-master",form,snapshot)),new JArray(),ct);
            }
            Console.WriteLine("Demo1–Demo13 accounts and existing sample records are seeded. Existing accounts and records were not overwritten.");
        }
    }
}
