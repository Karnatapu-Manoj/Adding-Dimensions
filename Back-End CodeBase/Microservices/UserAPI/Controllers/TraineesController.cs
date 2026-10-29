using System.IdentityModel.Tokens.Jwt;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Newtonsoft.Json.Linq;
using UserAPI.Models;
using UserAPI.Services;
using UserAPI.Utility;

namespace UserAPI.Controllers
{
    [ApiController]
    [Authorize(Policy = "PortalUser")]
    [Route("api/[controller]")]
    public class TraineesController : Controller
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<TraineesController> _logger;
        private readonly ITraineesService _traineesService;
        public TraineesController(IConfiguration configuration,ILogger<TraineesController> logger,ITraineesService service)
        {
            _configuration=configuration;_logger=logger;_traineesService=service;
        }

        [HttpPost]
        [Route("GetData")]
        public async Task<IActionResult> GetData(EncryptedRequest request,CancellationToken ct)
        {
            var msg=new Message<JObject>();
            try
            {
                string decryptedData=AesGcmEncryptionDecryption.Decrypt(request.data,request.salt,request.nonce,request.tag,_configuration["AESPassword"]!);
                RequestModel data=RequestHelper.DeserializeAndValidate<RequestModel>(decryptedData);
                msg=await _traineesService.GetData(CurrentUserId,ct);msg.ResponseCode=data.RequestCode;
            }
            catch(Exception ex) { ResponseHelper.SetError(msg,ex,_logger,nameof(GetData)); }
            return StatusCode(msg.StatusCode,ResponseHelper.Encrypt(msg,_configuration["AESPassword"]!));
        }

        [HttpPost]
        [Route("SaveData")]
        public async Task<IActionResult> SaveData(EncryptedRequest request,CancellationToken ct)
        {
            var msg=new Message<JObject>();
            try
            {
                string decryptedData=AesGcmEncryptionDecryption.Decrypt(request.data,request.salt,request.nonce,request.tag,_configuration["AESPassword"]!);
                PortalChangesRequest data=RequestHelper.DeserializeAndValidate<PortalChangesRequest>(decryptedData);
                msg=await _traineesService.SaveData(CurrentUserId,User.FindFirst("role")!.Value,data,ct);
                msg.ResponseCode=data.RequestCode;
            }
            catch(Exception ex) { ResponseHelper.SetError(msg,ex,_logger,nameof(SaveData)); }
            return StatusCode(msg.StatusCode,ResponseHelper.Encrypt(msg,_configuration["AESPassword"]!));
        }
        private long CurrentUserId { get { return long.Parse(User.FindFirst(JwtRegisteredClaimNames.Sub)!.Value); } }
    }
}
