using System.IdentityModel.Tokens.Jwt;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Newtonsoft.Json.Linq;
using Npgsql;
using NpgsqlTypes;
using BatchAPI.Models;
using BatchAPI.Services;
using BatchAPI.Utility;

namespace BatchAPI.Controllers
{
    [ApiController,Authorize(Policy="PortalUser",Roles="trainee"),Route("api/Assessments")]
    public class AssessmentAttemptsController : Controller
    {
        private readonly PortalRepository _repository;
        private readonly IConfiguration _configuration;
        private readonly ILogger<AssessmentAttemptsController> _logger;
        public AssessmentAttemptsController(PortalRepository repository,IConfiguration configuration,ILogger<AssessmentAttemptsController> logger)
        { _repository=repository;_configuration=configuration;_logger=logger; }
        [HttpPost,Route("Begin")]
        public async Task<IActionResult> Begin(EncryptedRequest request,CancellationToken ct)
        {
            var msg=new Message<JObject>();
            try
            {
            JObject data=JObject.Parse(AesGcmEncryptionDecryption.Decrypt(request.data,request.salt,request.nonce,request.tag,_configuration["AESPassword"]!));
            var parameters=new List<NpgsqlParameter>
            {
                new NpgsqlParameter("p_user_id",NpgsqlDbType.Bigint){Value=long.Parse(User.FindFirst(JwtRegisteredClaimNames.Sub)!.Value)},
                new NpgsqlParameter("p_form_id",NpgsqlDbType.Varchar){Value=data.Value<string>("formId") ?? string.Empty},
                new NpgsqlParameter("p_batch_id",NpgsqlDbType.Varchar){Value=data.Value<string>("batchId") ?? string.Empty}
            };
            JObject result=await _repository.ExecutePayload("public.usp_portal_begin_assessment",parameters,ct);
            msg.Data=result;msg.IsSuccess=true;msg.StatusCode=200;msg.ReturnMessage="Attempt started.";
            }
            catch(Exception ex){ResponseHelper.SetError(msg,ex,_logger,nameof(Begin));}
            return StatusCode(msg.StatusCode,ResponseHelper.Encrypt(msg,_configuration["AESPassword"]!));
        }
    }
}
