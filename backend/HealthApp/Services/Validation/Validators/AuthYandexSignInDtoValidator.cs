using Domain.Dto.Auth;
using FluentValidation;
using Localization.Validation;
using Services.Validation.Infrastructure;

namespace Services.Validation.Validators
{
    public class AuthYandexSignInDtoValidator : AbstractValidator<AuthYandexSignInDto>
    {
        public AuthYandexSignInDtoValidator()
        {
            RuleFor(x => x.AccessToken)
                .Cascade(CascadeMode.Stop)
                .Must(ValidationHelpers.HasText).WithMessage(ValidationMessages.Required(ValidationFieldNames.YandexAccessToken))
                .Must(x => ValidationHelpers.HasMaxTrimmedLength(x, 4096)).WithMessage(ValidationMessages.MaxLength(ValidationFieldNames.YandexAccessToken, 4096));

            RuleFor(x => x.DeviceId)
                .Must(x => ValidationHelpers.HasMaxTrimmedLength(x, 120)).WithMessage(ValidationMessages.MaxLength(ValidationFieldNames.DeviceId, 120));

            RuleFor(x => x.DeviceName)
                .Must(x => ValidationHelpers.HasMaxTrimmedLength(x, 200)).WithMessage(ValidationMessages.MaxLength(ValidationFieldNames.DeviceName, 200));
        }
    }
}
