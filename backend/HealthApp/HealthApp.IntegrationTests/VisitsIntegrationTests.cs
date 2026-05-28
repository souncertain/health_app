using Domain.Dto.MedicalVisit;
using Enums;
using FluentAssertions;
using HealthApp.IntegrationTests.Infrastructure;
using System.Net;
using System.Net.Http.Json;

namespace HealthApp.IntegrationTests;

public sealed class VisitsIntegrationTests
{
    [Fact]
    public async Task Visits_CanBeCreated_AndFetched()
    {
        using var factory = new HealthAppWebApplicationFactory();
        var (client, _, _) = await factory.CreateAuthenticatedClientAsync();
        var appointmentDate = new DateTime(2026, 5, 30);

        var createResponse = await client.PostAsJsonAsync("/api/visits", new
        {
            doctorName = "Доктор Иванов",
            speciality = "Кардиолог",
            appointmentDate,
            timeInMinutes = 14 * 60 + 30,
            location = "Клиника №1",
            visitType = (int)MedicalVisitType.OneTime
        });
        createResponse.StatusCode.Should().Be(HttpStatusCode.OK);
        var created = await createResponse.Content.ReadFromJsonAsync<MedicalVisitDetailsDto>();
        created.Should().NotBeNull();
        created!.DoctorName.Should().Be("Доктор Иванов");

        var visits = await client.GetFromJsonAsync<List<MedicalVisitDetailsDto>>("/api/visits");
        visits.Should().NotBeNull();
        var savedVisits = visits!;
        savedVisits.Should().ContainSingle();
        savedVisits[0].Location.Should().Be("Клиника №1");
        savedVisits[0].ScheduledAt.Should().Be(new DateTime(2026, 5, 30, 14, 30, 0));
    }
}
