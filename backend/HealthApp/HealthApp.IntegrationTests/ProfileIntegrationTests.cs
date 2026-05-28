using Domain.Dto.Profile;
using FluentAssertions;
using HealthApp.IntegrationTests.Infrastructure;
using System.Net;
using System.Net.Http.Json;

namespace HealthApp.IntegrationTests;

public sealed class ProfileIntegrationTests
{
    [Fact]
    public async Task ProfileMe_ReturnsDefaultPayload_ForNewUser()
    {
        using var factory = new HealthAppWebApplicationFactory();
        var (client, _, email) = await factory.CreateAuthenticatedClientAsync();

        var response = await client.GetAsync("/api/profile/me");

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var profile = await response.Content.ReadFromJsonAsync<ProfilePageDto>();
        profile.Should().NotBeNull();
        profile!.Email.Should().Be(email);
        profile.FullName.Should().BeEmpty();
        profile.NotificationsEnabled.Should().BeTrue();
    }

    [Fact]
    public async Task ProfileMe_CanBeUpdated_AndReadBack()
    {
        using var factory = new HealthAppWebApplicationFactory();
        var (client, _, _) = await factory.CreateAuthenticatedClientAsync();

        var updateResponse = await client.PutAsJsonAsync("/api/profile/me", new
        {
            fullName = "Иван Петров",
            email = "ivan.petrov@example.com",
            gender = "male",
            age = 29,
            bloodType = "AB+",
            heightCm = 182,
            weightKg = 79.5,
            primaryDoctor = "Кардиолог",
            emergencyContactName = "Мама",
            emergencyContactDetails = "+79990000001",
            notificationsEnabled = false
        });

        updateResponse.StatusCode.Should().Be(HttpStatusCode.OK);
        var updated = await updateResponse.Content.ReadFromJsonAsync<ProfilePageDto>();
        updated.Should().NotBeNull();
        updated!.FullName.Should().Be("Иван Петров");
        updated.Email.Should().Be("ivan.petrov@example.com");
        updated.Gender.Should().Be("male");
        updated.BloodType.Should().Be("AB+");
        updated.HeightCm.Should().Be(182);
        updated.WeightKg.Should().Be(79.5);
        updated.NotificationsEnabled.Should().BeFalse();

        var getResponse = await client.GetAsync("/api/profile/me");
        getResponse.StatusCode.Should().Be(HttpStatusCode.OK);
        var fetched = await getResponse.Content.ReadFromJsonAsync<ProfilePageDto>();
        fetched.Should().NotBeNull();
        fetched!.FullName.Should().Be("Иван Петров");
        fetched.EmergencyContactName.Should().Be("Мама");
        fetched.PrimaryDoctor.Should().Be("Кардиолог");
    }
}
