using Domain.Dto.MetricRecords;
using FluentValidation;
using Localization.Validation;

namespace Services.Validation.Validators
{
    public class MetricRecordCreateDtoValidator : AbstractValidator<MetricRecordCreateDto>
    {
        public MetricRecordCreateDtoValidator()
        {
            RuleFor(x => x.HealthMetricId)
                .NotEmpty()
                .WithMessage(ValidationMessages.Required(ValidationFieldNames.MetricId));

            RuleFor(x => x.Value)
                .InclusiveBetween(-100000d, 100000d)
                .WithMessage(ValidationMessages.Range(ValidationFieldNames.MetricValue, -100000, 100000));

            RuleFor(x => x.RecordedOn)
                .Must(x => x != default)
                .WithMessage(ValidationMessages.InvalidDate(ValidationFieldNames.MetricRecordedOn));
        }
    }
}
