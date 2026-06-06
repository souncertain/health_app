namespace Domain.Dto.Profile
{
    public class ProfileHealthInsightsDto
    {
        public BloodPressureInsightDto BloodPressure { get; set; } = new();

        public BodyMassInsightDto BodyMass { get; set; } = new();

        public IReadOnlyList<HealthRiskSignalDto> RiskSignals { get; set; } = Array.Empty<HealthRiskSignalDto>();
    }
}
