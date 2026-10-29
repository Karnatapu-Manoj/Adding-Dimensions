using System.IdentityModel.Tokens.Jwt;
using JwtAuthenticationManager;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using UserAPI.Models;
using UserAPI.Services;
using UserAPI.Utility;

namespace UserAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class LoginController : Controller
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<LoginController> _logger;
        private readonly ITeachersService _teachersService;
        private readonly ILoginService _loginService;

        public LoginController(IConfiguration configuration, ILogger<LoginController> logger,
            ITeachersService teachersService, ILoginService loginService)
        {
            _configuration = configuration;
            _logger = logger;
            _teachersService = teachersService;
            _loginService = loginService;
        }

        [HttpPost]
        [Route("Register")]
        [AllowAnonymous]
        [EnableRateLimiting("login")]
        public async Task<IActionResult> Register(EncryptedRequest request, CancellationToken cancellationToken)
        {
            var msg = new Message<TeacherModel>();
            try
            {
                string password = _configuration.GetValue<string>("AESPassword")!;
                string decryptedData = AesGcmEncryptionDecryption.Decrypt(
                    request.data, request.salt, request.nonce, request.tag, password);
                RegistrationModel data = RequestHelper.DeserializeAndValidate<RegistrationModel>(decryptedData);

                msg = await _teachersService.SaveTeacher(data, "Teacher", cancellationToken);
                msg.ResponseCode = data.RequestCode;
            }
            catch (Exception ex)
            {
                ResponseHelper.SetError(msg, ex, _logger, nameof(Register));
            }
            return StatusCode(msg.StatusCode, ResponseHelper.Encrypt(msg, _configuration.GetValue<string>("AESPassword")!));
        }

        [HttpPost]
        [Route("Login")]
        [AllowAnonymous]
        [EnableRateLimiting("login")]
        public async Task<IActionResult> Login(EncryptedRequest request, CancellationToken cancellationToken)
        {
            var msg = new Message<AuthenticationResponse>();
            try
            {
                string password = _configuration.GetValue<string>("AESPassword")!;
                string decryptedData = AesGcmEncryptionDecryption.Decrypt(
                    request.data, request.salt, request.nonce, request.tag, password);
                AuthenticationRequest data = RequestHelper.DeserializeAndValidate<AuthenticationRequest>(decryptedData);

                msg = await _loginService.GetLoginUser(data, cancellationToken);
                msg.ResponseCode = data.RequestCode;
            }
            catch (Exception ex)
            {
                ResponseHelper.SetError(msg, ex, _logger, nameof(Login));
            }
            return StatusCode(msg.StatusCode, ResponseHelper.Encrypt(msg, _configuration.GetValue<string>("AESPassword")!));
        }

        [HttpPost]
        [Route("Logout")]
        [Authorize(Policy = "LegacyTeacher")]
        public async Task<IActionResult> Logout(EncryptedRequest request, CancellationToken cancellationToken)
        {
            var msg = new Message<object>();
            try
            {
                string password = _configuration.GetValue<string>("AESPassword")!;
                string decryptedData = AesGcmEncryptionDecryption.Decrypt(
                    request.data, request.salt, request.nonce, request.tag, password);
                RequestModel data = RequestHelper.DeserializeAndValidate<RequestModel>(decryptedData);

                int userId = int.Parse(User.FindFirst(JwtRegisteredClaimNames.Sub)!.Value);
                string tokenId = User.FindFirst(JwtRegisteredClaimNames.Jti)!.Value;
                msg = await _loginService.Logout(userId, tokenId, cancellationToken);
                msg.ResponseCode = data.RequestCode;
            }
            catch (Exception ex)
            {
                ResponseHelper.SetError(msg, ex, _logger, nameof(Logout));
            }
            return StatusCode(msg.StatusCode, ResponseHelper.Encrypt(msg, _configuration.GetValue<string>("AESPassword")!));
        }
    }
}
