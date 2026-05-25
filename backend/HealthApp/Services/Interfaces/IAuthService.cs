using Domain.Dto.Auth;

namespace Services.Interfaces
{
    public interface IAuthService
    {
        Task<AuthSessionDto> Register(AuthRegisterDto dto, CancellationToken ct);
        Task<AuthSessionDto> SignInWithPassword(AuthLoginDto dto, CancellationToken ct);
        Task<AuthSessionDto> SignInWithGoogle(AuthGoogleSignInDto dto, CancellationToken ct);
        Task<AuthSessionDto> SignInWithYandex(AuthYandexSignInDto dto, CancellationToken ct);
        Task RequestPasswordReset(AuthForgotPasswordRequestDto dto, CancellationToken ct);
        Task ResetPassword(AuthResetPasswordDto dto, CancellationToken ct);
        Task<AuthSessionDto> Refresh(AuthRefreshDto dto, CancellationToken ct);
        Task Logout(AuthLogoutDto dto, CancellationToken ct);
        Task<AuthCurrentUserDto> GetCurrentUser(CancellationToken ct);
    }
}
