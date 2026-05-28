using Domain.Dto.Auth;
using FluentValidation;
using Localization.Validation;
using Services.Validation.Infrastructure;

namespace Services.Validation.Validators
{
    public class AuthConfirmEmailDtoValidator : AbstractValidator<AuthConfirmEmailDto>
    {
        public AuthConfirmEmailDtoValidator()
        {
            RuleFor(x => x.Email)
                .Cascade(CascadeMode.Stop)
                .Must(ValidationHelpers.HasText).WithMessage(ValidationMessages.Required(ValidationFieldNames.Email))
                .Must(x => ValidationHelpers.HasMaxTrimmedLength(x, 255)).WithMessage(ValidationMessages.MaxLength(ValidationFieldNames.Email, 255))
                .Must(ValidationHelpers.IsValidEmail).WithMessage(ValidationMessages.InvalidEmail());

            RuleFor(x => x.Code)
                .Cascade(CascadeMode.Stop)
                .Must(ValidationHelpers.HasText).WithMessage(ValidationMessages.Required(ValidationFieldNames.ConfirmationCode))
                .Must(x => ValidationHelpers.HasMinTrimmedLength(x, 4)).WithMessage(ValidationMessages.MinLength(ValidationFieldNames.ConfirmationCode, 4))
                .Must(x => ValidationHelpers.HasMaxTrimmedLength(x, 20)).WithMessage(ValidationMessages.MaxLength(ValidationFieldNames.ConfirmationCode, 20));

            RuleFor(x => x.DeviceId)
                .Must(x => ValidationHelpers.HasMaxTrimmedLength(x, 120)).WithMessage(ValidationMessages.MaxLength(ValidationFieldNames.DeviceId, 120));

            RuleFor(x => x.DeviceName)
                .Must(x => ValidationHelpers.HasMaxTrimmedLength(x, 200)).WithMessage(ValidationMessages.MaxLength(ValidationFieldNames.DeviceName, 200));
        }
    }
}
