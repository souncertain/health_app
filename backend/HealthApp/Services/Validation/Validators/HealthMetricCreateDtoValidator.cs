using Domain.Dto.HealthMetric;
using FluentValidation;
using Localization.Validation;

namespace Services.Validation.Validators
{
    public class HealthMetricCreateDtoValidator : AbstractValidator<HealthMetricCreateDto>
    {
        public HealthMetricCreateDtoValidator()
        {
            RuleFor(x => x.Title)
                .Cascade(CascadeMode.Stop)
                .Must(x => !string.IsNullOrWhiteSpace(x)).WithMessage(ValidationMessages.Required(ValidationFieldNames.MetricTitle))
                .Must(x => x.Trim().Length <= 100).WithMessage(ValidationMessages.MaxLength(ValidationFieldNames.MetricTitle, 100));

            RuleFor(x => x.Unit)
                .Cascade(CascadeMode.Stop)
                .Must(x => !string.IsNullOrWhiteSpace(x)).WithMessage(ValidationMessages.Required(ValidationFieldNames.MetricUnit))
                .Must(x => x.Trim().Length <= 30).WithMessage(ValidationMessages.MaxLength(ValidationFieldNames.MetricUnit, 30));

            RuleFor(x => x.TargetMin)
                .InclusiveBetween(-100000d, 100000d)
                .WithMessage(ValidationMessages.Range(ValidationFieldNames.TargetMin, -100000, 100000));

            RuleFor(x => x.TargetMax)
                .InclusiveBetween(-100000d, 100000d)
                .WithMessage(ValidationMessages.Range(ValidationFieldNames.TargetMax, -100000, 100000));

            RuleFor(x => x)
                .Must(x => x.TargetMax >= x.TargetMin)
                .WithMessage(ValidationMessages.MetricTargetRangeInvalid());

            RuleFor(x => x.VisualStyle)
                .IsInEnum()
                .WithMessage(ValidationMessages.InvalidEnum(ValidationFieldNames.MetricVisualStyle));
        }
    }
}
