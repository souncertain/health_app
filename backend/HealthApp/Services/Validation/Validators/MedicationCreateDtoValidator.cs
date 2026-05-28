using Domain.Dto.Medication;
using Enums;
using FluentValidation;
using Localization.Validation;

namespace Services.Validation.Validators
{
    public class MedicationCreateDtoValidator : AbstractValidator<MedicationCreateDto>
    {
        public MedicationCreateDtoValidator()
        {
            RuleFor(x => x.Name)
                .Cascade(CascadeMode.Stop)
                .Must(x => !string.IsNullOrWhiteSpace(x)).WithMessage(ValidationMessages.Required(ValidationFieldNames.MedicationName))
                .Must(x => x.Trim().Length <= 30).WithMessage(ValidationMessages.MaxLength(ValidationFieldNames.MedicationName, 30));

            RuleFor(x => x.DosageValue)
                .InclusiveBetween(0.001d, 100000d)
                .WithMessage(ValidationMessages.Range(ValidationFieldNames.DosageValue, 0.001, 100000));

            RuleFor(x => x.DosageUnit)
                .Cascade(CascadeMode.Stop)
                .Must(x => !string.IsNullOrWhiteSpace(x)).WithMessage(ValidationMessages.Required(ValidationFieldNames.DosageUnit))
                .Must(x => x.Trim().Length <= 30).WithMessage(ValidationMessages.MaxLength(ValidationFieldNames.DosageUnit, 30));

            RuleFor(x => x.Frequency)
                .IsInEnum()
                .WithMessage(ValidationMessages.InvalidEnum(ValidationFieldNames.MedicationFrequency));

            RuleFor(x => x.TimesInMinutes)
                .Must(x => x is not null && x.Count > 0)
                .WithMessage(ValidationMessages.CollectionRequired(ValidationFieldNames.MedicationTimes));

            RuleForEach(x => x.TimesInMinutes)
                .InclusiveBetween(0, 1439)
                .WithMessage(ValidationMessages.InvalidTimeOfDay());

            RuleFor(x => x.TimesInMinutes)
                .Must(x => x.Distinct().Count() == x.Count)
                .WithMessage(ValidationMessages.CollectionDistinct(ValidationFieldNames.MedicationTimes));

            RuleFor(x => x.ScheduledWeekdays)
                .Must(x => x is not null && x.Count > 0)
                .WithMessage(ValidationMessages.CollectionRequired(ValidationFieldNames.ScheduledWeekdays));

            RuleForEach(x => x.ScheduledWeekdays)
                .InclusiveBetween(1, 7)
                .WithMessage(ValidationMessages.InvalidWeekdayValues());

            RuleFor(x => x.ScheduledWeekdays)
                .Must(x => x.Distinct().Count() == x.Count)
                .WithMessage(ValidationMessages.CollectionDistinct(ValidationFieldNames.ScheduledWeekdays));

            RuleFor(x => x)
                .Must(HasExpectedTimesCount)
                .WithMessage(ValidationMessages.MedicationTimesMustMatchFrequency());

            RuleFor(x => x)
                .Must(x => x.Frequency != MedicationFrequency.Weekly || x.ScheduledWeekdays.Count == 1)
                .WithMessage(ValidationMessages.WeeklyMedicationRequiresSingleWeekday());
        }

        private static bool HasExpectedTimesCount(MedicationCreateDto dto)
        {
            var expectedCount = dto.Frequency switch
            {
                MedicationFrequency.OnceDaily => 1,
                MedicationFrequency.TwiceDaily => 2,
                MedicationFrequency.ThreeTimesDaily => 3,
                MedicationFrequency.DayAfterDay => 1,
                MedicationFrequency.Weekly => 1,
                _ => 0
            };

            return expectedCount > 0 && dto.TimesInMinutes.Count == expectedCount;
        }
    }
}
