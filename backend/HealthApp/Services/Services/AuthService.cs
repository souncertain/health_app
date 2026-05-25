using Data.Interfaces;
using Domain.Dto.Auth;
using Domain.Entity;
using Domain.Exceptions;
using Enums;
using Services.Interfaces;
using System.Globalization;
using System.Net;

namespace Services.Services
{
    public class AuthService : IAuthService
    {
        private readonly IAuthRepository _repository;
        private readonly IGoogleIdentityTokenValidator _googleIdentityTokenValidator;
        private readonly IYandexIdentityProviderClient _yandexIdentityProviderClient;
        private readonly IJwtTokenFactory _jwtTokenFactory;
        private readonly IPasswordHashService _passwordHashService;
        private readonly IRefreshTokenFactory _refreshTokenFactory;
        private readonly IOneTimeCodeFactory _oneTimeCodeFactory;
        private readonly IAuthSessionPolicy _sessionPolicy;
        private readonly IPasswordResetPolicy _passwordResetPolicy;
        private readonly IAccountEmailSender _accountEmailSender;
        private readonly ICurrentUserContext _currentUserContext;

        public AuthService(
            IAuthRepository repository,
            IGoogleIdentityTokenValidator googleIdentityTokenValidator,
            IYandexIdentityProviderClient yandexIdentityProviderClient,
            IJwtTokenFactory jwtTokenFactory,
            IPasswordHashService passwordHashService,
            IRefreshTokenFactory refreshTokenFactory,
            IOneTimeCodeFactory oneTimeCodeFactory,
            IAuthSessionPolicy sessionPolicy,
            IPasswordResetPolicy passwordResetPolicy,
            IAccountEmailSender accountEmailSender,
            ICurrentUserContext currentUserContext)
        {
            _repository = repository;
            _googleIdentityTokenValidator = googleIdentityTokenValidator;
            _yandexIdentityProviderClient = yandexIdentityProviderClient;
            _jwtTokenFactory = jwtTokenFactory;
            _passwordHashService = passwordHashService;
            _refreshTokenFactory = refreshTokenFactory;
            _oneTimeCodeFactory = oneTimeCodeFactory;
            _sessionPolicy = sessionPolicy;
            _passwordResetPolicy = passwordResetPolicy;
            _accountEmailSender = accountEmailSender;
            _currentUserContext = currentUserContext;
        }

        public async Task<AuthSessionDto> Register(AuthRegisterDto dto, CancellationToken ct)
        {
            var normalizedEmail = NormalizeEmail(dto.Email);
            var existingUser = await _repository.GetUserByEmail(normalizedEmail, ct);
            if (existingUser is not null)
            {
                throw new AuthException("A user with this email already exists.", HttpStatusCode.Conflict);
            }

            var user = new User
            {
                Id = Guid.NewGuid(),
                Email = normalizedEmail,
                Phone = NormalizeOptional(dto.Phone)
            };
            user.PasswordHash = _passwordHashService.HashPassword(user, dto.Password);

            await _repository.AddUser(user, ct);

            var session = await IssueSession(
                user,
                AuthProvider.Password,
                dto.DeviceId,
                dto.DeviceName,
                fallbackDisplayName: null,
                ct);

            await _repository.Save(ct);
            return session;
        }

        public async Task<AuthSessionDto> SignInWithPassword(AuthLoginDto dto, CancellationToken ct)
        {
            var normalizedEmail = NormalizeEmail(dto.Email);
            var user = await _repository.GetUserByEmail(normalizedEmail, ct);
            if (user is null)
            {
                throw new AuthException("Invalid email or password.", HttpStatusCode.Unauthorized);
            }

            var verifyResult = _passwordHashService.VerifyPassword(user, user.PasswordHash, dto.Password);
            if (verifyResult == PasswordVerificationResult.Failed)
            {
                throw new AuthException("Invalid email or password.", HttpStatusCode.Unauthorized);
            }

            if (verifyResult == PasswordVerificationResult.SuccessRehashNeeded)
            {
                user.PasswordHash = _passwordHashService.HashPassword(user, dto.Password);
                user.LastUpdatedAt = DateTime.UtcNow;
            }

            var session = await IssueSession(
                user,
                AuthProvider.Password,
                dto.DeviceId,
                dto.DeviceName,
                fallbackDisplayName: null,
                ct);

            await _repository.Save(ct);
            return session;
        }

        public async Task<AuthSessionDto> SignInWithGoogle(AuthGoogleSignInDto dto, CancellationToken ct)
        {
            var externalProfile = await _googleIdentityTokenValidator.Validate(dto.IdToken, ct);
            var user = await ResolveExternalUser(externalProfile, ct);

            var session = await IssueSession(
                user,
                AuthProvider.Google,
                dto.DeviceId,
                dto.DeviceName,
                externalProfile.DisplayName,
                ct);

            await _repository.Save(ct);
            return session;
        }

