using Data.Interfaces;
using Domain.Entity;
using Enums;
using Microsoft.EntityFrameworkCore;

namespace Data.Repositories
{
    public class AuthRepository : IAuthRepository
    {
        private readonly HealthAppDbContext _context;

        public AuthRepository(HealthAppDbContext context)
        {
            _context = context;
        }

        public Task<User?> GetUserByEmail(string normalizedEmail, CancellationToken ct = default)
        {
            return _context.Users
                .Include(x => x.Profile)
                .Include(x => x.ExternalAuthAccounts)
                .FirstOrDefaultAsync(x => x.Email.ToLower() == normalizedEmail, ct);
        }

        public Task<User?> GetUserById(Guid userId, CancellationToken ct = default)
        {
            return _context.Users
                .Include(x => x.Profile)
                .Include(x => x.ExternalAuthAccounts)
                .FirstOrDefaultAsync(x => x.Id == userId, ct);
        }

        public Task<ExternalAuthAccount?> GetExternalAuthAccount(AuthProvider provider, string providerUserId, CancellationToken ct = default)
        {
            return _context.ExternalAuthAccounts
                .Include(x => x.User)
                    .ThenInclude(x => x!.Profile)
                .FirstOrDefaultAsync(x => x.Provider == provider && x.ProviderUserId == providerUserId, ct);
        }

        public Task<AuthRefreshSession?> GetRefreshSession(Guid sessionId, CancellationToken ct = default)
        {
            return _context.AuthRefreshSessions
                .Include(x => x.User)
                    .ThenInclude(x => x!.Profile)
                .FirstOrDefaultAsync(x => x.Id == sessionId, ct);
        }

        public Task<AuthOneTimeCode?> GetLatestActiveOneTimeCode(Guid userId, AuthOneTimeCodePurpose purpose, CancellationToken ct = default)
        {
            var now = DateTime.UtcNow;
            return _context.AuthOneTimeCodes
                .Where(x =>
                    x.UserId == userId &&
                    x.Purpose == purpose &&
                    !x.UsedAt.HasValue &&
                    !x.InvalidatedAt.HasValue &&
                    x.ExpiresAt > now)
                .OrderByDescending(x => x.CreatedAt)
                .FirstOrDefaultAsync(ct);
        }

        public Task AddUser(User user, CancellationToken ct = default)
        {
            ApplyAuditDatesOnCreate(user);
            _context.Users.Add(user);
            return Task.CompletedTask;
        }

        public Task AddExternalAuthAccount(ExternalAuthAccount account, CancellationToken ct = default)
        {
            ApplyAuditDatesOnCreate(account);
            _context.ExternalAuthAccounts.Add(account);
            return Task.CompletedTask;
        }

        public Task AddRefreshSession(AuthRefreshSession session, CancellationToken ct = default)
        {
            ApplyAuditDatesOnCreate(session);
            _context.AuthRefreshSessions.Add(session);
            return Task.CompletedTask;
        }

        public Task AddOneTimeCode(AuthOneTimeCode code, CancellationToken ct = default)
        {
            ApplyAuditDatesOnCreate(code);
            _context.AuthOneTimeCodes.Add(code);
            return Task.CompletedTask;
        }

        public async Task InvalidateActiveOneTimeCodes(Guid userId, AuthOneTimeCodePurpose purpose, DateTime invalidatedAtUtc, CancellationToken ct = default)
        {
            var codes = await _context.AuthOneTimeCodes
                .Where(x =>
                    x.UserId == userId &&
                    x.Purpose == purpose &&
                    !x.UsedAt.HasValue &&
                    !x.InvalidatedAt.HasValue &&
                    x.ExpiresAt > invalidatedAtUtc)
                .ToListAsync(ct);

            foreach (var code in codes)
            {
                code.InvalidatedAt = invalidatedAtUtc;
                code.LastUpdatedAt = invalidatedAtUtc;
            }
        }

        public async Task RevokeActiveRefreshSessions(Guid userId, DateTime revokedAtUtc, CancellationToken ct = default)
        {
            var sessions = await _context.AuthRefreshSessions
                .Where(x => x.UserId == userId && !x.RevokedAt.HasValue && x.ExpiresAt > revokedAtUtc)
                .ToListAsync(ct);

            foreach (var session in sessions)
            {
                session.RevokedAt = revokedAtUtc;
                session.LastUpdatedAt = revokedAtUtc;
            }
        }

        public Task Save(CancellationToken ct = default)
        {
            return _context.SaveChangesAsync(ct);
        }

        private static void ApplyAuditDatesOnCreate(IHasAuditDates entity)
        {
            var now = DateTime.UtcNow;
            if (entity.CreatedAt == default)
            {
                entity.CreatedAt = now;
            }

            entity.LastUpdatedAt = now;
        }
    }
}
