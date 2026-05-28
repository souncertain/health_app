using Domain.Dto.User;
using FluentValidation;
using Localization.Validation;
using Services.Validation.Infrastructure;

namespace Services.Validation.Validators
{
    public class UserCreateDtoValidator : AbstractValidator<UserCreateDto>
    {
        public UserCreateDtoValidator()
        {
            RuleFor(x => x.Email)
                .Cascade(CascadeMode.Stop)
                .Must(ValidationHelpers.HasText).WithMessage(ValidationMessages.Required(ValidationFieldNames.UserEmail))
                .Must(x => ValidationHelpers.HasMaxTrimmedLength(x, 255)).WithMessage(ValidationMessages.MaxLength(ValidationFieldNames.UserEmail, 255))
                .Must(ValidationHelpers.IsValidEmail).WithMessage(ValidationMessages.InvalidEmail());

            RuleFor(x => x.Password)
                .Cascade(CascadeMode.Stop)
                .Must(ValidationHelpers.HasText).WithMessage(ValidationMessages.Required(ValidationFieldNames.UserPassword))
                .Must(x => ValidationHelpers.HasMinTrimmedLength(x, 6)).WithMessage(ValidationMessages.MinLength(ValidationFieldNames.UserPassword, 6))
                .Must(x => ValidationHelpers.HasMaxTrimmedLength(x, 200)).WithMessage(ValidationMessages.MaxLength(ValidationFieldNames.UserPassword, 200));

            RuleFor(x => x.Phone)
                .Must(x => ValidationHelpers.HasMaxTrimmedLength(x, 20)).WithMessage(ValidationMessages.MaxLength(ValidationFieldNames.Phone, 20))
                .Must(ValidationHelpers.IsValidPhone).WithMessage(ValidationMessages.InvalidPhone());
        }
    }
}
