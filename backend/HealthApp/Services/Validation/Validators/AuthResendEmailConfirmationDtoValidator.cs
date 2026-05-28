using Domain.Dto.Auth;
using FluentValidation;
using Localization.Validation;
using Services.Validation.Infrastructure;

namespace Services.Validation.Validators
{
    public class AuthResendEmailConfirmationDtoValidator : AbstractValidator<AuthResendEmailConfirmationDto>
    {
        public AuthResendEmailConfirmationDtoValidator()
        {
            RuleFor(x => x.Email)
                .Cascade(CascadeMode.Stop)
                .Must(ValidationHelpers.HasText).WithMessage(ValidationMessages.Required(ValidationFieldNames.Email))
                .Must(x => ValidationHelpers.HasMaxTrimmedLength(x, 255)).WithMessage(ValidationMessages.MaxLength(ValidationFieldNames.Email, 255))
                .Must(ValidationHelpers.IsValidEmail).WithMessage(ValidationMessages.InvalidEmail());
        }
    }
}