        public async Task<AuthSessionDto> SignInWithYandex(AuthYandexSignInDto dto, CancellationToken ct)
        {
            var externalProfile = await _yandexIdentityProviderClient.GetProfile(dto.AccessToken, ct);
            var user = await ResolveExternalUser(externalProfile, ct);

            var session = await IssueSession(
                user,
                AuthProvider.Yandex,
                dto.DeviceId,
                dto.DeviceName,
                externalProfile.DisplayName,
                ct);

            await _repository.Save(ct);
            return session;
        }

        public async Task RequestPasswordReset(AuthForgotPasswordRequestDto dto, CancellationToken ct)
        {
            var normalizedEmail = NormalizeEmail(dto.Email);
            var user = await _repository.GetUserByEmail(normalizedEmail, ct);
            if (user is null)
            {
                return;
            }

            var now = DateTime.UtcNow;
            var latestCode = await _repository.GetLatestActiveOneTimeCode(
                user.Id,
                AuthOneTimeCodePurpose.PasswordReset,
                ct);

            if (latestCode is not null && now - latestCode.CreatedAt < _passwordResetPolicy.ResendCooldown)
            {
                return;
            }

            await _repository.InvalidateActiveOneTimeCodes(
                user.Id,
                AuthOneTimeCodePurpose.PasswordReset,
                now,
                ct);

            var code = _oneTimeCodeFactory.CreateNumericCode(_passwordResetPolicy.CodeLength);
            var authCode = new AuthOneTimeCode
            {
                Id = Guid.NewGuid(),
                UserId = user.Id,
                User = user,
                Email = normalizedEmail,
                Purpose = AuthOneTimeCodePurpose.PasswordReset,
                CodeHash = _oneTimeCodeFactory.HashCode(code),
                ExpiresAt = now.Add(_passwordResetPolicy.CodeLifetime),
                MaxAllowedAttempts = _passwordResetPolicy.MaxAttempts,
                FailedAttemptCount = 0
            };

            await _repository.AddOneTimeCode(authCode, ct);
            await _repository.Save(ct);

            try
            {
                await _accountEmailSender.SendPasswordResetCode(
                    normalizedEmail,
                    code,
                    _passwordResetPolicy.CodeLifetime,
                    ct);
            }
            catch
            {
                authCode.InvalidatedAt = DateTime.UtcNow;
                authCode.LastUpdatedAt = authCode.InvalidatedAt.Value;
                await _repository.Save(ct);
                throw;
            }
        }

        public async Task ResetPassword(AuthResetPasswordDto dto, CancellationToken ct)
        {
            var normalizedEmail = NormalizeEmail(dto.Email);
            var code = NormalizeCode(dto.Code);
            var user = await _repository.GetUserByEmail(normalizedEmail, ct);
            if (user is null)
            {
                throw new AuthException("Invalid reset code or email.", HttpStatusCode.BadRequest);
            }

            var activeCode = await _repository.GetLatestActiveOneTimeCode(
                user.Id,
                AuthOneTimeCodePurpose.PasswordReset,
                ct);

            if (activeCode is null ||
                !string.Equals(activeCode.Email, normalizedEmail, StringComparison.Ordinal) ||
                activeCode.ExpiresAt <= DateTime.UtcNow)
            {
                throw new AuthException("Invalid reset code or email.", HttpStatusCode.BadRequest);
            }

            var incomingHash = _oneTimeCodeFactory.HashCode(code);
            if (!string.Equals(activeCode.CodeHash, incomingHash, StringComparison.Ordinal))
            {
                activeCode.FailedAttemptCount += 1;
                activeCode.LastUpdatedAt = DateTime.UtcNow;
                if (activeCode.FailedAttemptCount >= activeCode.MaxAllowedAttempts)
                {
                    activeCode.InvalidatedAt = DateTime.UtcNow;
                }

                await _repository.Save(ct);
                throw new AuthException("Invalid reset code or email.", HttpStatusCode.BadRequest);
            }

            var now = DateTime.UtcNow;
            user.PasswordHash = _passwordHashService.HashPassword(user, dto.NewPassword);
            user.LastUpdatedAt = now;

            activeCode.UsedAt = now;
            activeCode.LastUpdatedAt = now;

            await _repository.InvalidateActiveOneTimeCodes(
                user.Id,
                AuthOneTimeCodePurpose.PasswordReset,
                now,
                ct);
            await _repository.RevokeActiveRefreshSessions(user.Id, now, ct);

            await _repository.Save(ct);
        }

