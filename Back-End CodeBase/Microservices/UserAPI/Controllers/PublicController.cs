using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Newtonsoft.Json.Linq;
using UserAPI.Models;
using UserAPI.Services;
using UserAPI.Utility;

namespace UserAPI.Controllers
{
    [ApiController,AllowAnonymous,Route("api/[controller]")]
    public class PublicController : Controller
    {
        private readonly IConfiguration _configuration;
        private readonly PortalPublicService _publicService;
        private readonly PortalOtpService _otp;
        private readonly ILogger<PublicController> _logger;
        public PublicController(IConfiguration configuration,PortalPublicService publicService,PortalOtpService otp,ILogger<PublicController> logger)
        { _configuration=configuration;_publicService=publicService;_otp=otp;_logger=logger; }
        [HttpPost,Route("{actionName}"),EnableRateLimiting("public")]
        public async Task<IActionResult> Execute(string actionName,EncryptedRequest request,CancellationToken ct)
        {
            var msg = new Message<JObject>();
            try
            {
                JObject data=JObject.Parse(AesGcmEncryptionDecryption.Decrypt(request.data,request.salt,request.nonce,request.tag,_configuration["AESPassword"]!));
                msg=await _publicService.Execute(actionName,data,ct);
            }
            catch(Exception ex) { ResponseHelper.SetError(msg,ex,_logger,actionName); }
            return StatusCode(msg.StatusCode,ResponseHelper.Encrypt(msg,_configuration["AESPassword"]!));
        }

        [HttpGet, Route("LocalOutbox/{id:guid}"), EnableRateLimiting("public")]
        public async Task<IActionResult> LocalOutbox(Guid id, CancellationToken ct)
        {
            if (!_otp.CanViewLocalOutbox(HttpContext.Connection.RemoteIpAddress)) return NotFound();
            string path = Path.Combine(_otp.OutboxFolder(), id.ToString()+".eml");
            if (!System.IO.File.Exists(path)) return NotFound();
            Response.Headers.CacheControl = "no-store";
            Response.Headers["X-Content-Type-Options"] = "nosniff";
            return Content(await System.IO.File.ReadAllTextAsync(path, ct), "text/plain; charset=utf-8");
        }
    }
}
