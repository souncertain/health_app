using Data.Interfaces;
using Domain.Dto.Auth;
using Domain.Entity;
using Domain.Exceptions;
using Enums;
using FluentAssertions;
using HealthApp.UnitTests.TestDoubles;
using Moq;
using Services.Interfaces;
using Services.Services;
using System.Net;

namespace HealthApp.UnitTests.Services;

public sealed class AuthServiceTests
{
    [Fact]
    public async Task Register_CreatesUnconfirmedUserAndSendsEmail_WhenEmailIsAvailable()
    {
        var fixture = new AuthFixture();
        var dto = new AuthRegisterDto
        {
            Email = "  USER@example.com ",
            Password = "Secret123",
            Phone = "  +79990000000 ",
            DeviceId = "  phone-1 ",
            DeviceName = "  Pixel "
        };
        User? createdUser = null;
        AuthOneTimeCode? createdCode = null;

        fixture.Repository.Setup(x => x.GetUserByEmail("user@example.com", It.IsAny<CancellationToken>()))
            .ReturnsAsync((User?)null);
        fixture.PasswordHashService.Setup(x => x.HashPassword(It.IsAny<User>(), dto.Password)).Returns("hashed-password");
        fixture.OneTimeCodeFactory.Setup(x => x.CreateNumericCode(fixture.EmailConfirmationPolicy.Object.CodeLength)).Returns("654321");
        fixture.OneTimeCodeFactory.Setup(x => x.HashCode("654321")).Returns("confirmation-hash");
        fixture.Repository.Setup(x => x.AddUser(It.IsAny<User>(), It.IsAny<CancellationToken>()))
            .Callback<User, CancellationToken>((user, _) => createdUser = user)
            .Returns(Task.CompletedTask);
        fixture.Repository.Setup(x => x.InvalidateActiveOneTimeCodes(It.IsAny<Guid>(), AuthOneTimeCodePurpose.EmailConfirmation, It.IsAny<DateTime>(), It.IsAny<CancellationToken>()))
            .Returns(Task.CompletedTask);
        fixture.Repository.Setup(x => x.AddOneTimeCode(It.IsAny<AuthOneTimeCode>(), It.IsAny<CancellationToken>()))
            .Callback<AuthOneTimeCode, CancellationToken>((code, _) => createdCode = code)
            .Returns(Task.CompletedTask);
        fixture.Repository.Setup(x => x.Save(It.IsAny<CancellationToken>())).Returns(Task.CompletedTask);
        fixture.AccountEmailSender.Setup(x => x.SendEmailConfirmationCode("user@example.com", "654321", fixture.EmailConfirmationPolicy.Object.CodeLifetime, It.IsAny<CancellationToken>()))
            .Returns(Task.CompletedTask);

        var result = await fixture.Service.Register(dto, CancellationToken.None);

        createdUser.Should().NotBeNull();
        createdUser!.Email.Should().Be("user@example.com");
        createdUser.Phone.Should().Be("+79990000000");
        createdUser.PasswordHash.Should().Be("hashed-password");
        createdUser.EmailConfirmed.Should().BeFalse();
        createdCode.Should().NotBeNull();
        createdCode!.Purpose.Should().Be(AuthOneTimeCodePurpose.EmailConfirmation);
        createdCode.Email.Should().Be("user@example.com");
        createdCode.CodeHash.Should().Be("confirmation-hash");
        result.Email.Should().Be("user@example.com");
        result.EmailConfirmationRequired.Should().BeTrue();
        fixture.ValidationService.ValidatedModels.Should().ContainSingle().Which.Should().BeSameAs(dto);
    }

