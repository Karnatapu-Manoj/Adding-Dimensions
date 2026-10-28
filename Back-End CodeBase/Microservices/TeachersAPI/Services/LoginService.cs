using System.Data;
using JwtAuthenticationManager;
using JwtAuthenticationManager.Utility;
using Microsoft.AspNetCore.Identity;
using Npgsql;
using NpgsqlTypes;
using TeachersAPI.Models;
using TeachersAPI.Utility;

namespace TeachersAPI.Services
{
    public class LoginService : ILoginService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<LoginService> _logger;
        private readonly IPasswordHasher<RegistrationModel> _passwordHasher;
        private readonly JwtTokenHandler _jwtTokenHandler;
        private readonly PostgreSqlTokenStore _tokenStore;
        private static readonly RegistrationModel DummyUser = new RegistrationModel();
        private static readonly string DummyHash = new PasswordHasher<RegistrationModel>()
            .HashPassword(DummyUser, Guid.NewGuid().ToString());

        public LoginService(IConfiguration configuration, ILogger<LoginService> logger,
            IPasswordHasher<RegistrationModel> passwordHasher, JwtTokenHandler jwtTokenHandler,
            PostgreSqlTokenStore tokenStore)
        {
            _configuration = configuration;
            _logger = logger;
            _passwordHasher = passwordHasher;
            _jwtTokenHandler = jwtTokenHandler;
            _tokenStore = tokenStore;
        }

        public async Task<Message<AuthenticationResponse>> GetLoginUser(AuthenticationRequest request,
            CancellationToken cancellationToken)
        {
            var msg = new Message<AuthenticationResponse>();
            try
            {
                string connectionString = _configuration.GetConnectionString("DBConnection")!;
                List<NpgsqlParameter> sqlParams = new List<NpgsqlParameter>
                {
                    new NpgsqlParameter("p_email", NpgsqlDbType.Varchar) { Value = request.UserName }
                };
                using (DataTable dt = await SqlHelper.ExecuteDataTable(sqlParams, StoredProcedure.USP_GetLoginUser,
                    connectionString, cancellationToken))
                {
                    string passwordHash = dt.Rows.Count > 0 ? Convert.ToString(dt.Rows[0]["password_hash"])! : DummyHash;
                    PasswordVerificationResult passwordResult = _passwordHasher.VerifyHashedPassword(
                        DummyUser, passwordHash, request.Password);
                    if (dt.Rows.Count == 0 || passwordResult == PasswordVerificationResult.Failed ||
                        !Convert.ToBoolean(dt.Rows[0]["is_active"]))
                    {
                        msg.StatusCode = 401;
                        msg.ReturnMessage = "Invalid username or password.";
                        return msg;
                    }

                    int userId = Convert.ToInt32(dt.Rows[0]["id"]);
                    string userName = Convert.ToString(dt.Rows[0]["email"])!;
                    string role = Convert.ToString(dt.Rows[0]["role"])!;
                    AuthenticationResponse token = await _jwtTokenHandler.GenerateAuthorizedJwtToken(
                        userId, userName, role, cancellationToken);
                    msg.Data = token;
                    msg.JWTToken = token.JwtToken;
                    msg.UserId = userId;
                    msg.UserName = userName;
                    msg.StatusCode = 200;
                    msg.IsSuccess = true;
                    msg.ReturnMessage = "Login successful.";
                }
            }
            catch (Exception ex)
            {
                ResponseHelper.SetError(msg, ex, _logger, nameof(GetLoginUser));
            }
            return msg;
        }

        public async Task<Message<object>> Logout(int userId, string tokenId, CancellationToken cancellationToken)
        {
            var msg = new Message<object>();
            try
            {
                await _tokenStore.RevokeAsync(userId, tokenId, cancellationToken);
                msg.StatusCode = 200;
                msg.IsSuccess = true;
                msg.ReturnMessage = "Logout successful.";
            }
            catch (Exception ex)
            {
                ResponseHelper.SetError(msg, ex, _logger, nameof(Logout));
            }
            return msg;
        }
    }
}
