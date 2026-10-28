using System.ComponentModel.DataAnnotations;

namespace TeachersAPI.Utility
{
    public class EncryptionOptions
    {
        [Required, MinLength(32)]
        public string AESPassword { get; set; } = string.Empty;
    }
}
