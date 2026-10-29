using System.ComponentModel.DataAnnotations;
using ReportAPI.Models;
using ReportAPI.Services;

namespace ReportAPI.Utility
{
    public static class AdminBootstrap
    {
        public static async Task SeedAdmin(IServiceProvider services, IConfiguration configuration)
        {
            var request = new RegistrationModel
            {
                FirstName = "Adding Dimensions",
                LastName = "Administrator",
                Email = configuration["BootstrapAdmin:Email"] ?? string.Empty,
                Password = configuration["BootstrapAdmin:Password"] ?? string.Empty
            };
            Validator.ValidateObject(request, new ValidationContext(request), true);
            ITeachersService teachersService = services.GetRequiredService<ITeachersService>();
            Message<TeacherModel> msg = await teachersService.SaveTeacher(request, "Admin", default);
            if (!msg.IsSuccess)
            {
                throw new InvalidOperationException(msg.ReturnMessage);
            }
        }
    }
}
