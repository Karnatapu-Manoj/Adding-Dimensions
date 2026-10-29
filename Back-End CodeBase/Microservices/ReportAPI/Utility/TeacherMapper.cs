using System.Data;
using ReportAPI.Models;

namespace ReportAPI.Utility
{
    public static class TeacherMapper
    {
        public static TeacherModel MapTeacher(DataRow row)
        {
            return new TeacherModel
            {
                Id = Convert.ToInt32(row["id"]),
                FirstName = Convert.ToString(row["first_name"]) ?? string.Empty,
                LastName = Convert.ToString(row["last_name"]) ?? string.Empty,
                Email = Convert.ToString(row["email"]) ?? string.Empty,
                Subject = Convert.ToString(row["subject"]) ?? string.Empty,
                PhoneNumber = Convert.ToString(row["phone_number"]) ?? string.Empty,
                Role = Convert.ToString(row["role"]) ?? string.Empty,
                IsActive = Convert.ToBoolean(row["is_active"]),
                CreatedAt = Convert.ToDateTime(row["created_at"])
            };
        }
    }
}
