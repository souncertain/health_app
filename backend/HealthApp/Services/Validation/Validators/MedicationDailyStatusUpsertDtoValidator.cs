using Domain.Dto.Medication;
using FluentValidation;
using Localization.Validation;

namespace Services.Validation.Validators
{
    public class MedicationDailyStatusUpsertDtoValidator : AbstractValidator<MedicationDailyStatusUpsertDto>
    {
        public MedicationDailyStatusUpsertDtoValidator()
        {
            RuleFor(x => x.Date)
                .Must(x => x != default)
                .WithMessage(ValidationMessages.InvalidDate(ValidationFieldNames.MedicationDate));

            RuleFor(x => x.Status)
                .Must(x => !x.HasValue || Enum.IsDefined(x.Value))
                .WithMessage(ValidationMessages.InvalidEnum(ValidationFieldNames.MedicationStatus));
        }
    }
}
