using Domain.Entity;
using Enums;

namespace Services.Interfaces
{
    public interface IJwtTokenFactory
    {
        (string Token, DateTime ExpiresAtUtc) CreateAccessToken(User user, AuthProvider provider, string displayName);
    }
}
