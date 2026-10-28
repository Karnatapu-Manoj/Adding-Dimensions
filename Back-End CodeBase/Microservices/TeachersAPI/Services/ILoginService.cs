using JwtAuthenticationManager;
using TeachersAPI.Models;

namespace TeachersAPI.Services
{
    public interface ILoginService
    {
        Task<Message<AuthenticationResponse>> GetLoginUser(AuthenticationRequest request, CancellationToken cancellationToken);
        Task<Message<object>> Logout(int userId, string tokenId, CancellationToken cancellationToken);
    }
}
