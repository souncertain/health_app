using Data;
using HealthApp.Infrastructure.Email;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Services.Interfaces;
using System.Net.Http.Headers;
using System.Net.Http.Json;

namespace HealthApp.IntegrationTests.Infrastructure;

internal sealed class HealthAppWebApplicationFactory : WebApplicationFactory<Program>
{
    private readonly string _databaseName = $"health-app-tests-{Guid.NewGuid():N}";

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("IntegrationTesting");

        builder.ConfigureServices(services =>
        {
            NoOpAccountEmailSender.EmailConfirmationCodes.Clear();
            NoOpAccountEmailSender.PasswordResetCodes.Clear();

            services.RemoveAll(typeof(DbContextOptions<HealthAppDbContext>));
            services.RemoveAll(typeof(HealthAppDbContext));
            services.RemoveAll(typeof(IAccountEmailSender));

            services.AddDbContext<HealthAppDbContext>(options =>
            {
                options.UseInMemoryDatabase(_databaseName);
            });

            services.AddScoped<IAccountEmailSender, NoOpAccountEmailSender>();

            var serviceProvider = services.BuildServiceProvider();
            using var scope = serviceProvider.CreateScope();
            var dbContext = scope.ServiceProvider.GetRequiredService<HealthAppDbContext>();
            dbContext.Database.EnsureDeleted();
            dbContext.Database.EnsureCreated();
        });
    }

    public HttpClient CreateApiClient()
    {
        return CreateClient(new WebApplicationFactoryClientOptions
        {
            BaseAddress = new Uri("https://localhost"),
            AllowAutoRedirect = false
        });
    }

    public async Task<(HttpClient Client, Domain.Dto.Auth.AuthSessionDto Session, string Email)> CreateAuthenticatedClientAsync()
    {
        var client = CreateApiClient();
        var email = $"user-{Guid.NewGuid():N}@example.com";
        var registerResponse = await client.PostAsJsonAsync("/api/auth/register", new
        {
            email,
            password = "Secret123!",
            phone = "+79990000000",
            deviceId = "integration-device",
            deviceName = "Integration Test Device"
        });

        registerResponse.EnsureSuccessStatusCode();
        var registerResult = await registerResponse.Content.ReadFromJsonAsync<Domain.Dto.Auth.AuthRegisterResultDto>();
        if (registerResult is null)
        {
            throw new InvalidOperationException("Failed to deserialize registration result.");
        }

        if (!NoOpAccountEmailSender.EmailConfirmationCodes.TryGetValue(email, out var code))
        {
            throw new InvalidOperationException("Failed to capture email confirmation code.");
        }

        var confirmResponse = await client.PostAsJsonAsync("/api/auth/confirm-email", new
        {
            email,
            code,
            deviceId = "integration-device",
            deviceName = "Integration Test Device"
        });
        confirmResponse.EnsureSuccessStatusCode();

        var session = await confirmResponse.Content.ReadFromJsonAsync<Domain.Dto.Auth.AuthSessionDto>();
        if (session is null)
        {
            throw new InvalidOperationException("Failed to deserialize auth session.");
        }

        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", session.AccessToken);
        return (client, session, email);
    }

    public async Task ExecuteDbContextAsync(Func<HealthAppDbContext, Task> action)
    {
        using var scope = Services.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<HealthAppDbContext>();
        await action(dbContext);
    }

    public async Task<T> ExecuteDbContextAsync<T>(Func<HealthAppDbContext, Task<T>> action)
    {
        using var scope = Services.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<HealthAppDbContext>();
        return await action(dbContext);
    }
}
