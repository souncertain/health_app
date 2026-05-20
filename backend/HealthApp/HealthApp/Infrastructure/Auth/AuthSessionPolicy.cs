using HealthApp.Configuration;
using Microsoft.Extensions.Options;
using Services.Interfaces;

namespace HealthApp.Infrastructure.Auth
{
    public class AuthSessionPolicy : IAuthSessionPolicy
    {
        private readonly IOptions<AuthOptions> _authOptions;

        public AuthSessionPolicy(IOptions<AuthOptions> authOptions)
        {
            _authOptions = authOptions;
        }

        public TimeSpan RefreshTokenLifetime => TimeSpan.FromHours(
            Math.Max(1, _authOptions.Value.RefreshTokens.LifetimeHours));

        public bool UseSlidingRefreshExpiration => _authOptions.Value.RefreshTokens.UseSlidingExpiration;
    }
}
