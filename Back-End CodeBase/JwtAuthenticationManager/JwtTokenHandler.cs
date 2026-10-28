using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using JwtAuthenticationManager.Utility;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;

namespace JwtAuthenticationManager;

public sealed class JwtTokenHandler(IOptions<JwtOptions> options, PostgreSqlTokenStore tokenStore)
{
    public async Task<AuthenticationResponse> GenerateAuthorizedJwtToken(
        int userId, string userName, string role, CancellationToken ct = default)
    {
        var settings = options.Value;
        var now = DateTime.UtcNow;
        var expires = now.AddMinutes(settings.TokenValidityMinutes);
        var tokenId = Guid.NewGuid().ToString("N");
        var token = new JwtSecurityToken(settings.Issuer, settings.Audience,
            [new Claim(JwtRegisteredClaimNames.Sub, userId.ToString()),
             new Claim(JwtRegisteredClaimNames.Name, userName),
             new Claim(JwtRegisteredClaimNames.Jti, tokenId),
             new Claim("role", role)],
            now, expires,
            new SigningCredentials(new SymmetricSecurityKey(Encoding.UTF8.GetBytes(settings.SecurityKey)),
                SecurityAlgorithms.HmacSha256));
        await tokenStore.SaveAsync(userId, tokenId, expires, ct);
        return new(userId, userName, new JwtSecurityTokenHandler().WriteToken(token),
            settings.TokenValidityMinutes * 60);
    }
}
