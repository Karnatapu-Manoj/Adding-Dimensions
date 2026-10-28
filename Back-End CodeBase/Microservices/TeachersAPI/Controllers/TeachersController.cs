using System.IdentityModel.Tokens.Jwt;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TeachersAPI.Models;
using TeachersAPI.Services;
using TeachersAPI.Utility;

namespace TeachersAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize(Policy = "LegacyTeacher")]
    public class TeachersController : Controller
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<TeachersController> _logger;
        private readonly ITeachersService _teachersService;

        public TeachersController(IConfiguration configuration, ILogger<TeachersController> logger,
            ITeachersService teachersService)
        {
            _configuration = configuration;
            _logger = logger;
            _teachersService = teachersService;
        }

        [HttpPost]
        [Route("GetTeachersList")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> GetTeachersList(EncryptedRequest request, CancellationToken cancellationToken)
        {
            var msg = new Message<TeacherModel>();
            try
            {
                string password = _configuration.GetValue<string>("AESPassword")!;
                string decryptedData = AesGcmEncryptionDecryption.Decrypt(
                    request.data, request.salt, request.nonce, request.tag, password);
                TeachersListRequest data = RequestHelper.DeserializeAndValidate<TeachersListRequest>(decryptedData);

                msg = await _teachersService.GetTeachersList(data.PageNumber, data.PageSize, cancellationToken);
                msg.ResponseCode = data.RequestCode;
            }
            catch (Exception ex)
            {
                ResponseHelper.SetError(msg, ex, _logger, nameof(GetTeachersList));
            }
            return StatusCode(msg.StatusCode, ResponseHelper.Encrypt(msg, _configuration.GetValue<string>("AESPassword")!));
        }

        [HttpPost]
        [Route("GetTeacherById")]
        
        public async Task<IActionResult> GetTeacherById(EncryptedRequest request, CancellationToken cancellationToken)
        {
            var msg = new Message<TeacherModel>();
            try
            {
                string password = _configuration.GetValue<string>("AESPassword")!;
                string decryptedData = AesGcmEncryptionDecryption.Decrypt(
                    request.data, request.salt, request.nonce, request.tag, password);
                TeacherIdRequest data = RequestHelper.DeserializeAndValidate<TeacherIdRequest>(decryptedData);

                if (CanAccessTeacher(data.TeacherId))
                {
                    msg = await _teachersService.GetTeacherById(data.TeacherId, cancellationToken);
                }
                else
                {
                    msg.StatusCode = 403;
                    msg.ReturnMessage = "You do not have permission to access this teacher.";
                }
                msg.ResponseCode = data.RequestCode;
            }
            catch (Exception ex)
            {
                ResponseHelper.SetError(msg, ex, _logger, nameof(GetTeacherById));
            }
            return StatusCode(msg.StatusCode, ResponseHelper.Encrypt(msg, _configuration.GetValue<string>("AESPassword")!));
        }

        [HttpPost]
        [Route("GetMyProfile")]
        
        public async Task<IActionResult> GetMyProfile(EncryptedRequest request, CancellationToken cancellationToken)
        {
            var msg = new Message<TeacherModel>();
            try
            {
                string password = _configuration.GetValue<string>("AESPassword")!;
                string decryptedData = AesGcmEncryptionDecryption.Decrypt(
                    request.data, request.salt, request.nonce, request.tag, password);
                RequestModel data = RequestHelper.DeserializeAndValidate<RequestModel>(decryptedData);

                msg = await _teachersService.GetTeacherById(CurrentUserId, cancellationToken);
                msg.ResponseCode = data.RequestCode;
            }
            catch (Exception ex)
            {
                ResponseHelper.SetError(msg, ex, _logger, nameof(GetMyProfile));
            }
            return StatusCode(msg.StatusCode, ResponseHelper.Encrypt(msg, _configuration.GetValue<string>("AESPassword")!));
        }

        [HttpPost]
        [Route("SaveTeacher")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> SaveTeacher(EncryptedRequest request, CancellationToken cancellationToken)
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
                ResponseHelper.SetError(msg, ex, _logger, nameof(SaveTeacher));
            }
            return StatusCode(msg.StatusCode, ResponseHelper.Encrypt(msg, _configuration.GetValue<string>("AESPassword")!));
        }

        [HttpPost]
        [Route("UpdateTeacher")]
        
        public async Task<IActionResult> UpdateTeacher(EncryptedRequest request, CancellationToken cancellationToken)
        {
            var msg = new Message<TeacherModel>();
            try
            {
                string password = _configuration.GetValue<string>("AESPassword")!;
                string decryptedData = AesGcmEncryptionDecryption.Decrypt(
                    request.data, request.salt, request.nonce, request.tag, password);
                UpdateTeacherRequest data = RequestHelper.DeserializeAndValidate<UpdateTeacherRequest>(decryptedData);

                if (CanAccessTeacher(data.TeacherId))
                {
                    msg = await _teachersService.UpdateTeacher(data, cancellationToken);
                }
                else
                {
                    msg.StatusCode = 403;
                    msg.ReturnMessage = "You do not have permission to update this teacher.";
                }
                msg.ResponseCode = data.RequestCode;
            }
            catch (Exception ex)
            {
                ResponseHelper.SetError(msg, ex, _logger, nameof(UpdateTeacher));
            }
            return StatusCode(msg.StatusCode, ResponseHelper.Encrypt(msg, _configuration.GetValue<string>("AESPassword")!));
        }

        [HttpPost]
        [Route("DeleteTeacher")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> DeleteTeacher(EncryptedRequest request, CancellationToken cancellationToken)
        {
            var msg = new Message<object>();
            try
            {
                string password = _configuration.GetValue<string>("AESPassword")!;
                string decryptedData = AesGcmEncryptionDecryption.Decrypt(
                    request.data, request.salt, request.nonce, request.tag, password);
                TeacherIdRequest data = RequestHelper.DeserializeAndValidate<TeacherIdRequest>(decryptedData);

                msg = await _teachersService.DeleteTeacher(data.TeacherId, cancellationToken);
                msg.ResponseCode = data.RequestCode;
            }
            catch (Exception ex)
            {
                ResponseHelper.SetError(msg, ex, _logger, nameof(DeleteTeacher));
            }
            return StatusCode(msg.StatusCode, ResponseHelper.Encrypt(msg, _configuration.GetValue<string>("AESPassword")!));
        }

        private int CurrentUserId
        {
            get { return int.Parse(User.FindFirst(JwtRegisteredClaimNames.Sub)!.Value); }
        }

        private bool CanAccessTeacher(int teacherId)
        {
            return teacherId == CurrentUserId || User.IsInRole("Admin");
        }
    }
}
