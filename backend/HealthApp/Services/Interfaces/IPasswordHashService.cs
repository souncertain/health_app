using Domain.Entity;

namespace Services.Interfaces
{
    public interface IPasswordHashService
    {
        string HashPassword(User user, string password);
        PasswordVerificationResult VerifyPassword(User user, string? storedHash, string password);
    }

    public enum PasswordVerificationResult
    {
        Failed = 0,
        Success = 1,
        SuccessRehashNeeded = 2
    }
}