    [Fact]
    public async Task ConfirmEmail_IssuesSession_WhenCodeMatches()
    {
        var fixture = new AuthFixture();
        var user = new User { Id = Guid.NewGuid(), Email = "user@example.com", PasswordHash = "hash", EmailConfirmed = false };
        var activeCode = new AuthOneTimeCode
        {
            UserId = user.Id,
            Email = "user@example.com",
            Purpose = AuthOneTimeCodePurpose.EmailConfirmation,
            CodeHash = "expected-hash",
            ExpiresAt = DateTime.UtcNow.AddMinutes(10),
            MaxAllowedAttempts = 5
        };

        fixture.Repository.Setup(x => x.GetUserByEmail("user@example.com", It.IsAny<CancellationToken>())).ReturnsAsync(user);
        fixture.Repository.Setup(x => x.GetLatestActiveOneTimeCode(user.Id, AuthOneTimeCodePurpose.EmailConfirmation, It.IsAny<CancellationToken>()))
            .ReturnsAsync(activeCode);
        fixture.OneTimeCodeFactory.Setup(x => x.HashCode("654321")).Returns("expected-hash");
        fixture.JwtTokenFactory.Setup(x => x.CreateAccessToken(user, AuthProvider.Password, "User"))
            .Returns(("jwt-token", fixture.AccessTokenExpiresAt));
        fixture.RefreshTokenFactory.Setup(x => x.CreateToken()).Returns("refresh-token");
        fixture.RefreshTokenFactory.Setup(x => x.HashToken("refresh-token")).Returns("refresh-hash");
        fixture.Repository.Setup(x => x.InvalidateActiveOneTimeCodes(user.Id, AuthOneTimeCodePurpose.EmailConfirmation, It.IsAny<DateTime>(), It.IsAny<CancellationToken>()))
            .Returns(Task.CompletedTask);
        fixture.Repository.Setup(x => x.AddRefreshSession(It.IsAny<AuthRefreshSession>(), It.IsAny<CancellationToken>()))
            .Returns(Task.CompletedTask);
        fixture.Repository.Setup(x => x.Save(It.IsAny<CancellationToken>())).Returns(Task.CompletedTask);

        var result = await fixture.Service.ConfirmEmail(new AuthConfirmEmailDto
        {
            Email = "user@example.com",
            Code = "654321",
            DeviceId = "device-1",
            DeviceName = "Pixel"
        }, CancellationToken.None);

        user.EmailConfirmed.Should().BeTrue();
        activeCode.UsedAt.Should().NotBeNull();
        result.AccessToken.Should().Be("jwt-token");
        result.RefreshToken.Should().Be("refresh-token");
        fixture.Repository.Verify(x => x.AddRefreshSession(It.IsAny<AuthRefreshSession>(), It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task SignInWithPassword_ThrowsForbidden_WhenEmailIsNotConfirmed()
    {
        var fixture = new AuthFixture();
        var user = new User
        {
            Id = Guid.NewGuid(),
            Email = "user@example.com",
            PasswordHash = "stored-hash",
            EmailConfirmed = false
        };

        fixture.Repository.Setup(x => x.GetUserByEmail("user@example.com", It.IsAny<CancellationToken>()))
            .ReturnsAsync(user);
        fixture.PasswordHashService.Setup(x => x.VerifyPassword(user, "stored-hash", "Secret123"))
            .Returns(PasswordVerificationResult.Success);

        var action = () => fixture.Service.SignInWithPassword(new AuthLoginDto
        {
            Email = "user@example.com",
            Password = "Secret123"
        }, CancellationToken.None);

        var exception = await action.Should().ThrowAsync<AuthException>();
        exception.Which.StatusCode.Should().Be(HttpStatusCode.Forbidden);
    }

    [Fact]
    public async Task Register_ThrowsConflict_WhenEmailAlreadyExists()
    {
        var fixture = new AuthFixture();
        fixture.Repository.Setup(x => x.GetUserByEmail("user@example.com", It.IsAny<CancellationToken>()))
            .ReturnsAsync(new User
            {
                Id = Guid.NewGuid(),
                Email = "user@example.com",
                EmailConfirmed = true
            });

        var action = () => fixture.Service.Register(new AuthRegisterDto
        {
            Email = "user@example.com",
            Password = "Secret123"
        }, CancellationToken.None);

        var exception = await action.Should().ThrowAsync<AuthException>();
        exception.Which.StatusCode.Should().Be(HttpStatusCode.Conflict);
    }

    [Fact]
    public async Task SignInWithPassword_ThrowsUnauthorized_WhenUserIsMissing()
    {
        var fixture = new AuthFixture();
        fixture.Repository.Setup(x => x.GetUserByEmail("user@example.com", It.IsAny<CancellationToken>()))
            .ReturnsAsync((User?)null);

        var action = () => fixture.Service.SignInWithPassword(new AuthLoginDto
        {
            Email = "user@example.com",
            Password = "Secret123"
        }, CancellationToken.None);

        var exception = await action.Should().ThrowAsync<AuthException>();
        exception.Which.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task SignInWithPassword_RehashesPassword_WhenLegacyHashNeedsUpgrade()
    {
        var fixture = new AuthFixture();
        var user = new User { Id = Guid.NewGuid(), Email = "user@example.com", PasswordHash = "legacy-hash", EmailConfirmed = true };

        fixture.Repository.Setup(x => x.GetUserByEmail("user@example.com", It.IsAny<CancellationToken>())).ReturnsAsync(user);
        fixture.PasswordHashService.Setup(x => x.VerifyPassword(user, "legacy-hash", "Secret123"))
            .Returns(PasswordVerificationResult.SuccessRehashNeeded);
        fixture.PasswordHashService.Setup(x => x.HashPassword(user, "Secret123")).Returns("new-hash");
        fixture.JwtTokenFactory.Setup(x => x.CreateAccessToken(user, AuthProvider.Password, "User"))
            .Returns(("jwt-token", fixture.AccessTokenExpiresAt));
        fixture.RefreshTokenFactory.Setup(x => x.CreateToken()).Returns("refresh-token");
        fixture.RefreshTokenFactory.Setup(x => x.HashToken("refresh-token")).Returns("refresh-hash");
        fixture.Repository.Setup(x => x.AddRefreshSession(It.IsAny<AuthRefreshSession>(), It.IsAny<CancellationToken>()))
            .Returns(Task.CompletedTask);
        fixture.Repository.Setup(x => x.Save(It.IsAny<CancellationToken>())).Returns(Task.CompletedTask);

        var result = await fixture.Service.SignInWithPassword(new AuthLoginDto
        {
            Email = "user@example.com",
            Password = "Secret123"
        }, CancellationToken.None);

        user.PasswordHash.Should().Be("new-hash");
        user.LastUpdatedAt.Should().BeCloseTo(DateTime.UtcNow, TimeSpan.FromSeconds(5));
        result.Provider.Should().Be("password");
        fixture.Repository.Verify(x => x.Save(It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task RequestPasswordReset_ReturnsSilently_WhenUserIsUnknown()
    {
        var fixture = new AuthFixture();
        fixture.Repository.Setup(x => x.GetUserByEmail("missing@example.com", It.IsAny<CancellationToken>()))
            .ReturnsAsync((User?)null);

        await fixture.Service.RequestPasswordReset(new AuthForgotPasswordRequestDto { Email = "missing@example.com" }, CancellationToken.None);

        fixture.Repository.Verify(x => x.AddOneTimeCode(It.IsAny<AuthOneTimeCode>(), It.IsAny<CancellationToken>()), Times.Never);
        fixture.AccountEmailSender.Verify(x => x.SendPasswordResetCode(It.IsAny<string>(), It.IsAny<string>(), It.IsAny<TimeSpan>(), It.IsAny<CancellationToken>()), Times.Never);
    }

    [Fact]
    public async Task RequestPasswordReset_SkipsWhenCooldownIsActive()
    {
        var fixture = new AuthFixture();
        var user = new User { Id = Guid.NewGuid(), Email = "user@example.com", EmailConfirmed = true };
        var activeCode = new AuthOneTimeCode { CreatedAt = DateTime.UtcNow };

        fixture.Repository.Setup(x => x.GetUserByEmail("user@example.com", It.IsAny<CancellationToken>())).ReturnsAsync(user);
        fixture.Repository.Setup(x => x.GetLatestActiveOneTimeCode(user.Id, AuthOneTimeCodePurpose.PasswordReset, It.IsAny<CancellationToken>()))
            .ReturnsAsync(activeCode);

        await fixture.Service.RequestPasswordReset(new AuthForgotPasswordRequestDto { Email = "user@example.com" }, CancellationToken.None);

        fixture.Repository.Verify(x => x.InvalidateActiveOneTimeCodes(It.IsAny<Guid>(), It.IsAny<AuthOneTimeCodePurpose>(), It.IsAny<DateTime>(), It.IsAny<CancellationToken>()), Times.Never);
        fixture.Repository.Verify(x => x.AddOneTimeCode(It.IsAny<AuthOneTimeCode>(), It.IsAny<CancellationToken>()), Times.Never);
        fixture.AccountEmailSender.Verify(x => x.SendPasswordResetCode(It.IsAny<string>(), It.IsAny<string>(), It.IsAny<TimeSpan>(), It.IsAny<CancellationToken>()), Times.Never);
    }

    [Fact]
    public async Task RequestPasswordReset_CreatesCodeAndSendsEmail()
    {
        var fixture = new AuthFixture();
        var user = new User { Id = Guid.NewGuid(), Email = "user@example.com", EmailConfirmed = true };
        AuthOneTimeCode? createdCode = null;

        fixture.Repository.Setup(x => x.GetUserByEmail("user@example.com", It.IsAny<CancellationToken>())).ReturnsAsync(user);
        fixture.Repository.Setup(x => x.GetLatestActiveOneTimeCode(user.Id, AuthOneTimeCodePurpose.PasswordReset, It.IsAny<CancellationToken>()))
            .ReturnsAsync((AuthOneTimeCode?)null);
        fixture.OneTimeCodeFactory.Setup(x => x.CreateNumericCode(fixture.PasswordResetPolicy.Object.CodeLength)).Returns("123456");
        fixture.OneTimeCodeFactory.Setup(x => x.HashCode("123456")).Returns("code-hash");
        fixture.Repository.Setup(x => x.InvalidateActiveOneTimeCodes(user.Id, AuthOneTimeCodePurpose.PasswordReset, It.IsAny<DateTime>(), It.IsAny<CancellationToken>()))
            .Returns(Task.CompletedTask);
        fixture.Repository.Setup(x => x.AddOneTimeCode(It.IsAny<AuthOneTimeCode>(), It.IsAny<CancellationToken>()))
            .Callback<AuthOneTimeCode, CancellationToken>((code, _) => createdCode = code)
            .Returns(Task.CompletedTask);
        fixture.Repository.Setup(x => x.Save(It.IsAny<CancellationToken>())).Returns(Task.CompletedTask);
        fixture.AccountEmailSender.Setup(x => x.SendPasswordResetCode("user@example.com", "123456", fixture.PasswordResetPolicy.Object.CodeLifetime, It.IsAny<CancellationToken>()))
            .Returns(Task.CompletedTask);

        await fixture.Service.RequestPasswordReset(new AuthForgotPasswordRequestDto { Email = "user@example.com" }, CancellationToken.None);

        createdCode.Should().NotBeNull();
        createdCode!.Email.Should().Be("user@example.com");
        createdCode.Purpose.Should().Be(AuthOneTimeCodePurpose.PasswordReset);
        createdCode.CodeHash.Should().Be("code-hash");
        createdCode.MaxAllowedAttempts.Should().Be(fixture.PasswordResetPolicy.Object.MaxAttempts);
        createdCode.FailedAttemptCount.Should().Be(0);
        createdCode.ExpiresAt.Should().BeCloseTo(DateTime.UtcNow.Add(fixture.PasswordResetPolicy.Object.CodeLifetime), TimeSpan.FromSeconds(5));
        fixture.Repository.Verify(x => x.Save(It.IsAny<CancellationToken>()), Times.Once);
        fixture.AccountEmailSender.VerifyAll();
    }

    [Fact]
    public async Task RequestPasswordReset_InvalidatesCode_WhenEmailSendFails()
    {
        var fixture = new AuthFixture();
        var user = new User { Id = Guid.NewGuid(), Email = "user@example.com", EmailConfirmed = true };
        AuthOneTimeCode? createdCode = null;

        fixture.Repository.Setup(x => x.GetUserByEmail("user@example.com", It.IsAny<CancellationToken>())).ReturnsAsync(user);
        fixture.Repository.Setup(x => x.GetLatestActiveOneTimeCode(user.Id, AuthOneTimeCodePurpose.PasswordReset, It.IsAny<CancellationToken>()))
            .ReturnsAsync((AuthOneTimeCode?)null);
        fixture.OneTimeCodeFactory.Setup(x => x.CreateNumericCode(It.IsAny<int>())).Returns("123456");
        fixture.OneTimeCodeFactory.Setup(x => x.HashCode("123456")).Returns("code-hash");
        fixture.Repository.Setup(x => x.InvalidateActiveOneTimeCodes(user.Id, AuthOneTimeCodePurpose.PasswordReset, It.IsAny<DateTime>(), It.IsAny<CancellationToken>()))
            .Returns(Task.CompletedTask);
        fixture.Repository.Setup(x => x.AddOneTimeCode(It.IsAny<AuthOneTimeCode>(), It.IsAny<CancellationToken>()))
            .Callback<AuthOneTimeCode, CancellationToken>((code, _) => createdCode = code)
            .Returns(Task.CompletedTask);
        fixture.Repository.Setup(x => x.Save(It.IsAny<CancellationToken>())).Returns(Task.CompletedTask);
        fixture.AccountEmailSender.Setup(x => x.SendPasswordResetCode(It.IsAny<string>(), It.IsAny<string>(), It.IsAny<TimeSpan>(), It.IsAny<CancellationToken>()))
            .ThrowsAsync(new InvalidOperationException("smtp failed"));

        var action = () => fixture.Service.RequestPasswordReset(new AuthForgotPasswordRequestDto { Email = "user@example.com" }, CancellationToken.None);

        await action.Should().ThrowAsync<InvalidOperationException>();
        createdCode.Should().NotBeNull();
        createdCode!.InvalidatedAt.Should().NotBeNull();
        createdCode.LastUpdatedAt.Should().Be(createdCode.InvalidatedAt);
        fixture.Repository.Verify(x => x.Save(It.IsAny<CancellationToken>()), Times.Exactly(2));
    }

    [Fact]
    public async Task ResetPassword_ThrowsAndCountsAttempt_WhenCodeDoesNotMatch()
    {
        var fixture = new AuthFixture();
        var user = new User { Id = Guid.NewGuid(), Email = "user@example.com" };
        var activeCode = new AuthOneTimeCode
        {
            UserId = user.Id,
            Email = "user@example.com",
            ExpiresAt = DateTime.UtcNow.AddMinutes(10),
            CodeHash = "expected-hash",
            FailedAttemptCount = 4,
            MaxAllowedAttempts = 5
        };

        fixture.Repository.Setup(x => x.GetUserByEmail("user@example.com", It.IsAny<CancellationToken>())).ReturnsAsync(user);
        fixture.Repository.Setup(x => x.GetLatestActiveOneTimeCode(user.Id, AuthOneTimeCodePurpose.PasswordReset, It.IsAny<CancellationToken>()))
            .ReturnsAsync(activeCode);
        fixture.OneTimeCodeFactory.Setup(x => x.HashCode("000000")).Returns("wrong-hash");
        fixture.Repository.Setup(x => x.Save(It.IsAny<CancellationToken>())).Returns(Task.CompletedTask);

        var action = () => fixture.Service.ResetPassword(new AuthResetPasswordDto
        {
            Email = "user@example.com",
            Code = "000000",
            NewPassword = "NewSecret123"
        }, CancellationToken.None);

        var exception = await action.Should().ThrowAsync<AuthException>();
        exception.Which.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        activeCode.FailedAttemptCount.Should().Be(5);
        activeCode.InvalidatedAt.Should().NotBeNull();
        fixture.Repository.Verify(x => x.Save(It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task ResetPassword_UpdatesPasswordAndRevokesSessions_WhenCodeMatches()
    {
        var fixture = new AuthFixture();
        var user = new User { Id = Guid.NewGuid(), Email = "user@example.com", PasswordHash = "old-hash" };
        var activeCode = new AuthOneTimeCode
        {
            UserId = user.Id,
            Email = "user@example.com",
            ExpiresAt = DateTime.UtcNow.AddMinutes(10),
            CodeHash = "expected-hash",
            FailedAttemptCount = 0,
            MaxAllowedAttempts = 5
        };

        fixture.Repository.Setup(x => x.GetUserByEmail("user@example.com", It.IsAny<CancellationToken>())).ReturnsAsync(user);
        fixture.Repository.Setup(x => x.GetLatestActiveOneTimeCode(user.Id, AuthOneTimeCodePurpose.PasswordReset, It.IsAny<CancellationToken>()))
            .ReturnsAsync(activeCode);
        fixture.OneTimeCodeFactory.Setup(x => x.HashCode("000000")).Returns("expected-hash");
        fixture.PasswordHashService.Setup(x => x.HashPassword(user, "NewSecret123")).Returns("new-hash");
        fixture.Repository.Setup(x => x.InvalidateActiveOneTimeCodes(user.Id, AuthOneTimeCodePurpose.PasswordReset, It.IsAny<DateTime>(), It.IsAny<CancellationToken>()))
            .Returns(Task.CompletedTask);
        fixture.Repository.Setup(x => x.RevokeActiveRefreshSessions(user.Id, It.IsAny<DateTime>(), It.IsAny<CancellationToken>()))
            .Returns(Task.CompletedTask);
        fixture.Repository.Setup(x => x.Save(It.IsAny<CancellationToken>())).Returns(Task.CompletedTask);

        await fixture.Service.ResetPassword(new AuthResetPasswordDto
        {
            Email = "user@example.com",
            Code = "000000",
            NewPassword = "NewSecret123"
        }, CancellationToken.None);

        user.PasswordHash.Should().Be("new-hash");
        activeCode.UsedAt.Should().NotBeNull();
        fixture.Repository.Verify(x => x.InvalidateActiveOneTimeCodes(user.Id, AuthOneTimeCodePurpose.PasswordReset, It.IsAny<DateTime>(), It.IsAny<CancellationToken>()), Times.Once);
        fixture.Repository.Verify(x => x.RevokeActiveRefreshSessions(user.Id, It.IsAny<DateTime>(), It.IsAny<CancellationToken>()), Times.Once);
        fixture.Repository.Verify(x => x.Save(It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task Refresh_ThrowsUnauthorized_WhenRefreshTokenIsInvalid()
    {
        var fixture = new AuthFixture();
        var session = new AuthRefreshSession
        {
            Id = Guid.NewGuid(),
            User = new User { Id = Guid.NewGuid(), Email = "user@example.com" },
            ExpiresAt = DateTime.UtcNow.AddDays(1),
            RefreshTokenHash = "expected-hash"
        };

        fixture.Repository.Setup(x => x.GetRefreshSession(session.Id, It.IsAny<CancellationToken>())).ReturnsAsync(session);
        fixture.RefreshTokenFactory.Setup(x => x.HashToken("provided-token")).Returns("wrong-hash");

        var action = () => fixture.Service.Refresh(new AuthRefreshDto
        {
            RefreshSessionId = session.Id.ToString(),
            RefreshToken = "provided-token"
        }, CancellationToken.None);

        var exception = await action.Should().ThrowAsync<AuthException>();
        exception.Which.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task Refresh_RotatesTokenAndExtendsExpiry_WhenSessionIsValid()
    {
        var fixture = new AuthFixture();
        var originalExpiry = DateTime.UtcNow.AddDays(1);
        var user = new User { Id = Guid.NewGuid(), Email = "john_doe@example.com" };
        var session = new AuthRefreshSession
        {
            Id = Guid.NewGuid(),
            User = user,
            Provider = AuthProvider.Password,
            ExpiresAt = originalExpiry,
            RefreshTokenHash = "expected-hash"
        };

        fixture.Repository.Setup(x => x.GetRefreshSession(session.Id, It.IsAny<CancellationToken>())).ReturnsAsync(session);
        fixture.RefreshTokenFactory.Setup(x => x.HashToken("provided-token")).Returns("expected-hash");
        fixture.RefreshTokenFactory.Setup(x => x.CreateToken()).Returns("new-refresh-token");
        fixture.RefreshTokenFactory.Setup(x => x.HashToken("new-refresh-token")).Returns("new-refresh-hash");
        fixture.JwtTokenFactory.Setup(x => x.CreateAccessToken(user, AuthProvider.Password, "John Doe"))
            .Returns(("jwt-token", fixture.AccessTokenExpiresAt));
        fixture.Repository.Setup(x => x.Save(It.IsAny<CancellationToken>())).Returns(Task.CompletedTask);

        var result = await fixture.Service.Refresh(new AuthRefreshDto
        {
            RefreshSessionId = session.Id.ToString(),
            RefreshToken = "provided-token"
        }, CancellationToken.None);

        session.RefreshTokenHash.Should().Be("new-refresh-hash");
        session.LastUsedAt.Should().NotBeNull();
        session.ExpiresAt.Should().BeAfter(originalExpiry);
        result.RefreshToken.Should().Be("new-refresh-token");
        result.AccessToken.Should().Be("jwt-token");
        result.Provider.Should().Be("password");
    }

    [Fact]
    public async Task Logout_RevokesSession_WhenTokenMatches()
    {
        var fixture = new AuthFixture();
        var session = new AuthRefreshSession
        {
            Id = Guid.NewGuid(),
            RefreshTokenHash = "expected-hash"
        };

        fixture.Repository.Setup(x => x.GetRefreshSession(session.Id, It.IsAny<CancellationToken>())).ReturnsAsync(session);
        fixture.RefreshTokenFactory.Setup(x => x.HashToken("provided-token")).Returns("expected-hash");
        fixture.Repository.Setup(x => x.Save(It.IsAny<CancellationToken>())).Returns(Task.CompletedTask);

        await fixture.Service.Logout(new AuthLogoutDto
        {
            RefreshSessionId = session.Id.ToString(),
            RefreshToken = "provided-token"
        }, CancellationToken.None);

        session.RevokedAt.Should().NotBeNull();
        session.LastUpdatedAt.Should().Be(session.RevokedAt);
        fixture.Repository.Verify(x => x.Save(It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task GetCurrentUser_ReturnsSortedProvidersAndEmailBasedDisplayName()
    {
        var fixture = new AuthFixture();
        var userId = Guid.NewGuid();
        fixture.CurrentUserContext.UserId = userId;
        var user = new User
        {
            Id = userId,
            Email = "john_doe@example.com",
            PasswordHash = null,
            ExternalAuthAccounts = new List<ExternalAuthAccount>
            {
                new() { Provider = AuthProvider.Yandex },
                new() { Provider = AuthProvider.Google },
                new() { Provider = AuthProvider.Google }
            }
        };

        fixture.Repository.Setup(x => x.GetUserById(userId, It.IsAny<CancellationToken>())).ReturnsAsync(user);

        var result = await fixture.Service.GetCurrentUser(CancellationToken.None);

        result.DisplayName.Should().Be("John Doe");
        result.Email.Should().Be("john_doe@example.com");
        result.HasPassword.Should().BeFalse();
        result.LinkedProviders.Should().Equal("google", "yandex");
    }

    [Fact]
    public async Task SignInWithGoogle_ThrowsUnauthorized_WhenEmailIsNotVerified()
    {
        var fixture = new AuthFixture();
        fixture.GoogleIdentityTokenValidator.Setup(x => x.Validate("google-token", It.IsAny<CancellationToken>()))
            .ReturnsAsync(new ExternalIdentityProfileDto
            {
                Provider = AuthProvider.Google,
                ProviderUserId = "provider-user",
                Email = "user@example.com",
                DisplayName = "Google User",
                EmailVerified = false
            });

        var action = () => fixture.Service.SignInWithGoogle(new AuthGoogleSignInDto
        {
            IdToken = "google-token"
        }, CancellationToken.None);

        var exception = await action.Should().ThrowAsync<AuthException>();
        exception.Which.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    private sealed class AuthFixture
    {
        public AuthFixture()
        {
            ValidationService = new TrackingValidationService();
            Repository = new Mock<IAuthRepository>(MockBehavior.Loose);
            GoogleIdentityTokenValidator = new Mock<IGoogleIdentityTokenValidator>(MockBehavior.Loose);
            YandexIdentityProviderClient = new Mock<IYandexIdentityProviderClient>(MockBehavior.Loose);
            JwtTokenFactory = new Mock<IJwtTokenFactory>(MockBehavior.Loose);
            PasswordHashService = new Mock<IPasswordHashService>(MockBehavior.Loose);
            RefreshTokenFactory = new Mock<IRefreshTokenFactory>(MockBehavior.Loose);
            OneTimeCodeFactory = new Mock<IOneTimeCodeFactory>(MockBehavior.Loose);
            SessionPolicy = new Mock<IAuthSessionPolicy>(MockBehavior.Loose);
            PasswordResetPolicy = new Mock<IPasswordResetPolicy>(MockBehavior.Loose);
            EmailConfirmationPolicy = new Mock<IEmailConfirmationPolicy>(MockBehavior.Loose);
            AccountEmailSender = new Mock<IAccountEmailSender>(MockBehavior.Loose);
            CurrentUserContext = new TestCurrentUserContext();

            SessionPolicy.SetupGet(x => x.RefreshTokenLifetime).Returns(TimeSpan.FromDays(30));
            SessionPolicy.SetupGet(x => x.UseSlidingRefreshExpiration).Returns(true);
            PasswordResetPolicy.SetupGet(x => x.CodeLength).Returns(6);
            PasswordResetPolicy.SetupGet(x => x.MaxAttempts).Returns(5);
            PasswordResetPolicy.SetupGet(x => x.CodeLifetime).Returns(TimeSpan.FromMinutes(15));
            PasswordResetPolicy.SetupGet(x => x.ResendCooldown).Returns(TimeSpan.FromSeconds(60));
            EmailConfirmationPolicy.SetupGet(x => x.CodeLength).Returns(6);
            EmailConfirmationPolicy.SetupGet(x => x.MaxAttempts).Returns(5);
            EmailConfirmationPolicy.SetupGet(x => x.CodeLifetime).Returns(TimeSpan.FromMinutes(30));
            EmailConfirmationPolicy.SetupGet(x => x.ResendCooldown).Returns(TimeSpan.FromSeconds(60));

            Service = new AuthService(
                Repository.Object,
                GoogleIdentityTokenValidator.Object,
                YandexIdentityProviderClient.Object,
                JwtTokenFactory.Object,
                PasswordHashService.Object,
                RefreshTokenFactory.Object,
                OneTimeCodeFactory.Object,
                SessionPolicy.Object,
                PasswordResetPolicy.Object,
                EmailConfirmationPolicy.Object,
                AccountEmailSender.Object,
                CurrentUserContext,
                ValidationService);
        }

        public TrackingValidationService ValidationService { get; }
        public Mock<IAuthRepository> Repository { get; }
        public Mock<IGoogleIdentityTokenValidator> GoogleIdentityTokenValidator { get; }
        public Mock<IYandexIdentityProviderClient> YandexIdentityProviderClient { get; }
        public Mock<IJwtTokenFactory> JwtTokenFactory { get; }
        public Mock<IPasswordHashService> PasswordHashService { get; }
        public Mock<IRefreshTokenFactory> RefreshTokenFactory { get; }
        public Mock<IOneTimeCodeFactory> OneTimeCodeFactory { get; }
        public Mock<IAuthSessionPolicy> SessionPolicy { get; }
        public Mock<IPasswordResetPolicy> PasswordResetPolicy { get; }
        public Mock<IEmailConfirmationPolicy> EmailConfirmationPolicy { get; }
        public Mock<IAccountEmailSender> AccountEmailSender { get; }
        public TestCurrentUserContext CurrentUserContext { get; }
        public AuthService Service { get; }
        public DateTime AccessTokenExpiresAt { get; } = new DateTime(2030, 1, 1, 0, 0, 0, DateTimeKind.Utc);
    }
}