        public async Task<AuthSessionDto> Refresh(AuthRefreshDto dto, CancellationToken ct)
        {
            var sessionId = ParseSessionId(dto.RefreshSessionId);
            var session = await _repository.GetRefreshSession(sessionId, ct);
            if (session?.User is null)
            {
                throw new AuthException("Refresh session not found.", HttpStatusCode.Unauthorized);
            }

            var now = DateTime.UtcNow;
            if (session.RevokedAt.HasValue || session.ExpiresAt <= now)
            {
                throw new AuthException("Refresh session has expired. Please sign in again.", HttpStatusCode.Unauthorized);
            }

            var incomingHash = _refreshTokenFactory.HashToken(dto.RefreshToken);
            if (!string.Equals(session.RefreshTokenHash, incomingHash, StringComparison.Ordinal))
            {
                throw new AuthException("Invalid refresh token.", HttpStatusCode.Unauthorized);
            }

            var newRefreshToken = _refreshTokenFactory.CreateToken();
            session.RefreshTokenHash = _refreshTokenFactory.HashToken(newRefreshToken);
            session.LastUsedAt = now;
            if (_sessionPolicy.UseSlidingRefreshExpiration)
            {
                session.ExpiresAt = now.Add(_sessionPolicy.RefreshTokenLifetime);
            }
            session.LastUpdatedAt = now;

            var displayName = BuildDisplayName(session.User, fallbackDisplayName: null);
            var accessToken = _jwtTokenFactory.CreateAccessToken(session.User, session.Provider, displayName);

            await _repository.Save(ct);

            return new AuthSessionDto
            {
                UserId = session.User.Id.ToString(),
                DisplayName = displayName,
                Email = session.User.Email,
                Provider = ToProviderName(session.Provider),
                AccessToken = accessToken.Token,
                RefreshToken = newRefreshToken,
                IssuedAt = now,
                AccessTokenExpiresAt = accessToken.ExpiresAtUtc,
                RefreshSessionId = session.Id.ToString()
            };
        }

        public async Task Logout(AuthLogoutDto dto, CancellationToken ct)
        {
            var sessionId = ParseSessionId(dto.RefreshSessionId);
            var session = await _repository.GetRefreshSession(sessionId, ct);
            if (session is null)
            {
                return;
            }

            var incomingHash = _refreshTokenFactory.HashToken(dto.RefreshToken);
            if (!string.Equals(session.RefreshTokenHash, incomingHash, StringComparison.Ordinal))
            {
                return;
            }

            if (!session.RevokedAt.HasValue)
            {
                session.RevokedAt = DateTime.UtcNow;
                session.LastUpdatedAt = session.RevokedAt.Value;
                await _repository.Save(ct);
            }
        }

        public async Task<AuthCurrentUserDto> GetCurrentUser(CancellationToken ct)
        {
            if (!_currentUserContext.HasUserId)
            {
                throw new AuthException("User is not authenticated.", HttpStatusCode.Unauthorized);
            }

            var user = await _repository.GetUserById(_currentUserContext.UserId!.Value, ct);
            if (user is null)
            {
                throw new AuthException("User not found.", HttpStatusCode.Unauthorized);
            }

            return new AuthCurrentUserDto
            {
                UserId = user.Id.ToString(),
                DisplayName = BuildDisplayName(user, fallbackDisplayName: null),
                Email = user.Email,
                HasPassword = !string.IsNullOrWhiteSpace(user.PasswordHash),
                LinkedProviders = user.ExternalAuthAccounts
                    .Select(x => ToProviderName(x.Provider))
                    .Distinct(StringComparer.Ordinal)
                    .OrderBy(x => x, StringComparer.Ordinal)
                    .ToList()
            };
        }

        private async Task<User> ResolveExternalUser(ExternalIdentityProfileDto externalProfile, CancellationToken ct)
        {
            if (!externalProfile.EmailVerified)
            {
                throw new AuthException("The provider did not confirm the user's email.", HttpStatusCode.Unauthorized);
            }

            var normalizedEmail = NormalizeEmail(externalProfile.Email);
            var linkedAccount = await _repository.GetExternalAuthAccount(
                externalProfile.Provider,
                externalProfile.ProviderUserId,
                ct);

            if (linkedAccount?.User is not null)
            {
                linkedAccount.Email = normalizedEmail;
                linkedAccount.DisplayName = NormalizeOptional(externalProfile.DisplayName);
                linkedAccount.LastUpdatedAt = DateTime.UtcNow;
                return linkedAccount.User;
            }

            var user = await _repository.GetUserByEmail(normalizedEmail, ct);
            if (user is null)
            {
                user = new User
                {
                    Id = Guid.NewGuid(),
                    Email = normalizedEmail,
                    Phone = null,
                    PasswordHash = null
                };
                await _repository.AddUser(user, ct);
            }

            var account = new ExternalAuthAccount
            {
                Id = Guid.NewGuid(),
                UserId = user.Id,
                User = user,
                Provider = externalProfile.Provider,
                ProviderUserId = externalProfile.ProviderUserId,
                Email = normalizedEmail,
                DisplayName = NormalizeOptional(externalProfile.DisplayName)
            };

            await _repository.AddExternalAuthAccount(account, ct);
            user.ExternalAuthAccounts.Add(account);

            return user;
        }

