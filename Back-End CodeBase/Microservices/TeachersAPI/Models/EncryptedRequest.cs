using System.ComponentModel.DataAnnotations;

namespace TeachersAPI.Models
{
    public class EncryptedRequest
    {
        [Required, MaxLength(2000000)]
        public string data { get; set; } = string.Empty;
        [Required, MaxLength(24)]
        public string salt { get; set; } = string.Empty;
        [Required, MaxLength(16)]
        public string nonce { get; set; } = string.Empty;
        [Required, MaxLength(24)]
        public string tag { get; set; } = string.Empty;
    }
}
