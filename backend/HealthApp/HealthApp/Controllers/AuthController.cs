using Domain.Dto.Auth;
using Domain.Exceptions;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Services.Interfaces;

namespace HealthApp.Controllers
{
    [ApiController]
    [Route("api/auth")]
    public class AuthController : ControllerBase
    {
        private readonly IAuthService _authService;

        public AuthController(IAuthService authService)
        {
            _authService = authService;
        }

        [AllowAnonymous]
        [HttpPost("register")]
        public Task<AuthSessionDto> Register([FromBody] AuthRegisterDto dto, CancellationToken ct)
        {
            return _authService.Register(dto, ct);
        }

        [AllowAnonymous]
        [HttpPost("login")]
        public Task<AuthSessionDto> Login([FromBody] AuthLoginDto dto, CancellationToken ct)
        {
            return _authService.SignInWithPassword(dto, ct);
        }

        [AllowAnonymous]
        [HttpPost("google")]
        public Task<AuthSessionDto> Google([FromBody] AuthGoogleSignInDto dto, CancellationToken ct)
        {
            return _authService.SignInWithGoogle(dto, ct);
        }

        [AllowAnonymous]
        [HttpPost("yandex")]
        public Task<AuthSessionDto> Yandex([FromBody] AuthYandexSignInDto dto, CancellationToken ct)
        {
            return _authService.SignInWithYandex(dto, ct);
        }

        [AllowAnonymous]
        [HttpPost("forgot-password")]
        public async Task<IActionResult> ForgotPassword([FromBody] AuthForgotPasswordRequestDto dto, CancellationToken ct)
        {
            await _authService.RequestPasswordReset(dto, ct);
            return NoContent();
        }

        [AllowAnonymous]
        [HttpPost("reset-password")]
        public async Task<IActionResult> ResetPassword([FromBody] AuthResetPasswordDto dto, CancellationToken ct)
        {
            await _authService.ResetPassword(dto, ct);
            return NoContent();
        }

        [AllowAnonymous]
        [HttpPost("refresh")]
        public Task<AuthSessionDto> Refresh([FromBody] AuthRefreshDto dto, CancellationToken ct)
        {
            return _authService.Refresh(dto, ct);
        }

        [AllowAnonymous]
        [HttpPost("logout")]
        public async Task<IActionResult> Logout([FromBody] AuthLogoutDto dto, CancellationToken ct)
        {
            await _authService.Logout(dto, ct);
            return NoContent();
        }

        [Authorize]
        [HttpGet("me")]
        public Task<AuthCurrentUserDto> Me(CancellationToken ct)
        {
            return _authService.GetCurrentUser(ct);
        }
    }
}