        private async Task<AuthSessionDto> IssueSession(
            User user,
            AuthProvider provider,
            string? deviceId,
            string? deviceName,
            string? fallbackDisplayName,
            CancellationToken ct)
        {
            var now = DateTime.UtcNow;
            var displayName = BuildDisplayName(user, fallbackDisplayName);
            var accessToken = _jwtTokenFactory.CreateAccessToken(user, provider, displayName);
            var refreshToken = _refreshTokenFactory.CreateToken();

            var refreshSession = new AuthRefreshSession
            {
                Id = Guid.NewGuid(),
                UserId = user.Id,
                User = user,
                Provider = provider,
                RefreshTokenHash = _refreshTokenFactory.HashToken(refreshToken),
                DeviceId = NormalizeOptional(deviceId),
                DeviceName = NormalizeOptional(deviceName),
                ExpiresAt = now.Add(_sessionPolicy.RefreshTokenLifetime),
                LastUsedAt = now
            };

            await _repository.AddRefreshSession(refreshSession, ct);
            user.AuthRefreshSessions.Add(refreshSession);

            return new AuthSessionDto
            {
                UserId = user.Id.ToString(),
                DisplayName = displayName,
                Email = user.Email,
                Provider = ToProviderName(provider),
                AccessToken = accessToken.Token,
                RefreshToken = refreshToken,
                IssuedAt = now,
                AccessTokenExpiresAt = accessToken.ExpiresAtUtc,
                RefreshSessionId = refreshSession.Id.ToString()
            };
        }

        private static Guid ParseSessionId(string refreshSessionId)
        {
            if (!Guid.TryParse(refreshSessionId, out var sessionId))
            {
                throw new AuthException("Invalid refresh session id.");
            }

            return sessionId;
        }

        private static string NormalizeEmail(string email)
        {
            var normalized = email.Trim().ToLowerInvariant();
            if (string.IsNullOrWhiteSpace(normalized))
            {
                throw new AuthException("Email is required.");
            }

            return normalized;
        }

        private static string NormalizeCode(string code)
        {
            var normalized = code.Trim().Replace(" ", string.Empty, StringComparison.Ordinal);
            if (string.IsNullOrWhiteSpace(normalized))
            {
                throw new AuthException("Reset code is required.");
            }

            return normalized;
        }

        private static string? NormalizeOptional(string? value)
        {
            if (string.IsNullOrWhiteSpace(value))
            {
                return null;
            }

            return value.Trim();
        }

        private static string BuildDisplayName(User user, string? fallbackDisplayName)
        {
            var firstName = user.Profile?.FirstName?.Trim();
            var lastName = user.Profile?.LastName?.Trim();
            var fullName = string.Join(" ", new[] { firstName, lastName }.Where(x => !string.IsNullOrWhiteSpace(x)));
            if (!string.IsNullOrWhiteSpace(fullName))
            {
                return fullName;
            }

            if (!string.IsNullOrWhiteSpace(fallbackDisplayName))
            {
                return fallbackDisplayName.Trim();
            }

            return BuildDisplayNameFromEmail(user.Email);
        }

        private static string BuildDisplayNameFromEmail(string email)
        {
            var localPart = email.Split('@').FirstOrDefault()?.Trim() ?? string.Empty;
            if (string.IsNullOrWhiteSpace(localPart))
            {
                return "User";
            }

            var textInfo = CultureInfo.InvariantCulture.TextInfo;
            var parts = localPart
                .Split(['.', '_', '-'], StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
                .Select(textInfo.ToTitleCase)
                .ToList();

            return parts.Count == 0 ? "User" : string.Join(" ", parts);
        }

        private static string ToProviderName(AuthProvider provider) => provider switch
        {
            AuthProvider.Password => "password",
            AuthProvider.Google => "google",
            AuthProvider.Yandex => "yandex",
            _ => provider.ToString().ToLowerInvariant()
        };
    }
}
