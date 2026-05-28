using Domain.Dto.Auth;
using FluentValidation;
using Localization.Validation;
using Services.Validation.Infrastructure;

namespace Services.Validation.Validators
{
    public class AuthLoginDtoValidator : AbstractValidator<AuthLoginDto>
    {
        public AuthLoginDtoValidator()
        {
            RuleFor(x => x.Email)
                .Cascade(CascadeMode.Stop)
                .Must(ValidationHelpers.HasText).WithMessage(ValidationMessages.Required(ValidationFieldNames.Email))
                .Must(x => ValidationHelpers.HasMaxTrimmedLength(x, 255)).WithMessage(ValidationMessages.MaxLength(ValidationFieldNames.Email, 255))
                .Must(ValidationHelpers.IsValidEmail).WithMessage(ValidationMessages.InvalidEmail());

            RuleFor(x => x.Password)
                .Cascade(CascadeMode.Stop)
                .Must(ValidationHelpers.HasText).WithMessage(ValidationMessages.Required(ValidationFieldNames.Password))
                .Must(x => ValidationHelpers.HasMinTrimmedLength(x, 6)).WithMessage(ValidationMessages.MinLength(ValidationFieldNames.Password, 6))
                .Must(x => ValidationHelpers.HasMaxTrimmedLength(x, 200)).WithMessage(ValidationMessages.MaxLength(ValidationFieldNames.Password, 200));

            RuleFor(x => x.DeviceId)
                .Must(x => ValidationHelpers.HasMaxTrimmedLength(x, 120)).WithMessage(ValidationMessages.MaxLength(ValidationFieldNames.DeviceId, 120));

            RuleFor(x => x.DeviceName)
                .Must(x => ValidationHelpers.HasMaxTrimmedLength(x, 200)).WithMessage(ValidationMessages.MaxLength(ValidationFieldNames.DeviceName, 200));
        }
    }
}
