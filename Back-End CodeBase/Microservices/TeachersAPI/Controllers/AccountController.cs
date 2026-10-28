using System.IdentityModel.Tokens.Jwt;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using TeachersAPI.Models;
using TeachersAPI.Services;
using TeachersAPI.Utility;
using Newtonsoft.Json.Linq;

namespace TeachersAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AccountController : Controller
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<AccountController> _logger;
        private readonly PortalAccountService _accountService;
        public AccountController(IConfiguration configuration,ILogger<AccountController> logger,PortalAccountService accountService)
        {
            _configuration=configuration;_logger=logger;_accountService=accountService;
        }

        [HttpPost,Route("Login"),AllowAnonymous,EnableRateLimiting("login")]
        public async Task<IActionResult> Login(EncryptedRequest request,CancellationToken ct)
        {
            var msg=new Message<PortalLoginResponse>();
            try
            {
                string password=_configuration["AESPassword"]!;
                string decryptedData=AesGcmEncryptionDecryption.Decrypt(request.data,request.salt,request.nonce,request.tag,password);
                PortalLoginRequest data=RequestHelper.DeserializeAndValidate<PortalLoginRequest>(decryptedData);
                msg=await _accountService.Login(data,ct);msg.ResponseCode=data.RequestCode;
            }
            catch(Exception ex) { ResponseHelper.SetError(msg,ex,_logger,nameof(Login)); }
            return StatusCode(msg.StatusCode,ResponseHelper.Encrypt(msg,_configuration["AESPassword"]!));
        }

        [HttpPost, Route("VerifyLogin"), AllowAnonymous, EnableRateLimiting("public")]
        public async Task<IActionResult> VerifyLogin(EncryptedRequest request, CancellationToken ct)
        {
            var msg = new Message<PortalLoginResponse>();
            try
            {
                string decryptedData = AesGcmEncryptionDecryption.Decrypt(request.data, request.salt, request.nonce, request.tag, _configuration["AESPassword"]!);
                PortalOtpRequest data = RequestHelper.DeserializeAndValidate<PortalOtpRequest>(decryptedData);
                msg = await _accountService.VerifyLogin(data, ct);
                msg.ResponseCode = data.RequestCode;
            }
            catch (Exception ex) { ResponseHelper.SetError(msg, ex, _logger, nameof(VerifyLogin)); }
            return StatusCode(msg.StatusCode, ResponseHelper.Encrypt(msg, _configuration["AESPassword"]!));
        }

        [HttpPost, Route("RequestPasswordReset"), AllowAnonymous, EnableRateLimiting("login")]
        public async Task<IActionResult> RequestPasswordReset(EncryptedRequest request, CancellationToken ct)
        {
            var msg = new Message<JObject>();
            try
            {
                string decryptedData = AesGcmEncryptionDecryption.Decrypt(request.data, request.salt, request.nonce, request.tag, _configuration["AESPassword"]!);
                PortalIdentityRequest data = RequestHelper.DeserializeAndValidate<PortalIdentityRequest>(decryptedData);
                msg = await _accountService.RequestPasswordReset(data, ct);
            }
            catch (Exception ex) { ResponseHelper.SetError(msg, ex, _logger, nameof(RequestPasswordReset)); }
            return StatusCode(msg.StatusCode, ResponseHelper.Encrypt(msg, _configuration["AESPassword"]!));
        }

        [HttpPost, Route("ResetPassword"), AllowAnonymous, EnableRateLimiting("public")]
        public async Task<IActionResult> ResetPassword(EncryptedRequest request, CancellationToken ct)
        {
            var msg = new Message<JObject>();
            try
            {
                string decryptedData = AesGcmEncryptionDecryption.Decrypt(request.data, request.salt, request.nonce, request.tag, _configuration["AESPassword"]!);
                PortalResetPasswordRequest data = RequestHelper.DeserializeAndValidate<PortalResetPasswordRequest>(decryptedData);
                msg = await _accountService.ResetPassword(data, ct);
            }
            catch (Exception ex) { ResponseHelper.SetError(msg, ex, _logger, nameof(ResetPassword)); }
            return StatusCode(msg.StatusCode, ResponseHelper.Encrypt(msg, _configuration["AESPassword"]!));
        }

        [HttpPost,Route("Logout"),Authorize(Policy = "PortalUser")]
        public async Task<IActionResult> Logout(EncryptedRequest request,CancellationToken ct)
        {
            long userId=long.Parse(User.FindFirst(JwtRegisteredClaimNames.Sub)!.Value);
            string tokenId=User.FindFirst(JwtRegisteredClaimNames.Jti)!.Value;
            Message<object> msg=await _accountService.Logout(userId,tokenId,ct);
            return StatusCode(msg.StatusCode,ResponseHelper.Encrypt(msg,_configuration["AESPassword"]!));
        }
    }
}
