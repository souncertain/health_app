using Domain.Dto.Medication;
using Enums;
using FluentValidation.TestHelper;
using Services.Validation.Validators;

namespace HealthApp.UnitTests.Validation;

public sealed class MedicationValidatorsTests
{
    [Fact]
    public void MedicationCreateValidator_AcceptsValidOnceDailyMedication()
    {
        var validator = new MedicationCreateDtoValidator();

        var result = validator.TestValidate(CreateValidMedicationDto());

        result.ShouldNotHaveAnyValidationErrors();
    }

    [Fact]
    public void MedicationCreateValidator_AcceptsValidTwiceDailyMedication()
    {
        var validator = new MedicationCreateDtoValidator();
        var dto = CreateValidMedicationDto();
        dto.Frequency = MedicationFrequency.TwiceDaily;
        dto.TimesInMinutes = new List<int> { 8 * 60, 20 * 60 };

        var result = validator.TestValidate(dto);

        result.ShouldNotHaveAnyValidationErrors();
    }

    [Fact]
    public void MedicationCreateValidator_RejectsDoseOutOfRange()
    {
        var validator = new MedicationCreateDtoValidator();
        var dto = CreateValidMedicationDto();
        dto.DosageValue = 0;

        var result = validator.TestValidate(dto);

        result.ShouldHaveValidationErrorFor(x => x.DosageValue);
    }

    [Fact]
    public void MedicationCreateValidator_RejectsEmptyTimesCollection()
    {
        var validator = new MedicationCreateDtoValidator();
        var dto = CreateValidMedicationDto();
        dto.TimesInMinutes = [];

        var result = validator.TestValidate(dto);

        result.ShouldHaveValidationErrorFor(x => x.TimesInMinutes);
    }

    [Fact]
    public void MedicationCreateValidator_RejectsTimeOutsideDayRange()
    {
        var validator = new MedicationCreateDtoValidator();
        var dto = CreateValidMedicationDto();
        dto.TimesInMinutes = new List<int> { -1 };

        var result = validator.TestValidate(dto);

        result.ShouldHaveValidationErrorFor("TimesInMinutes[0]");
    }

    [Fact]
    public void MedicationCreateValidator_RejectsDuplicateTimes()
    {
        var validator = new MedicationCreateDtoValidator();
        var dto = CreateValidMedicationDto();
        dto.TimesInMinutes = new List<int> { 480, 480 };
        dto.Frequency = MedicationFrequency.TwiceDaily;

        var result = validator.TestValidate(dto);

        result.ShouldHaveValidationErrorFor(x => x.TimesInMinutes);
    }

    [Fact]
    public void MedicationCreateValidator_RejectsFrequencyTimeMismatch()
    {
        var validator = new MedicationCreateDtoValidator();
        var dto = CreateValidMedicationDto();
        dto.Frequency = MedicationFrequency.ThreeTimesDaily;
        dto.TimesInMinutes = new List<int> { 480, 720 };

        var result = validator.TestValidate(dto);

        result.ShouldHaveValidationErrorFor(x => x);
    }

    [Fact]
    public void MedicationCreateValidator_RejectsWeeklyMedicationWithoutSingleWeekday()
    {
        var validator = new MedicationCreateDtoValidator();
        var dto = CreateValidMedicationDto();
        dto.Frequency = MedicationFrequency.Weekly;
        dto.ScheduledWeekdays = new List<int> { 1, 3 };

        var result = validator.TestValidate(dto);

        result.ShouldHaveValidationErrorFor(x => x);
    }

    [Fact]
    public void MedicationCreateValidator_RejectsWeekdayOutsideIsoRange()
    {
        var validator = new MedicationCreateDtoValidator();
        var dto = CreateValidMedicationDto();
        dto.ScheduledWeekdays = new List<int> { 0 };

        var result = validator.TestValidate(dto);

        result.ShouldHaveValidationErrorFor("ScheduledWeekdays[0]");
    }

    [Fact]
    public void MedicationDailyStatusValidator_AcceptsValidPayload()
    {
        var validator = new MedicationDailyStatusUpsertDtoValidator();
        var dto = new MedicationDailyStatusUpsertDto
        {
            Date = new DateOnly(2026, 5, 26),
            Status = MedicationDayStatus.Taken
        };

        var result = validator.TestValidate(dto);

        result.ShouldNotHaveAnyValidationErrors();
    }

    [Fact]
    public void MedicationDailyStatusValidator_RejectsDefaultDate()
    {
        var validator = new MedicationDailyStatusUpsertDtoValidator();

        var result = validator.TestValidate(new MedicationDailyStatusUpsertDto());

        result.ShouldHaveValidationErrorFor(x => x.Date);
    }

    private static MedicationCreateDto CreateValidMedicationDto()
    {
        return new MedicationCreateDto
        {
            Name = "Витамин C",
            DosageValue = 1,
            DosageUnit = "таблетка",
            Frequency = MedicationFrequency.OnceDaily,
            TimesInMinutes = new List<int> { 8 * 60 },
            NotificationsEnabled = true,
            ScheduledWeekdays = new List<int> { 1, 2, 3, 4, 5, 6, 7 }
        };
    }
}
