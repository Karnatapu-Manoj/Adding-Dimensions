using JwtAuthenticationManager;
using UserAPI.Models;

namespace UserAPI.Services
{
    public interface ILoginService
    {
        Task<Message<AuthenticationResponse>> GetLoginUser(AuthenticationRequest request, CancellationToken cancellationToken);
        Task<Message<object>> Logout(int userId, string tokenId, CancellationToken cancellationToken);
    }
}
