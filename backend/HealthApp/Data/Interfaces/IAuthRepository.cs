using Domain.Entity;
using Enums;

namespace Data.Interfaces
{
    public interface IAuthRepository
    {
        Task<User?> GetUserByEmail(string normalizedEmail, CancellationToken ct = default);
        Task<User?> GetUserById(Guid userId, CancellationToken ct = default);
        Task<ExternalAuthAccount?> GetExternalAuthAccount(AuthProvider provider, string providerUserId, CancellationToken ct = default);
        Task<AuthRefreshSession?> GetRefreshSession(Guid sessionId, CancellationToken ct = default);
        Task<AuthOneTimeCode?> GetLatestActiveOneTimeCode(Guid userId, AuthOneTimeCodePurpose purpose, CancellationToken ct = default);
        Task AddUser(User user, CancellationToken ct = default);
        Task AddExternalAuthAccount(ExternalAuthAccount account, CancellationToken ct = default);
        Task AddRefreshSession(AuthRefreshSession session, CancellationToken ct = default);
        Task AddOneTimeCode(AuthOneTimeCode code, CancellationToken ct = default);
        Task InvalidateActiveOneTimeCodes(Guid userId, AuthOneTimeCodePurpose purpose, DateTime invalidatedAtUtc, CancellationToken ct = default);
        Task RevokeActiveRefreshSessions(Guid userId, DateTime revokedAtUtc, CancellationToken ct = default);
        Task Save(CancellationToken ct = default);
    }
}
