using System.ComponentModel.DataAnnotations;

namespace JwtAuthenticationManager
{
    public class AuthenticationRequest
    {
        [Required, EmailAddress, StringLength(254)]
        public string UserName { get; set; } = string.Empty;

        [Required, StringLength(128)]
        public string Password { get; set; } = string.Empty;

        [StringLength(100)]
        public string? RequestCode { get; set; }
    }
}
