using System.Data;
using JwtAuthenticationManager;
using JwtAuthenticationManager.Utility;
using Microsoft.AspNetCore.Identity;
using Npgsql;
using NpgsqlTypes;
using Newtonsoft.Json.Linq;
using ReportAPI.Models;
using ReportAPI.Utility;

namespace ReportAPI.Services
{
    public class PortalAccountService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<PortalAccountService> _logger;
        private readonly IPasswordHasher<PortalUserModel> _passwordHasher;
        private readonly PortalJwtTokenHandler _tokenHandler;
        private readonly PortalSessionStore _sessions;
        private readonly PortalOtpService _otp;
        private readonly PortalPii _pii;
        private static readonly PortalUserModel DummyUser = new PortalUserModel();
        private static readonly string DummyHash = new PasswordHasher<PortalUserModel>().HashPassword(DummyUser, Guid.NewGuid().ToString());

        public PortalAccountService(IConfiguration configuration, ILogger<PortalAccountService> logger,
            IPasswordHasher<PortalUserModel> passwordHasher, PortalJwtTokenHandler tokenHandler, PortalSessionStore sessions,
            PortalOtpService otp, PortalPii pii)
        {
            _configuration = configuration; _logger = logger; _passwordHasher = passwordHasher;
            _tokenHandler = tokenHandler; _sessions = sessions;
            _otp = otp; _pii = pii;
        }

        public async Task<Message<PortalLoginResponse>> Login(PortalLoginRequest request, CancellationToken ct)
        {
            var msg = new Message<PortalLoginResponse>();
            try
            {
                string connectionString = _configuration.GetConnectionString("DBConnection")!;
                List<NpgsqlParameter> sqlParams = new List<NpgsqlParameter>
                {
                    new NpgsqlParameter("p_login_id", NpgsqlDbType.Varchar) { Value = request.UserName },
                    new NpgsqlParameter("p_contact_hash", NpgsqlDbType.Varchar) { Value = _pii.ContactHash(request.UserName) }
                };
                using (DataTable dt = await SqlHelper.ExecuteDataTable(sqlParams,"public.usp_portal_login_lookup",connectionString,ct))
                {
                    DataRow? row = dt.Rows.Count == 1 ? dt.Rows[0] : null;
                    string hash = row == null ? DummyHash : Convert.ToString(row["password_hash"])!;
                    bool passwordValid = _passwordHasher.VerifyHashedPassword(DummyUser, hash, request.Password) != PasswordVerificationResult.Failed;
                    bool locked = row != null && row["locked_until"] != DBNull.Value && Convert.ToDateTime(row["locked_until"]).ToUniversalTime() > DateTime.UtcNow;
                    bool success = row != null && Convert.ToBoolean(row["is_active"]) && passwordValid && !locked;
                    long userId = row == null ? 0 : Convert.ToInt64(row["user_id"]);
                    List<NpgsqlParameter> resultParams = new List<NpgsqlParameter>
                    {
                        new NpgsqlParameter("p_user_id",NpgsqlDbType.Bigint) { Value = row == null ? DBNull.Value : userId },
                        new NpgsqlParameter("p_success",NpgsqlDbType.Boolean) { Value = success },
                        new NpgsqlParameter("p_login_id",NpgsqlDbType.Varchar) { Value = request.UserName }
                    };
                    if (!success) await SqlHelper.ExecuteNonQuery(resultParams,"public.usp_portal_login_result",connectionString,ct);
                    if (!success)
                    {
                        msg.StatusCode = 401; msg.ReturnMessage = "The user ID or password is incorrect, or this account is inactive or temporarily locked.";
                        return msg;
                    }
                    JObject contact = _pii.Reveal(JObject.Parse(Convert.ToString(row!["contact_data"])!), true);
                    string recipient = contact.Value<string>("email") ?? contact.Value<string>("phone") ?? contact.Value<string>("mobile") ?? Convert.ToString(row["login_id"])!;
                    JObject challenge = await _otp.Create("LOGIN", userId, recipient, new JObject(), ct);
                    msg.Data = new PortalLoginResponse { RequiresOtp = true, ChallengeId = challenge.Value<string>("challengeId")!,
                        ExpiresAt = new DateTimeOffset(challenge.Value<DateTime>("expiresAt").ToUniversalTime()), OutboxPath = challenge.Value<string>("outboxPath")!,
                        Message = challenge.Value<string>("message")! };
                    msg.IsSuccess = true; msg.StatusCode = 200; msg.ReturnMessage = "Password verified. OTP verification is required.";
                }
            }
            catch (Exception ex) { ResponseHelper.SetError(msg,ex,_logger,nameof(Login)); }
            return msg;
        }

