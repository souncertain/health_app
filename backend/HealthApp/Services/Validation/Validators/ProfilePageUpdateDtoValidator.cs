using Domain.Dto.Profile;
using FluentValidation;
using Localization.Validation;
using Services.Validation.Infrastructure;

namespace Services.Validation.Validators
{
    public class ProfilePageUpdateDtoValidator : AbstractValidator<ProfilePageUpdateDto>
    {
        private static readonly HashSet<string> AllowedGenders = new(StringComparer.OrdinalIgnoreCase)
        {
            "male",
            "female",
            "unspecified"
        };

        private static readonly HashSet<string> AllowedBloodTypes = new(StringComparer.OrdinalIgnoreCase)
        {
            "O",
            "O+",
            "O-",
            "A",
            "A+",
            "A-",
            "B",
            "B+",
            "B-",
            "AB",
            "AB+",
            "AB-"
        };

        public ProfilePageUpdateDtoValidator()
        {
            RuleFor(x => x.FullName)
                .Must(x => ValidationHelpers.HasMaxTrimmedLength(x, 200))
                .WithMessage(ValidationMessages.MaxLength(ValidationFieldNames.FullName, 200));

            RuleFor(x => x.Email)
                .Cascade(CascadeMode.Stop)
                .Must(ValidationHelpers.HasText).WithMessage(ValidationMessages.Required(ValidationFieldNames.Email))
                .Must(x => ValidationHelpers.HasMaxTrimmedLength(x, 255)).WithMessage(ValidationMessages.MaxLength(ValidationFieldNames.Email, 255))
                .Must(ValidationHelpers.IsValidEmail).WithMessage(ValidationMessages.InvalidEmail());

            RuleFor(x => x.Phone)
                .Must(x => ValidationHelpers.HasMaxTrimmedLength(x, 20))
                .WithMessage(ValidationMessages.MaxLength(ValidationFieldNames.Phone, 20))
                .Must(ValidationHelpers.IsValidPhone)
                .WithMessage(ValidationMessages.InvalidPhone());

            RuleFor(x => x.Gender)
                .Must(x => string.IsNullOrWhiteSpace(x) || AllowedGenders.Contains(x.Trim()))
                .WithMessage(ValidationMessages.InvalidGender());

            RuleFor(x => x.Birthday)
                .Must(x => !x.HasValue || x.Value.Date <= DateTime.UtcNow.Date)
                .WithMessage(ValidationMessages.DateCannotBeInFuture(ValidationFieldNames.Birthday));

            RuleFor(x => x.Birthday)
                .Must(x => !x.HasValue || x.Value.Date >= DateTime.UtcNow.Date.AddYears(-130))
                .WithMessage(ValidationMessages.Range(ValidationFieldNames.Birthday, DateTime.UtcNow.Date.AddYears(-130).ToString("dd.MM.yyyy"), DateTime.UtcNow.Date.ToString("dd.MM.yyyy")));

            RuleFor(x => x.Age)
                .InclusiveBetween(0, 130)
                .When(x => x.Age.HasValue)
                .WithMessage(ValidationMessages.Range(ValidationFieldNames.Age, 0, 130));

            RuleFor(x => x.BloodType)
                .Must(x => string.IsNullOrWhiteSpace(x) || AllowedBloodTypes.Contains(x.Trim().Replace('0', 'O')))
                .WithMessage(ValidationMessages.InvalidBloodType());

            RuleFor(x => x.HeightCm)
                .InclusiveBetween(30, 300)
                .When(x => x.HeightCm.HasValue)
                .WithMessage(ValidationMessages.Range(ValidationFieldNames.Height, 30, 300));

            RuleFor(x => x.WeightKg)
                .InclusiveBetween(1d, 700d)
                .When(x => x.WeightKg.HasValue)
                .WithMessage(ValidationMessages.Range(ValidationFieldNames.Weight, 1, 700));

            RuleFor(x => x.PrimaryDoctor)
                .Must(x => ValidationHelpers.HasMaxTrimmedLength(x, 150)).WithMessage(ValidationMessages.MaxLength(ValidationFieldNames.PrimaryDoctor, 150));

            RuleFor(x => x.EmergencyContactName)
                .Must(x => ValidationHelpers.HasMaxTrimmedLength(x, 120)).WithMessage(ValidationMessages.MaxLength(ValidationFieldNames.EmergencyContactName, 120));

            RuleFor(x => x.EmergencyContactDetails)
                .Must(x => ValidationHelpers.HasMaxTrimmedLength(x, 255)).WithMessage(ValidationMessages.MaxLength(ValidationFieldNames.EmergencyContactDetails, 255));
        }
    }
}
