using Domain.Entity;
using FluentAssertions;
using HealthApp.Configuration;
using HealthApp.Infrastructure.Auth;
using Microsoft.Extensions.Options;
using Services.Interfaces;

namespace HealthApp.UnitTests.Infrastructure;

public sealed class AuthInfrastructureTests
{
    [Fact]
    public void AuthSessionPolicy_UsesAtLeastOneHourLifetime()
    {
        var options = Options.Create(new AuthOptions
        {
            RefreshTokens = new RefreshTokenOptions
            {
                LifetimeHours = 0,
                UseSlidingExpiration = false
            }
        });

        var policy = new AuthSessionPolicy(options);

        policy.RefreshTokenLifetime.Should().Be(TimeSpan.FromHours(1));
        policy.UseSlidingRefreshExpiration.Should().BeFalse();
    }

    [Fact]
    public void AuthSessionPolicy_ReturnsConfiguredValues()
    {
        var options = Options.Create(new AuthOptions
        {
            RefreshTokens = new RefreshTokenOptions
            {
                LifetimeHours = 24 * 14,
                UseSlidingExpiration = true
            }
        });

        var policy = new AuthSessionPolicy(options);

        policy.RefreshTokenLifetime.Should().Be(TimeSpan.FromHours(24 * 14));
        policy.UseSlidingRefreshExpiration.Should().BeTrue();
    }

    [Fact]
    public void PasswordResetPolicy_ClampsValuesToSafeBounds()
    {
        var options = Options.Create(new AuthOptions
        {
            PasswordReset = new PasswordResetOptions
            {
                CodeLength = 1,
                LifetimeMinutes = 0,
                MaxAttempts = 999,
                ResendCooldownSeconds = -15
            }
        });

        var policy = new PasswordResetPolicy(options);

        policy.CodeLength.Should().Be(4);
        policy.CodeLifetime.Should().Be(TimeSpan.FromMinutes(1));
        policy.MaxAttempts.Should().Be(20);
        policy.ResendCooldown.Should().Be(TimeSpan.Zero);
    }

    [Fact]
    public void PasswordResetPolicy_ReturnsConfiguredValues_WhenTheyAreWithinRange()
    {
        var options = Options.Create(new AuthOptions
        {
            PasswordReset = new PasswordResetOptions
            {
                CodeLength = 8,
                LifetimeMinutes = 25,
                MaxAttempts = 7,
                ResendCooldownSeconds = 90
            }
        });

        var policy = new PasswordResetPolicy(options);

        policy.CodeLength.Should().Be(8);
        policy.CodeLifetime.Should().Be(TimeSpan.FromMinutes(25));
        policy.MaxAttempts.Should().Be(7);
        policy.ResendCooldown.Should().Be(TimeSpan.FromSeconds(90));
    }

    [Fact]
    public void OneTimeCodeFactory_CreateNumericCode_ReturnsDigitsOnlyWithRequestedLength()
    {
        var factory = new OneTimeCodeFactory();

        var code = factory.CreateNumericCode(6);

        code.Should().HaveLength(6);
        code.Should().MatchRegex("^[0-9]{6}$");
    }

    [Fact]
    public void OneTimeCodeFactory_CreateNumericCode_ThrowsForNonPositiveLength()
    {
        var factory = new OneTimeCodeFactory();

        var action = () => factory.CreateNumericCode(0);

        action.Should().Throw<ArgumentOutOfRangeException>();
    }

    [Fact]
    public void OneTimeCodeFactory_HashCode_IsDeterministicAndTrimsValue()
    {
        var factory = new OneTimeCodeFactory();

        var left = factory.HashCode("123456");
        var right = factory.HashCode(" 123456 ");

        left.Should().Be(right);
        left.Should().HaveLength(64);
    }

    [Fact]
    public void RefreshTokenFactory_CreateToken_ReturnsUrlSafeToken()
    {
        var factory = new RefreshTokenFactory();

        var token = factory.CreateToken();

        token.Should().NotBeNullOrWhiteSpace();
        token.Should().MatchRegex("^[A-Za-z0-9_-]+$");
        token.Should().NotContain("=");
        token.Should().NotContain("+");
        token.Should().NotContain("/");
    }

    [Fact]
    public void RefreshTokenFactory_HashToken_IsDeterministic()
    {
        var factory = new RefreshTokenFactory();

        var hash1 = factory.HashToken("token");
        var hash2 = factory.HashToken("token");
        var hash3 = factory.HashToken("other-token");

        hash1.Should().Be(hash2);
        hash1.Should().NotBe(hash3);
        hash1.Should().HaveLength(64);
    }

    [Fact]
    public void PasswordHashService_VerifyPassword_ReturnsFailed_WhenHashIsMissing()
    {
        var service = new PasswordHashService();

        var result = service.VerifyPassword(new User(), null, "password");

        result.Should().Be(PasswordVerificationResult.Failed);
    }

    [Fact]
    public void PasswordHashService_VerifyPassword_SupportsLegacyHashes()
    {
        var service = new PasswordHashService();
        var legacyHash = "legacy:" + Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes("secret"));

        var result = service.VerifyPassword(new User(), legacyHash, "secret");

        result.Should().Be(PasswordVerificationResult.SuccessRehashNeeded);
    }

    [Fact]
    public void PasswordHashService_VerifyPassword_ReturnsFailed_ForBrokenLegacyHash()
    {
        var service = new PasswordHashService();

        var result = service.VerifyPassword(new User(), "legacy:not-base64", "secret");

        result.Should().Be(PasswordVerificationResult.Failed);
    }

    [Fact]
    public void PasswordHashService_VerifyPassword_ReturnsSuccess_ForFreshHash()
    {
        var service = new PasswordHashService();
        var user = new User();
        var hash = service.HashPassword(user, "secret");

        var result = service.VerifyPassword(user, hash, "secret");

        result.Should().Be(PasswordVerificationResult.Success);
    }

    [Fact]
    public void PasswordHashService_VerifyPassword_ReturnsFailed_ForWrongPassword()
    {
        var service = new PasswordHashService();
        var user = new User();
        var hash = service.HashPassword(user, "secret");

        var result = service.VerifyPassword(user, hash, "wrong");

        result.Should().Be(PasswordVerificationResult.Failed);
    }
}
