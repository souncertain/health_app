using HealthApp.Configuration;
using Microsoft.Extensions.Options;
using Services.Interfaces;

namespace HealthApp.Infrastructure.Auth
{
    public class EmailConfirmationPolicy : IEmailConfirmationPolicy
    {
        private readonly EmailConfirmationOptions _options;

        public EmailConfirmationPolicy(IOptions<AuthOptions> authOptions)
        {
            _options = authOptions.Value.EmailConfirmation ?? new EmailConfirmationOptions();
        }

        public int CodeLength => Math.Max(4, _options.CodeLength);
        public int MaxAttempts => Math.Clamp(_options.MaxAttempts, 1, 20);
        public TimeSpan CodeLifetime => TimeSpan.FromMinutes(Math.Max(1, _options.LifetimeMinutes));
        public TimeSpan ResendCooldown => TimeSpan.FromSeconds(Math.Max(0, _options.ResendCooldownSeconds));
    }
}
