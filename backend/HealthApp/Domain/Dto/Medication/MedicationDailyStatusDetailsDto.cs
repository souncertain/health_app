using Enums;

namespace Domain.Dto.Medication
{
    public class MedicationDailyStatusDetailsDto
    {
        public Guid Id { get; set; }
        public Guid MedicationId { get; set; }
        public DateOnly Date { get; set; }
        public MedicationDayStatus Status { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime LastUpdatedAt { get; set; }
    }
}
