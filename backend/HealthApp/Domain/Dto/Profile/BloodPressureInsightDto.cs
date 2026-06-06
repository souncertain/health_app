namespace Domain.Dto.Profile
{
    public class BloodPressureInsightDto
    {
        public bool HasReadings { get; set; }

        public int ReadingsCount { get; set; }

        public int MeasuredDaysLast30Days { get; set; }

        public int? AverageSystolic { get; set; }

        public int? AverageDiastolic { get; set; }

        public int? AveragePulse { get; set; }

        public int? NormalRangePercent { get; set; }

        public string LatestCategory { get; set; } = "noData";

        public string Trend { get; set; } = "insufficientData";

        public string Variability { get; set; } = "insufficientData";

        public string Summary { get; set; } = string.Empty;
    }
}
