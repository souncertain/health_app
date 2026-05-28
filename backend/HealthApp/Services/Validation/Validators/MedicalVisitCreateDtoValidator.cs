using Domain.Dto.MedicalVisit;
using FluentValidation;
using Localization.Validation;

namespace Services.Validation.Validators
{
    public class MedicalVisitCreateDtoValidator : AbstractValidator<MedicalVisitCreateDto>
    {
        public MedicalVisitCreateDtoValidator()
        {
            RuleFor(x => x.DoctorName)
                .Cascade(CascadeMode.Stop)
                .Must(x => !string.IsNullOrWhiteSpace(x)).WithMessage(ValidationMessages.Required(ValidationFieldNames.DoctorName))
                .Must(x => x.Trim().Length <= 120).WithMessage(ValidationMessages.MaxLength(ValidationFieldNames.DoctorName, 120));

            RuleFor(x => x.Speciality)
                .Cascade(CascadeMode.Stop)
                .Must(x => !string.IsNullOrWhiteSpace(x)).WithMessage(ValidationMessages.Required(ValidationFieldNames.Specialty))
                .Must(x => x.Trim().Length <= 120).WithMessage(ValidationMessages.MaxLength(ValidationFieldNames.Specialty, 120));

            RuleFor(x => x.AppointmentDate)
                .Must(x => x != default)
                .WithMessage(ValidationMessages.InvalidDate(ValidationFieldNames.AppointmentDate));

            RuleFor(x => x.TimeInMinutes)
                .InclusiveBetween(0, 1439)
                .WithMessage(ValidationMessages.Range(ValidationFieldNames.AppointmentTime, 0, 1439));

            RuleFor(x => x.Location)
                .Cascade(CascadeMode.Stop)
                .Must(x => !string.IsNullOrWhiteSpace(x)).WithMessage(ValidationMessages.Required(ValidationFieldNames.VisitLocation))
                .Must(x => x.Trim().Length <= 255).WithMessage(ValidationMessages.MaxLength(ValidationFieldNames.VisitLocation, 255));

            RuleFor(x => x.VisitType)
                .IsInEnum()
                .WithMessage(ValidationMessages.InvalidEnum(ValidationFieldNames.VisitType));
        }
    }
}
