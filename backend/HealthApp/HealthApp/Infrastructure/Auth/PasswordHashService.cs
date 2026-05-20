using Domain.Entity;
using Microsoft.AspNetCore.Identity;
using Services.Interfaces;
using System.Text;

namespace HealthApp.Infrastructure.Auth
{
    public class PasswordHashService : IPasswordHashService
    {
        private const string LegacyPrefix = "legacy:";
        private readonly PasswordHasher<User> _passwordHasher = new();

        public string HashPassword(User user, string password)
        {
            return _passwordHasher.HashPassword(user, password);
        }

        public Services.Interfaces.PasswordVerificationResult VerifyPassword(User user, string? storedHash, string password)
        {
            if (string.IsNullOrWhiteSpace(storedHash))
            {
                return Services.Interfaces.PasswordVerificationResult.Failed;
            }

            if (storedHash.StartsWith(LegacyPrefix, StringComparison.Ordinal))
            {
                var payload = storedHash[LegacyPrefix.Length..];
                try
                {
                    var legacyPassword = Encoding.UTF8.GetString(Convert.FromBase64String(payload));
                    return string.Equals(legacyPassword, password, StringComparison.Ordinal)
                        ? Services.Interfaces.PasswordVerificationResult.SuccessRehashNeeded
                        : Services.Interfaces.PasswordVerificationResult.Failed;
                }
                catch (FormatException)
                {
                    return Services.Interfaces.PasswordVerificationResult.Failed;
                }
            }

            return _passwordHasher.VerifyHashedPassword(user, storedHash, password) switch
            {
                Microsoft.AspNetCore.Identity.PasswordVerificationResult.Success => Services.Interfaces.PasswordVerificationResult.Success,
                Microsoft.AspNetCore.Identity.PasswordVerificationResult.SuccessRehashNeeded => Services.Interfaces.PasswordVerificationResult.SuccessRehashNeeded,
                _ => Services.Interfaces.PasswordVerificationResult.Failed
            };
        }
    }
}
