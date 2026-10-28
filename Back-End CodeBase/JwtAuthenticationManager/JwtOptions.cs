using System.ComponentModel.DataAnnotations;

namespace JwtAuthenticationManager;

public sealed class JwtOptions
{
    public const string SectionName = "Jwt";
    [Required] public string Issuer { get; set; } = string.Empty;
    [Required] public string Audience { get; set; } = string.Empty;
    [Required, MinLength(32)] public string SecurityKey { get; set; } = string.Empty;
    [Range(1, 1440)] public int TokenValidityMinutes { get; set; } = 60;
}
