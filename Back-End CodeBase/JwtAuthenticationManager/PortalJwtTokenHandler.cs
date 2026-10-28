using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;

namespace JwtAuthenticationManager
{
    public class PortalJwtTokenHandler
    {
        private readonly IOptions<JwtOptions> _options;
        private readonly PortalSessionStore _sessionStore;
        public PortalJwtTokenHandler(IOptions<JwtOptions> options, PortalSessionStore sessionStore)
        {
            _options = options;
            _sessionStore = sessionStore;
        }

        public async Task<string> GenerateToken(long userId, string loginId, string role, CancellationToken ct)
        {
            JwtOptions settings = _options.Value;
            DateTime now = DateTime.UtcNow;
            DateTime expiresAt = now.AddMinutes(settings.TokenValidityMinutes);
            string tokenId = Guid.NewGuid().ToString("N");
            List<Claim> claims = new List<Claim>
            {
                new Claim(JwtRegisteredClaimNames.Sub, userId.ToString()),
                new Claim(JwtRegisteredClaimNames.Name, loginId),
                new Claim(JwtRegisteredClaimNames.Jti, tokenId),
                new Claim("role", role), new Claim("identity_kind", "app_user")
            };
            JwtSecurityToken token = new JwtSecurityToken(settings.Issuer, settings.Audience, claims, now, expiresAt,
                new SigningCredentials(new SymmetricSecurityKey(Encoding.UTF8.GetBytes(settings.SecurityKey)), SecurityAlgorithms.HmacSha256));
            await _sessionStore.SaveSession(userId, tokenId, expiresAt, role, ct);
            return new JwtSecurityTokenHandler().WriteToken(token);
        }
    }
}
