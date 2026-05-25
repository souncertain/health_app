using Enums;

namespace Domain.Dto.Medication
{
    public class MedicationDailyStatusUpsertDto
    {
        public DateOnly Date { get; set; }
        public MedicationDayStatus? Status { get; set; }
    }
}
