using System.ComponentModel.DataAnnotations;

namespace ReportAPI.Utility
{
    public class EncryptionOptions
    {
        [Required, MinLength(32)]
        public string AESPassword { get; set; } = string.Empty;
    }
}
