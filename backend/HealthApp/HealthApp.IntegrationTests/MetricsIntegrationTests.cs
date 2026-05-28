using Domain.Dto.HealthMetric;
using Domain.Dto.MetricRecords;
using Enums;
using FluentAssertions;
using HealthApp.IntegrationTests.Infrastructure;
using System.Net;
using System.Net.Http.Json;

namespace HealthApp.IntegrationTests;

public sealed class MetricsIntegrationTests
{
    [Fact]
    public async Task HealthMetrics_DefaultsCustomMetricRecordsAndTrend_WorkTogether()
    {
        using var factory = new HealthAppWebApplicationFactory();
        var (client, _, _) = await factory.CreateAuthenticatedClientAsync();

        var defaults = await client.GetFromJsonAsync<List<HealthMetricDetailsDto>>("/api/healthmetric");
        defaults.Should().NotBeNull();
        var defaultMetrics = defaults!;
        defaultMetrics.Select(x => x.Title).Should().Contain(["Сахар", "Кислород", "Гемоглобин", "Холестерин"]);
        defaultMetrics.Select(x => x.Title).Should().NotContain(["пульс", "вес", "температура"]);

        var createMetricResponse = await client.PostAsJsonAsync("/api/healthmetric", new
        {
            title = "Ферритин",
            unit = "нг/мл",
            targetMin = 30,
            targetMax = 300,
            visualStyle = (int)MetricVisualStyle.CoralSun
        });
        createMetricResponse.StatusCode.Should().Be(HttpStatusCode.OK);
        var customMetric = await createMetricResponse.Content.ReadFromJsonAsync<HealthMetricDetailsDto>();
        customMetric.Should().NotBeNull();

        var createRecord1 = await client.PostAsJsonAsync("/api/metricrecord", new
        {
            healthMetricId = customMetric!.Id,
            value = 10,
            recordedOn = DateTime.UtcNow.Date.AddDays(-1)
        });
        createRecord1.StatusCode.Should().Be(HttpStatusCode.OK);

        var createRecord2 = await client.PostAsJsonAsync("/api/metricrecord", new
        {
            healthMetricId = customMetric.Id,
            value = 12,
            recordedOn = DateTime.UtcNow.Date
        });
        createRecord2.StatusCode.Should().Be(HttpStatusCode.OK);

        var metrics = await client.GetFromJsonAsync<List<HealthMetricDetailsDto>>("/api/healthmetric");
        metrics.Should().NotBeNull();
        var fetchedCustomMetric = metrics!.Single(x => x.Id == customMetric.Id);
        fetchedCustomMetric.Records.Should().HaveCount(2);

        var trend = await client.GetFromJsonAsync<MetricTrend>($"/api/healthmetric/type?metricId={customMetric.Id}");
        trend.Should().Be(MetricTrend.Up);

        var graph = await client.GetFromJsonAsync<List<MetricRecordGraphProjection>>("/api/metricrecord/graph");
        graph.Should().NotBeNull();
        graph!.Should().Contain(x => x.Value == 10);
        graph.Should().Contain(x => x.Value == 12);
    }
}
