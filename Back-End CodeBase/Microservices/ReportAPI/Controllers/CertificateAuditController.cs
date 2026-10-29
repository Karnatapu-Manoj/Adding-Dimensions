using System.IdentityModel.Tokens.Jwt;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Newtonsoft.Json.Linq;
using ReportAPI.Models;
using ReportAPI.Services;
using ReportAPI.Utility;

namespace ReportAPI.Controllers
{
    [ApiController]
    [Authorize(Policy = "PortalUser")]
    [Route("api/[controller]")]
    public class CertificateAuditController : Controller
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<CertificateAuditController> _logger;
        private readonly ICertificateAuditService _certificateAuditService;
        public CertificateAuditController(IConfiguration configuration,ILogger<CertificateAuditController> logger,ICertificateAuditService service)
        {
            _configuration=configuration;_logger=logger;_certificateAuditService=service;
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
                msg=await _certificateAuditService.GetData(CurrentUserId,ct);msg.ResponseCode=data.RequestCode;
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
                msg=await _certificateAuditService.SaveData(CurrentUserId,User.FindFirst("role")!.Value,data,ct);
                msg.ResponseCode=data.RequestCode;
            }
            catch(Exception ex) { ResponseHelper.SetError(msg,ex,_logger,nameof(SaveData)); }
            return StatusCode(msg.StatusCode,ResponseHelper.Encrypt(msg,_configuration["AESPassword"]!));
        }
        private long CurrentUserId { get { return long.Parse(User.FindFirst(JwtRegisteredClaimNames.Sub)!.Value); } }
    }
}
