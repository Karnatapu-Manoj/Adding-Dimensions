namespace JwtAuthenticationManager;

public sealed record AuthenticationResponse(int UserId, string UserName, string JwtToken, int ExpiresIn);
