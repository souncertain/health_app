using Data.Interfaces;
using Domain.Entity;
using Enums;
using Microsoft.EntityFrameworkCore;

namespace Data.Repositories
{
    public class HealthMetricRepository : AbstractRepository<HealthMetric>, IHealthMetricRepository
    {
        private static readonly string[] DeprecatedDefaultMetricTitles =
        [
            "пульс",
            "вес",
            "температура",
        ];

        private static readonly MetricSeedDefinition[] DefaultMetrics =
        [
            new("Сахар", "ммоль/л", 3.9, 5.5, MetricVisualStyle.AmberDrop),
            new("Кислород", "%", 95, 100, MetricVisualStyle.VioletHeart),
            new("Гемоглобин", "г/л", 120, 160, MetricVisualStyle.RedCircle),
            new("Холестерин", "ммоль/л", 3.0, 5.2, MetricVisualStyle.CoralSun),
        ];

        public HealthMetricRepository(HealthAppDbContext context, ICurrentUserContext currentUserContext)
            : base(context, currentUserContext)
        {
        }

        public override async Task<List<HealthMetric>> GetAll(CancellationToken ct = default)
        {
            await EnsureDefaultMetrics(ct);

            return await Query(asNoTracking: true)
                .Include(x => x.Records)
                .ToListAsync(ct);
        }

        public override async Task<HealthMetric?> GetById(Guid id, CancellationToken ct = default)
        {
            return await Query(asNoTracking: true)
                .Include(x => x.Records)
                .FirstOrDefaultAsync(x => x.Id == id, ct);
        }

        public async Task<HealthMetric> AddRecordToHealthMetric(Guid metricRecordId, Guid metricId)
        {
            var healthMetric = await Query().FirstOrDefaultAsync(x => x.Id == metricId);
            var metricRecord = await _context.Set<MetricRecord>().Where(x => x.Id == metricRecordId).FirstOrDefaultAsync();
            if (healthMetric is null || metricRecord is null) throw new ArgumentNullException("No health metric or metric record with this id");
            healthMetric.Records.Add(metricRecord);
            return healthMetric;
        }
        public async Task<MetricTrend> GetMetricTrend(Guid metricId)
        {
            var scopedMetricIds = Query(asNoTracking: true)
                .Where(x => x.Id == metricId)
                .Select(x => x.Id);

            var values = await _context.Set<MetricRecord>()
                .AsNoTracking()
                .Where(x => scopedMetricIds.Contains(x.HealthMetricId))
                .OrderByDescending(x => x.RecordedOn)
                .Select(x => x.Value)
                .Take(2)
                .ToListAsync();

            if (values.Count < 2)
            {
                return MetricTrend.None;
            }

            var last = values[0];
            var previous = values[1];

            var delta = last - previous;

            if (Math.Abs(delta) < 0.01)
            {
                return MetricTrend.Stable;
            }

            return delta < 0
                ? MetricTrend.Down
                : MetricTrend.Up;
        }

        private async Task EnsureDefaultMetrics(CancellationToken ct)
        {
            if (!CurrentUserId.HasValue)
            {
                return;
            }

            var existingTitles = await Query(asNoTracking: true)
                .Select(x => x.Title.Trim().ToLower())
                .ToListAsync(ct);

            var deprecatedMetrics = await Query()
                .Where(x => !x.IsCustom && DeprecatedDefaultMetricTitles.Contains(x.Title.Trim().ToLower()))
                .ToListAsync(ct);
            if (deprecatedMetrics.Count > 0)
            {
                _context.Set<HealthMetric>().RemoveRange(deprecatedMetrics);
                await _context.SaveChangesAsync(ct);
                existingTitles.RemoveAll(title => DeprecatedDefaultMetricTitles.Contains(title));
            }

            var titleSet = existingTitles.ToHashSet();
            var missingMetrics = DefaultMetrics
                .Where(metric => !titleSet.Contains(metric.Title.Trim().ToLower()))
                .ToList();

            if (missingMetrics.Count == 0)
            {
                return;
            }

            var now = DateTime.UtcNow;
            foreach (var metric in missingMetrics)
            {
                _context.Set<HealthMetric>().Add(new HealthMetric
                {
                    Id = Guid.NewGuid(),
                    UserId = CurrentUserId.Value,
                    Title = metric.Title,
                    Unit = metric.Unit,
                    TargetMin = metric.TargetMin,
                    TargetMax = metric.TargetMax,
                    VisualStyle = metric.VisualStyle,
                    IsCustom = false,
                    CreatedAt = now,
                    LastUpdatedAt = now,
                });
            }

            await _context.SaveChangesAsync(ct);
        }

        private sealed record MetricSeedDefinition(
            string Title,
            string Unit,
            double TargetMin,
            double TargetMax,
            MetricVisualStyle VisualStyle);
    }
}
