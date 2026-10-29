using System.IdentityModel.Tokens.Jwt;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Newtonsoft.Json.Linq;
using ReportAPI.Models;
using ReportAPI.Services;
using ReportAPI.Utility;

namespace ReportAPI.Controllers
{
    [ApiController,Authorize(Policy="PortalUser"),Route("api/[controller]")]
    public class ReportsController : Controller
    {
        private readonly ReportsService _reportsService;
        private readonly IConfiguration _configuration;
        private readonly ILogger<ReportsController> _logger;
        public ReportsController(ReportsService reportsService,IConfiguration configuration,ILogger<ReportsController> logger)
        { _reportsService=reportsService;_configuration=configuration;_logger=logger; }
        [HttpPost,Route("GetData")]
        public async Task<IActionResult> GetData(EncryptedRequest request,CancellationToken ct)
        {
            var msg=new Message<JObject>();
            try
            {
                AesGcmEncryptionDecryption.Decrypt(request.data,request.salt,request.nonce,request.tag,_configuration["AESPassword"]!);
                msg=await _reportsService.GetData(long.Parse(User.FindFirst(JwtRegisteredClaimNames.Sub)!.Value),ct);
            }
            catch(Exception ex) {ResponseHelper.SetError(msg,ex,_logger,nameof(GetData));}
            return StatusCode(msg.StatusCode,ResponseHelper.Encrypt(msg,_configuration["AESPassword"]!));
        }
    }
}
