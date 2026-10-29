using System.ComponentModel.DataAnnotations;
using Newtonsoft.Json.Linq;

namespace ReportAPI.Models
{
    public class PortalLoginRequest : RequestModel
    {
        [Required, StringLength(150)] public string UserName { get; set; } = string.Empty;
        [Required, StringLength(128)] public string Password { get; set; } = string.Empty;
    }
    public class PortalChangesRequest : RequestModel
    {
        public JArray Upserts { get; set; } = new JArray();
        public JArray Deletes { get; set; } = new JArray();
    }
    public class PortalUserModel
    {
        public long Id { get; set; }
        public string UserId { get; set; } = string.Empty;
        public string Role { get; set; } = string.Empty;
        public bool Active { get; set; }
    }
    public class PortalLoginResponse
    {
        public bool RequiresOtp { get; set; }
        public string ChallengeId { get; set; } = string.Empty;
        public string OutboxPath { get; set; } = string.Empty;
        public string Message { get; set; } = string.Empty;
        public DateTimeOffset? ExpiresAt { get; set; }
        public PortalUserModel User { get; set; } = new PortalUserModel();
        public string JwtToken { get; set; } = string.Empty;
    }
    public class PortalOtpRequest : RequestModel
    {
        [Required] public string ChallengeId { get; set; } = string.Empty;
        [Required, RegularExpression("^[0-9]{6}$")] public string Otp { get; set; } = string.Empty;
    }
    public class PortalIdentityRequest : RequestModel
    {
        [Required, StringLength(150)] public string UserName { get; set; } = string.Empty;
    }
    public class PortalResetPasswordRequest : PortalOtpRequest
    {
        [Required, StringLength(128, MinimumLength = 10)] public string NewPassword { get; set; } = string.Empty;
    }
}
