using Domain.Dto.Auth;
using FluentValidation;
using Localization.Validation;
using Services.Validation.Infrastructure;

namespace Services.Validation.Validators
{
    public class AuthLogoutDtoValidator : AbstractValidator<AuthLogoutDto>
    {
        public AuthLogoutDtoValidator()
        {
            RuleFor(x => x.RefreshSessionId)
                .Cascade(CascadeMode.Stop)
                .Must(ValidationHelpers.HasText).WithMessage(ValidationMessages.Required(ValidationFieldNames.RefreshSessionId))
                .Must(ValidationHelpers.IsGuid).WithMessage(ValidationMessages.InvalidGuid(ValidationFieldNames.RefreshSessionId));

            RuleFor(x => x.RefreshToken)
                .Cascade(CascadeMode.Stop)
                .Must(ValidationHelpers.HasText).WithMessage(ValidationMessages.Required(ValidationFieldNames.RefreshToken))
                .Must(x => ValidationHelpers.HasMaxTrimmedLength(x, 512)).WithMessage(ValidationMessages.MaxLength(ValidationFieldNames.RefreshToken, 512));
        }
    }
}
