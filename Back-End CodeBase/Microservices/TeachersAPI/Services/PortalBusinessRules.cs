using System.ComponentModel.DataAnnotations;
using Newtonsoft.Json.Linq;
using TeachersAPI.Utility;
using static TeachersAPI.Services.PortalRecordMapper;

namespace TeachersAPI.Services
{
    public class PortalBusinessRules
    {
        private readonly IConfiguration _configuration;
        public PortalBusinessRules(IConfiguration configuration) { _configuration=configuration; }
        public void Validate(string collection,JObject record,JObject snapshot,long userId,string role)
        {
            string key=collection.Replace("teacher-training-","");
            JObject? previous=Find(snapshot,key,Text(record,"id",Text(record,"userId")));
            string loginId=Text(snapshot["_current"],"userId");
            DateOnly today=BusinessToday();
            if(key=="projects")
            {
                Require(!string.IsNullOrWhiteSpace(Text(record,"name")) && !string.IsNullOrWhiteSpace(Text(record,"code")),"Project name and code are required.");
                Require(Date(record,"endDate")>=Date(record,"startDate"),"Project end date cannot precede its start date.");
                foreach(JObject phase in record["phases"] as JArray ?? new JArray())
                    Require(Date(phase,"endDate")>=Date(phase,"startDate"),"Phase dates are invalid.");
            }
            if(key=="plans")
            {
                Require(!string.IsNullOrWhiteSpace(Text(record,"name")),"Training plan name is required.");
                Require(record.Value<int>("days") is >=1 and <=365,"Training duration must be between 1 and 365 days.");
                decimal percent=record["completionCriteria"]?.Value<decimal?>("minimumAttendancePercent") ?? 0;
                Require(percent>=0 && percent<=100,"Attendance threshold must be between 0 and 100.");
            }
            if(key=="batch-plan-uses")
            {
                JObject project=Find(snapshot,"projects",Text(record,"projectId")) ?? throw new ValidationException("Select a valid project.");
                JObject association=Find(snapshot,"project-plan-associations",Text(record,"projectPlanAssociationId")) ?? throw new ValidationException("Link this training plan to the project first.");
                Require(Text(association,"projectId")==Text(project,"id") && Text(association,"status")=="Active","The training plan is not active for this project.");
                JObject plan=Find(snapshot,"plans",Text(association,"trainingPlanId")) ?? throw new ValidationException("Select a valid plan.");
                Require(Text(plan,"status")=="Active","Only active plans may be scheduled.");
                DateOnly start=Date(record,"trainingStartDate");DateOnly end=Date(record,"trainingEndAuto");
                Require(start>=Date(project,"startDate") && end<=Date(project,"endDate") && end>=start,"Batch dates must be within the project period.");
                int duration=record.Value<int>("trainingDuration");Require(duration>0 && duration<=365,"Batch duration is invalid.");
                string[] dates=(record["trainingDates"] as JArray ?? new JArray()).Values<string>().Where(x=>x!=null).Select(x=>x!).ToArray();
                Require(dates.Length==duration && dates.Distinct().Count()==duration,"The schedule must contain exactly the configured number of distinct training dates.");
                foreach(string date in dates)
                {
                    DateOnly day=DateOnly.Parse(date);
                    Require(day>=start && day<=end && day.DayOfWeek is not DayOfWeek.Saturday and not DayOfWeek.Sunday,"Training dates must fall on permitted weekdays within the batch period.");
                    bool holiday=Rows(snapshot,"holidays").OfType<JObject>().Any(h=>h.Value<bool?>("active")!=false && Text(h,"date")==date &&
                        (Text(h,"scope")=="National" || Text(h,"state")==Text(record,"state")));
                    bool warn=Rows(snapshot,"holiday-policy").FirstOrDefault()?["value"]?.ToString()=="warn";
                    Require(!holiday || warn,"A training date conflicts with an applicable holiday.");
                }
                JObject trainer=Find(snapshot,"trainer-profiles",Text(record,"trainerProfileCode",Text(record,"trainerCode"))) ?? throw new ValidationException("Select a valid trainer.");
                Require(trainer.Value<bool?>("active")!=false,"The trainer is inactive.");
                if(role=="trainer")Require(Text(trainer,"userId")==loginId,"Trainers may schedule only their own assignments.");
                foreach(JObject other in Rows(snapshot,"batch-plan-uses").OfType<JObject>())
                {
                    if(Text(other,"id")==Text(record,"id") || Text(other,"status") is "Cancelled" or "Archived")continue;
                    if(Text(other,"trainerCode")!=Text(record,"trainerCode"))continue;
                    string[] otherDates=(other["trainingDates"] as JArray ?? new JArray()).Values<string>().Select(x=>x!).ToArray();
                    bool conflict=dates.Intersect(otherDates).Any() &&
                        string.CompareOrdinal(Text(record,"trainingStartTime"),Text(other,"trainingEndTime","23:59"))<0 &&
                        string.CompareOrdinal(Text(other,"trainingStartTime"),Text(record,"trainingEndTime","23:59"))<0;
                    Require(!conflict || (role=="schoolnet-super-admin" && !string.IsNullOrWhiteSpace(Text(record,"overrideReason"))),"The trainer is already assigned during these dates and times.");
                }
                foreach(JObject availability in Rows(snapshot,"trainer-availability").OfType<JObject>().Where(a=>Text(a,"trainerCode")==Text(record,"trainerCode")))
                    Require(!(dates.Contains(Text(availability,"date")) && Text(availability,"status")=="Unavailable"),"The trainer is unavailable on a training date.");
            }
            if(key is "trainer-profiles" or "trainer-availability")
            {
                JObject? trainer=key=="trainer-profiles"?record:Find(snapshot,"trainer-profiles",Text(record,"trainerCode"));
                if(role=="trainer")Require(Text(trainer,"userId")==loginId,"Trainers may manage only their own profile and availability.");
                if(key=="trainer-availability" && role!="schoolnet-super-admin")Require(Date(record,"date")>=today,"Only future availability may be changed.");
            }
            if(key=="registrations")
            {
                Require(Text(record,"status") is "Pending" or "Approved" or "Rejected","Registration status is invalid.");
            }
            if(key is "attendance-records" or "attendance-exclusions")
            {
                JObject batch=Find(snapshot,"batch-plan-uses",Text(record,"batchId",Text(record,"batchCode"))) ?? throw new ValidationException("Select a valid batch.");
                Require(Date(record,"trainingDate")<=today,"Future attendance is not allowed.");
                Require((batch["trainingDates"] as JArray ?? new JArray()).Values<string>().Contains(Text(record,"trainingDate")),"Attendance date must be a scheduled batch training day.");
                if(key=="attendance-records")Require(Text(record,"status") is "Present" or "Absent","Attendance status must be Present or Absent.");
                if(role=="trainer")Require(Text(batch,"trainerCode")==loginId || Text(batch,"trainerProfileCode")==Text(Find(snapshot,"trainer-profiles",loginId),"trainerCode"),"Only the assigned trainer may mark attendance.");
                JObject? registration=FindEnrollment(snapshot,record);
                Require(registration!=null && (registration.Value<bool?>("approved")==true || Text(registration,"status")=="Approved"),"Attendance requires an approved registration in this batch.");
                if(previous!=null && Text(previous,"status")!=Text(record,"status") && role!="schoolnet-super-admin")
                    Require(!string.IsNullOrWhiteSpace(Text(record,"reason",Text(record,"amendmentReason"))),"An attendance amendment reason is required.");
            }
            if(key=="assessment-form-master")
            {
                Require(!string.IsNullOrWhiteSpace(Text(record,"title")),"Form title is required.");
                Require(record.Value<int>("attemptLimit")>0,"Attempt limit must be positive.");
                if(Text(record,"grading")=="graded" && Text(record,"source")=="native")
                    foreach(JObject q in record["questions"] as JArray ?? new JArray())
                        Require(q.Value<int?>("correctIndex")>=0 && q.Value<int?>("correctIndex")<(q["options"] as JArray)?.Count,"Each graded question requires a valid correct answer.");
            }
            if(key is "assessment-records" or "feedback-records")
            {
                Require(previous==null,"Submitted attempts cannot be overwritten.");
                JObject form=Find(snapshot,"assessment-form-master",Text(record,"formId")) ?? throw new ValidationException("This form is unavailable.");
                JObject registration=FindEnrollment(snapshot,record) ?? throw new ValidationException("Registration in this batch is required.");
                Require(registration.Value<long?>("_ownerId")==userId,"A trainee can submit only their own assessment or feedback.");
                Require(Text(registration,"status")=="Approved","Registration approval is required.");
                JObject assignedBatch=Find(snapshot,"batch-plan-uses",Text(record,"batchId")) ?? throw new ValidationException("Select a valid batch.");
                Require(Text(form,"planCode")=="*" || Text(form,"planCode")==Text(assignedBatch,"trainingPlanCode"),"The form is not assigned to this batch's training plan.");
                int assignedDay=form.Value<int>("day");
                JArray trainingDates=assignedBatch["trainingDates"] as JArray ?? new JArray();
                Require(assignedDay>=1 && assignedDay<=trainingDates.Count && DateOnly.Parse(trainingDates[assignedDay-1]!.ToString())<=today,"The form is not available on this training day yet.");
                Require(Text(form,"source","native")=="native","External completion must be verified by its provider; it cannot be self-certified.");
                if(!string.IsNullOrEmpty(Text(form,"availableFrom")))Require(today>=Date(form,"availableFrom"),"The form is not open yet.");
                if(!string.IsNullOrEmpty(Text(form,"availableUntil")))Require(today<=Date(form,"availableUntil"),"The form has closed.");
                int attempts=Rows(snapshot,key).OfType<JObject>().Count(a=>Text(a,"formId")==Text(form,"id") && Text(a,"batchId")==Text(record,"batchId") && a.Value<long?>("_ownerId")==userId);
                Require(attempts<form.Value<int>("attemptLimit"),"The attempt limit has been reached.");
                JObject answers=record["answers"] as JObject ?? new JObject();
                decimal score=0,max=0;
                foreach(JObject q in form["questions"] as JArray ?? new JArray())
                {
                    string answer=answers.Value<string>(Text(q,"id")) ?? string.Empty;
                    Require(form.Value<bool?>("allowUnanswered")==true || q.Value<bool?>("required")==false || answer.Trim().Length>0,"Answer all required questions.");
                    decimal marks=q.Value<decimal?>("points") ?? 1;max+=marks;
                    if(answer==Text(q,"correctIndex"))score+=marks;
                }
                bool graded=key=="assessment-records" && Text(form,"grading")=="graded";
                record["score"]=graded?new JValue(score):JValue.CreateNull();
                record["maxMarks"]=graded?new JValue(max):JValue.CreateNull();
                record["passed"]=graded?new JValue(score>=(form.Value<decimal?>("passMarks") ?? 0)):JValue.CreateNull();
                record["completed"]=true;record["status"]=graded?(score>=(form.Value<decimal?>("passMarks") ?? 0)?"Passed":"Not passed"):"Submitted";
                record["submittedAt"]=DateTime.UtcNow;record["userId"]=loginId;
            }
            if(key=="certificates")
            {
                if(previous!=null)
                {
                    string state=Text(record,"status");
                    Require(state is "Revoked" or "Reissued" or "Superseded","Issued certificate details are immutable. Reissue to change them.");
                    string reason=Text(record,"reason");
                    if(state=="Revoked")Require(!string.IsNullOrWhiteSpace(reason),"A revocation reason is required.");
                    JToken? version=record["_version"]?.DeepClone();
                    record.RemoveAll();record.Merge(previous.DeepClone());record["status"]=state;record["_version"]=version;
                    record["reason"]=reason;record["revokedBy"]=loginId;record["revokedAt"]=DateTime.UtcNow;
                    return;
                }
                JObject registration=FindEnrollment(snapshot,record) ?? throw new ValidationException("Certificate requires an approved registration.");
                JObject batch=Find(snapshot,"batch-plan-uses",Text(record,"batchId",Text(record,"batchCode")))!;
                JObject plan=Find(snapshot,"plans",Text(batch,"trainingPlanCode"))!;
                Require(Text(registration,"status")=="Approved","Certificate requires an approved registration.");
                JObject criteria=plan["completionCriteria"] as JObject ?? new JObject();
                Require(criteria.Count>0,"Configure completion criteria before issuing certificates.");
                string traineeRef=Text(registration,"traineeId");
                string[] dates=(batch["trainingDates"] as JArray ?? new JArray()).Values<string>().Select(d=>d!).ToArray();
                JObject[] marks=Rows(snapshot,"attendance-records").OfType<JObject>().Where(a=>Text(a,"batchId")==Text(batch,"id") && Text(a,"traineeId")==traineeRef).ToArray();
                decimal percent=dates.Length==0?0:100m*marks.Count(m=>Text(m,"status")=="Present")/dates.Length;
                Require(percent>=(criteria.Value<decimal?>("minimumAttendancePercent") ?? 0),"The attendance completion requirement is not met.");
                foreach(int day in (criteria["mandatoryTrainingDays"] as JArray ?? new JArray()).Values<int>())
                    Require(day>=1 && day<=dates.Length && marks.Any(m=>Text(m,"trainingDate")==dates[day-1] && Text(m,"status")=="Present"),"A mandatory training day is incomplete.");
                JObject[] forms=Rows(snapshot,"assessment-form-master").OfType<JObject>().Where(f=>
                    Text(f,"planCode")==Text(batch,"trainingPlanCode") && f.Value<bool?>("mandatory")==true).ToArray();
                JObject[] assessmentRows=Rows(snapshot,"assessment-records").OfType<JObject>().Where(a=>Text(a,"batchId")==Text(batch,"id") &&
                    a.Value<long?>("_ownerId")==registration.Value<long?>("_ownerId") && a.Value<bool?>("completed")==true).ToArray();
                decimal? minimumMarks=criteria.Value<decimal?>("minimumAssessmentMarks");
                bool GoodResult(JObject a) => a.Value<bool?>("passed")!=false && (!minimumMarks.HasValue ||
                    (a.Value<decimal?>("maxMarks")>0 && 100m*a.Value<decimal>("score")/a.Value<decimal>("maxMarks")>=minimumMarks));
                if(criteria.Value<bool?>("requireAssessments")==true || minimumMarks.HasValue)
                {
                    JObject[] mandatory=forms.Where(f=>Text(f,"kind")=="assessment").ToArray();
                    Require(mandatory.Length==0 ? assessmentRows.Any(GoodResult) : mandatory.All(f=>assessmentRows.Any(a=>Text(a,"formId")==Text(f,"id") && GoodResult(a))),
                        "All mandatory assessments and minimum assessment marks must be completed.");
                }
                if(criteria.Value<bool?>("requireFeedback")==true)
                {
                    JObject[] submitted=Rows(snapshot,"feedback-records").OfType<JObject>().Where(a=>Text(a,"batchId")==Text(batch,"id") &&
                        a.Value<long?>("_ownerId")==registration.Value<long?>("_ownerId") && a.Value<bool?>("completed")==true).ToArray();
                    JObject[] mandatory=forms.Where(f=>Text(f,"kind")=="feedback").ToArray();
                    Require(mandatory.Length==0 ? submitted.Length>0 : mandatory.All(f=>submitted.Any(a=>Text(a,"formId")==Text(f,"id"))),"Required feedback is incomplete.");
                }
                if(criteria.Value<bool?>("requireExternalCourse")==true)
                    Require(Rows(snapshot,"external-course-records").OfType<JObject>().Any(a=>Text(a,"batchId")==Text(batch,"id") &&
                        a.Value<long?>("_ownerId")==registration.Value<long?>("_ownerId") && a.Value<bool?>("completed")==true),"Required external course is incomplete.");
                JObject template=Find(snapshot,"certificate-templates",Text(record["templateSnapshot"],"id")) ?? throw new ValidationException("Save an approved certificate template first.");
                JObject person=Find(snapshot,"trainees",traineeRef) ?? throw new ValidationException("Select a valid trainee.");
                JObject? project=Find(snapshot,"projects",Text(batch,"projectId"));
                record["traineeName"]=person["name"] ?? person["traineeName"];record["registrationId"]=registration["id"];
                record["traineeId"]=person["id"];record["userId"]=person["userId"];record["batchId"]=batch["id"];record["batchCode"]=batch["batchCode"];
                record["projectId"]=batch["projectId"];record["projectName"]=project?["name"];record["trainingPlanName"]=plan["name"];
                record["templateSnapshot"]=template.DeepClone();record["templateMode"]=template["mode"];
                record["trainingStartDate"]=dates.FirstOrDefault();record["trainingEndDate"]=dates.LastOrDefault();
                record["issuedAt"]=DateTime.UtcNow;record["issuedBy"]=loginId;record["status"]="Issued";
                if(record["reissueOf"]!=null)Require(!string.IsNullOrWhiteSpace(Text(record,"reason")),"A reissue reason is required.");
                string format=Text(template,"numberFormat","CERT-{YYYY}-{####}");
                if(!format.Contains("{####}"))format+="-{####}";
                int sequence=1;string number;
                do {number=format.Replace("{YYYY}",today.Year.ToString()).Replace("{####}",(sequence++).ToString("D4"));}
                while(Rows(snapshot,"certificates").OfType<JObject>().Any(c=>Text(c,"certificateNumber")==number));
                record["certificateNumber"]=number;
                Require(Date(batch,"trainingEndAuto")<=today,"Training has not finished yet.");
            }
            if(key=="users" && previous!=null && Text(previous,"userId")==loginId)
                Require(record.Value<bool?>("active")!=false && Text(record,"role")==role,"You cannot remove your own administrative access.");
        }
        public DateOnly BusinessToday()
        {
            return DateOnly.FromDateTime(TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow,
                TimeZoneInfo.FindSystemTimeZoneById(_configuration["BusinessTimeZone"] ?? "Asia/Kolkata")));
        }
        private static DateOnly Date(JObject data,string key)
        {
            if(!DateOnly.TryParse(Text(data,key)[..Math.Min(Text(data,key).Length,10)],out DateOnly date))throw new ValidationException("A valid "+key+" date is required.");
            return date;
        }
        public static JObject? FindEnrollment(JObject snapshot,JObject record)
        {
            JObject? found=Find(snapshot,"registrations",Text(record,"registrationId"));
            if(found!=null)return found;
            JObject? person=Find(snapshot,"trainees",Text(record,"traineeId",Text(record,"userId")));
            return Rows(snapshot,"registrations").OfType<JObject>().FirstOrDefault(r=>
                (Text(r,"batchId")==Text(record,"batchId") || (!string.IsNullOrEmpty(Text(record,"batchCode")) && Text(r,"batchCode")==Text(record,"batchCode"))) &&
                (Text(r,"traineeId")==Text(record,"traineeId") || (!string.IsNullOrEmpty(Text(record,"userId")) && Text(r,"userId")==Text(record,"userId")) ||
                    (person!=null && Text(r,"traineeId")==Text(person,"id"))));
        }
        private static void Require(bool condition,string message) { if(!condition)throw new ValidationException(message); }
    }
}
