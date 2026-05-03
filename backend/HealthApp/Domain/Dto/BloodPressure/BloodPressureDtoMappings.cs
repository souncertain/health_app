namespace HealthApp.Dtos.BloodPressure
{
    public static class BloodPressureDtoMappings
    {
        public static BloodPressureListItemDto ToListItemDto(this Domain.Entity.BloodPressure bloodPressure)
        {
            return new BloodPressureListItemDto
            {
                Id = bloodPressure.Id,
                Systolic = bloodPressure.Systolic,
                Diastolic = bloodPressure.Diastolic,
                Pulse = bloodPressure.Pulse,
                RecordedAt = bloodPressure.RecordedAt,
                Category = bloodPressure.Category.ToString(),
                PressureLabel = $"{bloodPressure.Systolic}/{bloodPressure.Diastolic}",
            };
        }

        public static BloodPressureDetailsDto ToDetailsDto(this Domain.Entity.BloodPressure bloodPressure)
        {
            return new BloodPressureDetailsDto
            {
                Id = bloodPressure.Id,
                UserId = bloodPressure.UserId,
                Systolic = bloodPressure.Systolic,
                Diastolic = bloodPressure.Diastolic,
                Pulse = bloodPressure.Pulse,
                RecordedAt = bloodPressure.RecordedAt,
                CreatedAt = bloodPressure.CreatedAt,
                LastUpdatedAt = bloodPressure.LastUpdatedAt,
                Source = bloodPressure.Source.ToString(),
                Category = bloodPressure.Category.ToString(),
                PressureLabel = $"{bloodPressure.Systolic}/{bloodPressure.Diastolic}",
            };
        }
    }
}
