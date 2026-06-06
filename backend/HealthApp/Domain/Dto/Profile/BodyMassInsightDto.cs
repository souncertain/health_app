namespace Domain.Dto.Profile
{
    public class BodyMassInsightDto
    {
        public bool HasBodyMassData { get; set; }

        public double? Bmi { get; set; }

        public string Category { get; set; } = "noData";

        public double? HealthyWeightMinKg { get; set; }

        public double? HealthyWeightMaxKg { get; set; }

        public double? WeightDeltaKg { get; set; }

        public string Summary { get; set; } = string.Empty;
    }
}
