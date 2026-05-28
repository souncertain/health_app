using Domain.Dto.Auth;
using FluentValidation;
using Localization.Validation;
using Services.Interfaces;
using Services.Validation.Infrastructure;

namespace Services.Validation.Validators
{
    public class AuthResetPasswordDtoValidator : AbstractValidator<AuthResetPasswordDto>
    {
        public AuthResetPasswordDtoValidator(IPasswordResetPolicy passwordResetPolicy)
        {
            RuleFor(x => x.Email)
                .Cascade(CascadeMode.Stop)
                .Must(ValidationHelpers.HasText).WithMessage(ValidationMessages.Required(ValidationFieldNames.Email))
                .Must(x => ValidationHelpers.HasMaxTrimmedLength(x, 255)).WithMessage(ValidationMessages.MaxLength(ValidationFieldNames.Email, 255))
                .Must(ValidationHelpers.IsValidEmail).WithMessage(ValidationMessages.InvalidEmail());

            RuleFor(x => x.Code)
                .Cascade(CascadeMode.Stop)
                .Must(ValidationHelpers.HasText).WithMessage(ValidationMessages.Required(ValidationFieldNames.ResetCode))
                .Must(x => ValidationHelpers.IsNumericCode(x, passwordResetPolicy.CodeLength))
                .WithMessage(ValidationMessages.PasswordResetCodeLength(passwordResetPolicy.CodeLength));

            RuleFor(x => x.NewPassword)
                .Cascade(CascadeMode.Stop)
                .Must(ValidationHelpers.HasText).WithMessage(ValidationMessages.Required(ValidationFieldNames.NewPassword))
                .Must(x => ValidationHelpers.HasMinTrimmedLength(x, 6)).WithMessage(ValidationMessages.MinLength(ValidationFieldNames.NewPassword, 6))
                .Must(x => ValidationHelpers.HasMaxTrimmedLength(x, 200)).WithMessage(ValidationMessages.MaxLength(ValidationFieldNames.NewPassword, 200));
        }
    }
}
