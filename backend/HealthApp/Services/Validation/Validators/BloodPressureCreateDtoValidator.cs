using Domain.Dto.BloodPressure;
using Enums;
using FluentValidation;
using Localization.Validation;
using Services.Validation.Infrastructure;

namespace Services.Validation.Validators
{
    public class BloodPressureCreateDtoValidator : AbstractValidator<BloodPressureCreateDto>
    {
        public BloodPressureCreateDtoValidator()
        {
            RuleFor(x => x.Systolic)
                .InclusiveBetween(40, 300)
                .WithMessage(ValidationMessages.Range(ValidationFieldNames.Systolic, 40, 300));

            RuleFor(x => x.Diastolic)
                .InclusiveBetween(30, 200)
                .WithMessage(ValidationMessages.Range(ValidationFieldNames.Diastolic, 30, 200));

            RuleFor(x => x.Pulse)
                .InclusiveBetween(20, 250)
                .WithMessage(ValidationMessages.Range(ValidationFieldNames.Pulse, 20, 250));

            RuleFor(x => x.RecordedAt)
                .Must(x => x != default)
                .WithMessage(ValidationMessages.InvalidDate(ValidationFieldNames.RecordedAt));

            RuleFor(x => x.Source)
                .Cascade(CascadeMode.Stop)
                .Must(ValidationHelpers.HasText).WithMessage(ValidationMessages.Required(ValidationFieldNames.PressureSource))
                .Must(x => ValidationHelpers.HasMaxTrimmedLength(x, 50)).WithMessage(ValidationMessages.MaxLength(ValidationFieldNames.PressureSource, 50))
                .Must(x => Enum.TryParse<BloodPressureSource>(x, ignoreCase: true, out _))
                .WithMessage(ValidationMessages.InvalidEnum(ValidationFieldNames.PressureSource));
        }
    }
}
