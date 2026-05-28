using Services.Interfaces;
using System.Collections.Concurrent;

namespace HealthApp.IntegrationTests.Infrastructure;

internal sealed class NoOpAccountEmailSender : IAccountEmailSender
{
    public static ConcurrentDictionary<string, string> EmailConfirmationCodes { get; } = new(StringComparer.OrdinalIgnoreCase);
    public static ConcurrentDictionary<string, string> PasswordResetCodes { get; } = new(StringComparer.OrdinalIgnoreCase);

    public Task SendEmailConfirmationCode(string toEmail, string code, TimeSpan lifetime, CancellationToken ct)
    {
        EmailConfirmationCodes[toEmail] = code;
        return Task.CompletedTask;
    }

    public Task SendPasswordResetCode(string toEmail, string code, TimeSpan lifetime, CancellationToken ct)
    {
        PasswordResetCodes[toEmail] = code;
        return Task.CompletedTask;
    }
}
