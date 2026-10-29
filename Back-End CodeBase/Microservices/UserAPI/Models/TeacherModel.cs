using System.ComponentModel.DataAnnotations;

namespace UserAPI.Models
{
    public class TeacherModel
    {
        public int Id { get; set; }
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string Subject { get; set; } = string.Empty;
        public string PhoneNumber { get; set; } = string.Empty;
        public string Role { get; set; } = string.Empty;
        public bool IsActive { get; set; }
        public DateTime CreatedAt { get; set; }
    }

    public class RequestModel
    {
        [StringLength(100)]
        public string? RequestCode { get; set; }
    }

    public class TeacherRequest : RequestModel
    {
        [Required, StringLength(100)]
        public string FirstName { get; set; } = string.Empty;
        [Required, StringLength(100)]
        public string LastName { get; set; } = string.Empty;
        [Required, EmailAddress, StringLength(254)]
        public string Email { get; set; } = string.Empty;
        [StringLength(150)]
        public string? Subject { get; set; } = string.Empty;
        [StringLength(30)]
        public string? PhoneNumber { get; set; } = string.Empty;
    }

    public class RegistrationModel : TeacherRequest
    {
        [Required, StringLength(128, MinimumLength = 12)]
        public string Password { get; set; } = string.Empty;
    }

    public class TeacherIdRequest : RequestModel
    {
        [Range(1, int.MaxValue)]
        public int TeacherId { get; set; }
    }

    public class UpdateTeacherRequest : TeacherRequest
    {
        [Range(1, int.MaxValue)]
        public int TeacherId { get; set; }
    }

    public class TeachersListRequest : RequestModel
    {
        [Range(1, int.MaxValue)]
        public int PageNumber { get; set; } = 1;
        [Range(1, 100)]
        public int PageSize { get; set; } = 20;
    }
}
