using UserAPI.Models;

namespace UserAPI.Services
{
    public interface ITeachersService
    {
        Task<Message<TeacherModel>> GetTeachersList(int pageNumber, int pageSize, CancellationToken cancellationToken);
        Task<Message<TeacherModel>> GetTeacherById(int teacherId, CancellationToken cancellationToken);
        Task<Message<TeacherModel>> SaveTeacher(RegistrationModel request, string role, CancellationToken cancellationToken);
        Task<Message<TeacherModel>> UpdateTeacher(UpdateTeacherRequest request, CancellationToken cancellationToken);
        Task<Message<object>> DeleteTeacher(int teacherId, CancellationToken cancellationToken);
    }
}
