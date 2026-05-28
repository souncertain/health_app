using Domain.Dto.Medication;
using Enums;
using FluentAssertions;
using HealthApp.IntegrationTests.Infrastructure;
using System.Net;
using System.Net.Http.Json;

namespace HealthApp.IntegrationTests;

public sealed class MedicationIntegrationTests
{
    [Fact]
    public async Task MedicationFlow_CreateStatusAndNotifications_Works()
    {
        using var factory = new HealthAppWebApplicationFactory();
        var (client, _, _) = await factory.CreateAuthenticatedClientAsync();
        var today = DateOnly.FromDateTime(DateTime.Now);

        var createResponse = await client.PostAsJsonAsync("/api/medications", new
        {
            name = "Витамин D",
            dosageValue = 1,
            dosageUnit = "таблетка",
            frequency = (int)MedicationFrequency.OnceDaily,
            timesInMinutes = new[] { 1439 },
            notificationsEnabled = true,
            scheduledWeekdays = new[] { 1, 2, 3, 4, 5, 6, 7 }
        });
        createResponse.StatusCode.Should().Be(HttpStatusCode.OK);
        var created = await createResponse.Content.ReadFromJsonAsync<MedicationDetailsDto>();
        created.Should().NotBeNull();

        var statusResponse = await client.PutAsJsonAsync($"/api/medications/{created!.Id}/daily-status", new
        {
            date = today.ToString("yyyy-MM-dd"),
            status = (int)MedicationDayStatus.Taken
        });
        statusResponse.StatusCode.Should().Be(HttpStatusCode.OK);
        var dailyStatus = await statusResponse.Content.ReadFromJsonAsync<MedicationDailyStatusDetailsDto>();
        dailyStatus.Should().NotBeNull();
        dailyStatus!.Status.Should().Be(MedicationDayStatus.Taken);

        var medications = await client.GetFromJsonAsync<List<MedicationDetailsDto>>("/api/medications");
        medications.Should().NotBeNull();
        var savedMedications = medications!;
        savedMedications.Should().ContainSingle();
        savedMedications[0].DailyStatuses.Should().ContainSingle(x => x.Date == today && x.Status == MedicationDayStatus.Taken);

        var statuses = await client.GetFromJsonAsync<MedicationStatusesDto>("/api/medications/statuses");
        statuses.Should().NotBeNull();
        statuses!.TakenCount.Should().Be(1);

        var notifications = await client.GetFromJsonAsync<List<MedicationSoonestNotificationDto>>("/api/medications/soonest-notifications");
        notifications.Should().NotBeNull();
        var soonestNotifications = notifications!;
        soonestNotifications.Should().NotBeEmpty();
        soonestNotifications[0].Name.Should().Be("Витамин D");
    }
}
