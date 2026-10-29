using System.ComponentModel.DataAnnotations;

namespace UserAPI.Utility
{
    public class EncryptionOptions
    {
        [Required, MinLength(32)]
        public string AESPassword { get; set; } = string.Empty;
    }
}
