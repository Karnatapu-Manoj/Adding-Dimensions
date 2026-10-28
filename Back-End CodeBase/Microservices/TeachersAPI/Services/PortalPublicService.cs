using System.ComponentModel.DataAnnotations;
using System.Security.Cryptography;
using System.Text;
using Microsoft.AspNetCore.Identity;
using Newtonsoft.Json.Linq;
using Npgsql;
using NpgsqlTypes;
using TeachersAPI.Models;
using TeachersAPI.Utility;

namespace TeachersAPI.Services
{
    public class PortalPublicService
    {
        private readonly PortalRepository _repository;
        private readonly PortalPii _pii;
        private readonly IConfiguration _configuration;
        private readonly IWebHostEnvironment _environment;
        private readonly ILogger<PortalPublicService> _logger;
        private readonly PortalOtpService _otp;
        public PortalPublicService(PortalRepository repository,PortalPii pii,IConfiguration configuration,
            IWebHostEnvironment environment,ILogger<PortalPublicService> logger,PortalOtpService otp)
        { _repository=repository;_pii=pii;_configuration=configuration;_environment=environment;_logger=logger;_otp=otp; }

        public async Task<Message<JObject>> Execute(string action,JObject data,CancellationToken ct)
        {
            var msg=new Message<JObject>();
            try
            {
                if(action=="GetData")msg.Data=await _repository.ExecutePayload("public.usp_portal_public_data",new List<NpgsqlParameter>(),ct);
                else if(action=="RequestRegistration" || action=="Register")
                {
                    if (action == "Register")
                    {
                        JObject verified = await _otp.Verify("REGISTRATION", data.Value<string>("challengeId") ?? string.Empty,
                            data.Value<string>("otp") ?? string.Empty, ct);
                        data = (JObject)verified["payload"]!;
                    }
                    string name=data.Value<string>("name")?.Trim() ?? string.Empty;
                    string email=data.Value<string>("email")?.Trim() ?? string.Empty;
                    string phone=data.Value<string>("phone")?.Trim() ?? string.Empty;
                    if(data.Value<bool?>("consentProvided")!=true)throw new ValidationException("Consent to using your contact details for training registration is required.");
                    if(name.Length<1 || name.Length>150 || (email.Length==0 && phone.Length==0) ||
                        (email.Length>0 && !new EmailAddressAttribute().IsValid(email)))throw new ValidationException("Enter a valid name and contact details.");
                    if (phone.Length > 0 && (new string(phone.Where(char.IsDigit).ToArray()).Length < 10 || phone.Length > 20))
                        throw new ValidationException("Enter a valid mobile number.");
                    if (action == "RequestRegistration")
                    {
                        msg.Data = await _otp.Create("REGISTRATION", null, email.Length > 0 ? email : phone,
                            new JObject { ["name"] = name, ["email"] = email, ["phone"] = phone,
                                ["category"] = data["category"], ["batchCode"] = data["batchCode"], ["consentProvided"] = true }, ct);
                        msg.IsSuccess = true; msg.StatusCode = 200; msg.ReturnMessage = "Verification code created.";
                        return msg;
                    }
                    string id="TR-"+Guid.NewGuid().ToString("N")[..12].ToUpperInvariant();
                    JObject person=_pii.Protect(new JObject { ["id"]=id,["traineeId"]=id,["name"]=name,["email"]=email,
                        ["phone"]=phone,["category"]=data["category"],["consentProvided"]=true,["createdAt"]=DateTime.UtcNow },null);
                    JObject contact=new JObject { ["id"]=id,["name"]=name,["data"]=person };
                    foreach(string field in new[]{"email","phone"})
                    {
                        JObject entry=(JObject)person["_contacts"]![field]!;
                        contact[field+"Hash"]=string.IsNullOrEmpty(field=="email"?email:phone)?null:entry["hash"];
                        contact[field+"Hex"]=Convert.ToHexString(Encoding.UTF8.GetBytes(entry.ToString()));
                        contact[field+"Mask"]=entry["mask"];
                    }
                    string initialPassword=Convert.ToBase64String(RandomNumberGenerator.GetBytes(18));
                    var parameters=new List<NpgsqlParameter>
                    {
                        new NpgsqlParameter("p_batch_code",NpgsqlDbType.Varchar){Value=data.Value<string>("batchCode") ?? string.Empty},
                        new NpgsqlParameter("p_person",NpgsqlDbType.Jsonb){Value=contact.ToString()},
                        new NpgsqlParameter("p_password_hash",NpgsqlDbType.Varchar){Value=new PasswordHasher<PortalUserModel>().HashPassword(new PortalUserModel(),initialPassword)}
                    };
                    msg.Data=await _repository.ExecutePayload("public.usp_portal_public_register",parameters,ct);
                    if(_environment.IsDevelopment() && msg.Data.Value<bool>("newAccount"))
                        msg.Data["accountMailPath"] = "/api/Public/LocalOutbox/" + await WriteMail(email.Length>0?email:phone,"Training registration",
                            $"Trainee ID: {msg.Data.Value<string>("traineeId")}\nInitial password: {initialPassword}\nRegistration is pending administrator approval.",ct);
                }
                else if(action=="RequestRecovery")
                {
                    string contact=data.Value<string>("contact")?.Trim() ?? string.Empty;
                    if(contact.Length==0 || contact.Length>150)throw new ValidationException("Enter your registered email or mobile number.");
                    var parameters=new List<NpgsqlParameter>
                    {
                        new NpgsqlParameter("p_contact_hash",NpgsqlDbType.Varchar){Value=_pii.ContactHash(contact)}
                    };
                    JObject identifiers=await _repository.ExecutePayload("public.usp_portal_recovery_lookup",parameters,ct);
                    msg.Data=await _otp.Create("RECOVERY",null,contact,identifiers,ct);
                    msg.Data["requestId"]=msg.Data["challengeId"];
                    msg.Data["message"]="If the contact is registered, its trainee ID will be available after verification. Read the code in the local email outbox.";
                }
                else if(action=="VerifyRecovery")
                {
                    JObject verified=await _otp.Verify("RECOVERY",data.Value<string>("requestId") ?? string.Empty,data.Value<string>("otp") ?? string.Empty,ct);
                    JObject payload=(JObject)verified["payload"]!;
                    if(payload["traineeIds"] is not JArray ids || ids.Count==0)throw new ValidationException("No active trainee record could be recovered with this contact. Contact an administrator.");
                    msg.Data=new JObject{["verified"]=true,["traineeIds"]=ids};
                }
                else throw new ValidationException("Unknown public action.");
                msg.IsSuccess=true;msg.StatusCode=200;msg.ReturnMessage="Success.";
            }
            catch(Exception ex){ResponseHelper.SetError(msg,ex,_logger,action);}
            return msg;
        }
        private async Task<string> WriteMail(string recipient,string subject,string body,CancellationToken ct)
        {
            string folder=Path.GetFullPath(Path.Combine(_environment.ContentRootPath,"../../.local/mail-outbox"));
            Directory.CreateDirectory(folder);
            string id=Guid.NewGuid().ToString();
            await File.WriteAllTextAsync(Path.Combine(folder,id+".eml"),$"To: {recipient.Replace("\r", "").Replace("\n", "")}\nSubject: {subject}\n\n{body}",ct);
            return id;
        }
    }
}