        public async Task<Message<PortalLoginResponse>> VerifyLogin(PortalOtpRequest request, CancellationToken ct)
        {
            var msg = new Message<PortalLoginResponse>();
            try
            {
                JObject verified = await _otp.Verify("LOGIN", request.ChallengeId, request.Otp, ct);
                long userId = verified.Value<long>("userId");
                var user = new PortalUserModel { Id = userId, UserId = verified.Value<string>("loginId")!,
                    Role = verified.Value<string>("role")!, Active = true };
                var sqlParams = new List<NpgsqlParameter>
                {
                    new NpgsqlParameter("p_user_id", NpgsqlDbType.Bigint) { Value = userId },
                    new NpgsqlParameter("p_success", NpgsqlDbType.Boolean) { Value = true },
                    new NpgsqlParameter("p_login_id", NpgsqlDbType.Varchar) { Value = user.UserId }
                };
                await SqlHelper.ExecuteNonQuery(sqlParams, "public.usp_portal_login_result", _configuration.GetConnectionString("DBConnection")!, ct);
                string token = await _tokenHandler.GenerateToken(userId, user.UserId, user.Role, ct);
                msg.Data = new PortalLoginResponse { User = user, JwtToken = token };
                msg.IsSuccess = true; msg.StatusCode = 200; msg.ReturnMessage = "Login successful.";
            }
            catch (Exception ex) { ResponseHelper.SetError(msg, ex, _logger, nameof(VerifyLogin)); }
            return msg;
        }

        public async Task<Message<JObject>> RequestPasswordReset(PortalIdentityRequest request, CancellationToken ct)
        {
            var msg = new Message<JObject>();
            try
            {
                var sqlParams = new List<NpgsqlParameter>
                {
                    new NpgsqlParameter("p_login_id", NpgsqlDbType.Varchar) { Value = request.UserName },
                    new NpgsqlParameter("p_contact_hash", NpgsqlDbType.Varchar) { Value = _pii.ContactHash(request.UserName) }
                };
                using (DataTable dt = await SqlHelper.ExecuteDataTable(sqlParams, "public.usp_portal_login_lookup", _configuration.GetConnectionString("DBConnection")!, ct))
                {
                    DataRow? row = dt.Rows.Count == 1 ? dt.Rows[0] : null;
                    JObject contact = row == null ? new JObject() : _pii.Reveal(JObject.Parse(Convert.ToString(row["contact_data"])!), true);
                    string recipient = contact.Value<string>("email") ?? contact.Value<string>("phone") ?? contact.Value<string>("mobile") ?? request.UserName;
                    msg.Data = await _otp.Create("PASSWORD_RESET", row == null ? null : Convert.ToInt64(row["user_id"]), recipient,
                        new JObject { ["loginId"] = row == null ? "" : Convert.ToString(row["login_id"]) }, ct);
                    msg.IsSuccess = true; msg.StatusCode = 200; msg.ReturnMessage = "Verify the code to reset your password.";
                }
            }
            catch (Exception ex) { ResponseHelper.SetError(msg, ex, _logger, nameof(RequestPasswordReset)); }
            return msg;
        }

        public async Task<Message<JObject>> ResetPassword(PortalResetPasswordRequest request, CancellationToken ct)
        {
            var msg = new Message<JObject>();
            try
            {
                JObject result = await _otp.Verify("PASSWORD_RESET", request.ChallengeId, request.Otp, ct);
                long? userId = result.Value<long?>("userId");
                if (userId == null) throw new System.ComponentModel.DataAnnotations.ValidationException("This account could not be reset. Contact an administrator.");
                string loginId = result["payload"]!.Value<string>("loginId")!;
                if (System.Text.RegularExpressions.Regex.IsMatch(loginId, "^Demo[1-8]$", System.Text.RegularExpressions.RegexOptions.IgnoreCase))
                    throw new System.ComponentModel.DataAnnotations.ValidationException("Demo credentials are preserved. Continue using the existing demo password.");
                var sqlParams = new List<NpgsqlParameter>
                {
                    new NpgsqlParameter("p_user_id", NpgsqlDbType.Bigint) { Value = userId.Value },
                    new NpgsqlParameter("p_password_hash", NpgsqlDbType.Varchar) { Value = _passwordHasher.HashPassword(new PortalUserModel(), request.NewPassword) }
                };
                await SqlHelper.ExecuteNonQuery(sqlParams, "public.usp_portal_reset_password", _configuration.GetConnectionString("DBConnection")!, ct);
                msg.Data = new JObject { ["message"] = "Your password has been reset. Sign in with the new password and a fresh verification code." };
                msg.IsSuccess = true; msg.StatusCode = 200; msg.ReturnMessage = "Password reset successful.";
            }
            catch (Exception ex) { ResponseHelper.SetError(msg, ex, _logger, nameof(ResetPassword)); }
            return msg;
        }

        public async Task<Message<object>> Logout(long userId,string tokenId,CancellationToken ct)
        {
            var msg = new Message<object>();
            try
            {
                await _sessions.Logout(userId,tokenId,ct);
                msg.IsSuccess=true;msg.StatusCode=200;msg.ReturnMessage="Logout successful.";
            }
            catch (Exception ex) { ResponseHelper.SetError(msg,ex,_logger,nameof(Logout)); }
            return msg;
        }
    }
}
