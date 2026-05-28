using Domain.Dto.Profile;
using FluentValidation;
using Localization.Validation;
using Services.Validation.Infrastructure;

namespace Services.Validation.Validators
{
    public class ProfileCreateDtoValidator : AbstractValidator<ProfileCreateDto>
    {
        public ProfileCreateDtoValidator()
        {
            RuleFor(x => x.FirstName)
                .Cascade(CascadeMode.Stop)
                .Must(ValidationHelpers.HasText).WithMessage(ValidationMessages.Required(ValidationFieldNames.FirstName))
                .Must(x => ValidationHelpers.HasMaxTrimmedLength(x, 100)).WithMessage(ValidationMessages.MaxLength(ValidationFieldNames.FirstName, 100));

            RuleFor(x => x.LastName)
                .Cascade(CascadeMode.Stop)
                .Must(ValidationHelpers.HasText).WithMessage(ValidationMessages.Required(ValidationFieldNames.LastName))
                .Must(x => ValidationHelpers.HasMaxTrimmedLength(x, 100)).WithMessage(ValidationMessages.MaxLength(ValidationFieldNames.LastName, 100));

            RuleFor(x => x.Birthday)
                .Must(x => !x.HasValue || x.Value.Date <= DateTime.UtcNow.Date)
                .WithMessage(ValidationMessages.DateCannotBeInFuture(ValidationFieldNames.Birthday));

            RuleFor(x => x.AvatarUrl)
                .Must(x => ValidationHelpers.HasMaxTrimmedLength(x, 2048)).WithMessage(ValidationMessages.MaxLength(ValidationFieldNames.AvatarUrl, 2048))
                .Must(ValidationHelpers.IsAbsoluteUri).WithMessage(ValidationMessages.InvalidUrl(ValidationFieldNames.AvatarUrl));

            RuleFor(x => x.Height)
                .InclusiveBetween(30d, 300d)
                .When(x => x.Height.HasValue)
                .WithMessage(ValidationMessages.Range(ValidationFieldNames.Height, 30, 300));

            RuleFor(x => x.Weight)
                .InclusiveBetween(1d, 700d)
                .When(x => x.Weight.HasValue)
                .WithMessage(ValidationMessages.Range(ValidationFieldNames.Weight, 1, 700));

            RuleFor(x => x.PrimaryDoctor)
                .Must(x => ValidationHelpers.HasMaxTrimmedLength(x, 150)).WithMessage(ValidationMessages.MaxLength(ValidationFieldNames.PrimaryDoctor, 150));

            RuleFor(x => x.EmergencyContactName)
                .Must(x => ValidationHelpers.HasMaxTrimmedLength(x, 120)).WithMessage(ValidationMessages.MaxLength(ValidationFieldNames.EmergencyContactName, 120));

            RuleFor(x => x.EmergencyContactDetails)
                .Must(x => ValidationHelpers.HasMaxTrimmedLength(x, 255)).WithMessage(ValidationMessages.MaxLength(ValidationFieldNames.EmergencyContactDetails, 255));

            RuleFor(x => x.Sex)
                .Must(x => !x.HasValue || Enum.IsDefined(x.Value))
                .WithMessage(ValidationMessages.InvalidEnum(ValidationFieldNames.Gender));

            RuleFor(x => x.BloodType)
                .Must(x => !x.HasValue || Enum.IsDefined(x.Value))
                .WithMessage(ValidationMessages.InvalidEnum(ValidationFieldNames.BloodType));
        }
    }
}
