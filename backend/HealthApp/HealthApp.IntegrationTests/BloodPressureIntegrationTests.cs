using Domain.Dto.BloodPressure;
using FluentAssertions;
using HealthApp.IntegrationTests.Infrastructure;
using System.Net;
using System.Net.Http.Json;

namespace HealthApp.IntegrationTests;

public sealed class BloodPressureIntegrationTests
{
    [Fact]
    public async Task BloodPressureEndpoints_AreUserScoped_AndReturnAnalytics()
    {
        using var factory = new HealthAppWebApplicationFactory();
        var (client1, _, _) = await factory.CreateAuthenticatedClientAsync();
        var (client2, _, _) = await factory.CreateAuthenticatedClientAsync();

        var now = DateTime.UtcNow;
        await CreatePressureAsync(client1, 120, 80, 70, now.AddDays(-2));
        await CreatePressureAsync(client1, 140, 90, 80, now.AddDays(-1));
        await CreatePressureAsync(client2, 200, 100, 90, now.AddDays(-1));

        var allResponse = await client1.GetAsync("/api/pressures");
        allResponse.StatusCode.Should().Be(HttpStatusCode.OK);
        var all = await allResponse.Content.ReadFromJsonAsync<List<BloodPressureDetailsDto>>();
        all.Should().NotBeNull();
        var pressures = all!;
        pressures.Should().HaveCount(2);
        pressures.Select(x => x.Systolic).Should().BeEquivalentTo([120, 140]);

        var average = await client1.GetFromJsonAsync<BloodPressureAverageDataDto>("/api/pressures/average");
        average.Should().NotBeNull();
        average!.Systolic.Should().Be(130);
        average.Diastolic.Should().Be(85);
        average.Pulse.Should().Be(75);

        var last = await client1.GetFromJsonAsync<List<BloodPressureDetailsDto>>("/api/pressures/last?last=1");
        last.Should().NotBeNull();
        var lastPressures = last!;
        lastPressures.Should().HaveCount(1);
        lastPressures[0].Systolic.Should().Be(140);

        var interval = await client1.GetFromJsonAsync<List<BloodPressureDetailsDto>>("/api/pressures/interval?interval=7");
        interval.Should().NotBeNull();
        var intervalPressures = interval!;
        intervalPressures.Should().HaveCount(2);
    }

    private static async Task CreatePressureAsync(HttpClient client, int systolic, int diastolic, int pulse, DateTime recordedAt)
    {
        var response = await client.PostAsJsonAsync("/api/pressures", new
        {
            systolic,
            diastolic,
            pulse,
            recordedAt,
            source = "HandNote"
        });

        response.EnsureSuccessStatusCode();
    }
}
