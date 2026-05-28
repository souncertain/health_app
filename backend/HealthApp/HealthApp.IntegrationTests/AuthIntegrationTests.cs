using Data;
using Domain.Dto.Auth;
using Domain.Entity;
using Enums;
using FluentAssertions;
using HealthApp.IntegrationTests.Infrastructure;
using Microsoft.EntityFrameworkCore;
using System.Net;
using System.Net.Http.Json;

namespace HealthApp.IntegrationTests;

public sealed class AuthIntegrationTests
{
    [Fact]
    public async Task ProtectedEndpoint_ReturnsUnauthorized_WithoutToken()
    {
        using var factory = new HealthAppWebApplicationFactory();
        using var client = factory.CreateApiClient();

        var response = await client.GetAsync("/api/profile/me");

        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task Register_ThenMe_ReturnsCurrentUser()
    {
        using var factory = new HealthAppWebApplicationFactory();
        var (client, session, email) = await factory.CreateAuthenticatedClientAsync();

        var response = await client.GetAsync("/api/auth/me");

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var me = await response.Content.ReadFromJsonAsync<AuthCurrentUserDto>();
        me.Should().NotBeNull();
        me!.UserId.Should().Be(session.UserId);
        me.Email.Should().Be(email);
        me.HasPassword.Should().BeTrue();
    }

    [Fact]
    public async Task Register_WithInvalidEmail_ReturnsValidationPayload()
    {
        using var factory = new HealthAppWebApplicationFactory();
        using var client = factory.CreateApiClient();

        var response = await client.PostAsJsonAsync("/api/auth/register", new
        {
            email = "bad-email",
            password = "Secret123!",
            phone = "+79990000000"
        });

        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        var payload = await response.Content.ReadFromJsonAsync<ValidationErrorResponse>();
        payload.Should().NotBeNull();
        payload!.UiMessage.Should().NotBeNullOrWhiteSpace();
        payload.Errors.Keys.Should().Contain("Email");
    }

    [Fact]
    public async Task Refresh_ThenLogout_RevokesSession()
    {
        using var factory = new HealthAppWebApplicationFactory();
        using var client = factory.CreateApiClient();
        var email = $"refresh-{Guid.NewGuid():N}@example.com";

        var registerResponse = await client.PostAsJsonAsync("/api/auth/register", new
        {
            email,
            password = "Secret123!",
            phone = "+79990000000"
        });
        registerResponse.EnsureSuccessStatusCode();
        var code = NoOpAccountEmailSender.EmailConfirmationCodes[email];
        var confirmResponse = await client.PostAsJsonAsync("/api/auth/confirm-email", new
        {
            email,
            code
        });
        confirmResponse.EnsureSuccessStatusCode();
        var session = await confirmResponse.Content.ReadFromJsonAsync<AuthSessionDto>();
        session.Should().NotBeNull();

        var refreshResponse = await client.PostAsJsonAsync("/api/auth/refresh", new
        {
            refreshSessionId = session!.RefreshSessionId,
            refreshToken = session.RefreshToken
        });
        refreshResponse.StatusCode.Should().Be(HttpStatusCode.OK);
        var refreshed = await refreshResponse.Content.ReadFromJsonAsync<AuthSessionDto>();
        refreshed.Should().NotBeNull();
        refreshed!.RefreshToken.Should().NotBe(session.RefreshToken);

        var logoutResponse = await client.PostAsJsonAsync("/api/auth/logout", new
        {
            refreshSessionId = refreshed.RefreshSessionId,
            refreshToken = refreshed.RefreshToken
        });
        logoutResponse.StatusCode.Should().Be(HttpStatusCode.NoContent);

        var secondRefresh = await client.PostAsJsonAsync("/api/auth/refresh", new
        {
            refreshSessionId = refreshed.RefreshSessionId,
            refreshToken = refreshed.RefreshToken
        });
        secondRefresh.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task ForgotPassword_CreatesOneTimeCode_ForExistingUser()
    {
        using var factory = new HealthAppWebApplicationFactory();
        using var client = factory.CreateApiClient();
        var email = $"forgot-{Guid.NewGuid():N}@example.com";

        var registerResponse = await client.PostAsJsonAsync("/api/auth/register", new
        {
            email,
            password = "Secret123!",
            phone = "+79990000000"
        });
        registerResponse.EnsureSuccessStatusCode();
        var confirmationCode = NoOpAccountEmailSender.EmailConfirmationCodes[email];
        var confirmResponse = await client.PostAsJsonAsync("/api/auth/confirm-email", new
        {
            email,
            code = confirmationCode
        });
        confirmResponse.EnsureSuccessStatusCode();

        var response = await client.PostAsJsonAsync("/api/auth/forgot-password", new
        {
            email
        });

        response.StatusCode.Should().Be(HttpStatusCode.NoContent);

        var codeCount = await factory.ExecuteDbContextAsync(async db =>
        {
            return await db.Set<AuthOneTimeCode>()
                .CountAsync(x => x.Email == email && x.Purpose == Enums.AuthOneTimeCodePurpose.PasswordReset);
        });

        codeCount.Should().Be(1);
    }

    [Fact]
    public async Task Register_ThenConfirmEmail_ReturnsSession()
    {
        using var factory = new HealthAppWebApplicationFactory();
        using var client = factory.CreateApiClient();
        var email = $"confirm-{Guid.NewGuid():N}@example.com";

        var registerResponse = await client.PostAsJsonAsync("/api/auth/register", new
        {
            email,
            password = "Secret123!",
            phone = "+79990000000"
        });

        registerResponse.StatusCode.Should().Be(HttpStatusCode.OK);
        var registerResult = await registerResponse.Content.ReadFromJsonAsync<AuthRegisterResultDto>();
        registerResult.Should().NotBeNull();
        registerResult!.Email.Should().Be(email);
        registerResult.EmailConfirmationRequired.Should().BeTrue();

        var code = NoOpAccountEmailSender.EmailConfirmationCodes[email];
        var confirmResponse = await client.PostAsJsonAsync("/api/auth/confirm-email", new
        {
            email,
            code,
            deviceId = "integration-device"
        });

        confirmResponse.StatusCode.Should().Be(HttpStatusCode.OK);
        var session = await confirmResponse.Content.ReadFromJsonAsync<AuthSessionDto>();
        session.Should().NotBeNull();
        session!.Email.Should().Be(email);
        session.AccessToken.Should().NotBeNullOrWhiteSpace();
    }
}
