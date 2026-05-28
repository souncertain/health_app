using Domain.Dto.BloodPressure;
using Domain.Dto.HealthMetric;
using Domain.Dto.MedicalVisit;
using Domain.Dto.MetricRecords;
using Enums;
using FluentValidation.TestHelper;
using Services.Validation.Validators;

namespace HealthApp.UnitTests.Validation;

public sealed class MetricsAndVisitsValidatorsTests
{
    [Fact]
    public void BloodPressureValidator_AcceptsValidPayload()
    {
        var validator = new BloodPressureCreateDtoValidator();

        var result = validator.TestValidate(new BloodPressureCreateDto
        {
            Systolic = 120,
            Diastolic = 80,
            Pulse = 70,
            RecordedAt = DateTime.UtcNow,
            Source = BloodPressureSource.HandNote.ToString()
        });

        result.ShouldNotHaveAnyValidationErrors();
    }

    [Fact]
    public void BloodPressureValidator_RejectsSystolicOutOfRange()
    {
        var validator = new BloodPressureCreateDtoValidator();

        var result = validator.TestValidate(new BloodPressureCreateDto
        {
            Systolic = 20,
            Diastolic = 80,
            Pulse = 70,
            RecordedAt = DateTime.UtcNow,
            Source = BloodPressureSource.HandNote.ToString()
        });

        result.ShouldHaveValidationErrorFor(x => x.Systolic);
    }

    [Fact]
    public void BloodPressureValidator_RejectsUnknownSource()
    {
        var validator = new BloodPressureCreateDtoValidator();

        var result = validator.TestValidate(new BloodPressureCreateDto
        {
            Systolic = 120,
            Diastolic = 80,
            Pulse = 70,
            RecordedAt = DateTime.UtcNow,
            Source = "Unknown"
        });

        result.ShouldHaveValidationErrorFor(x => x.Source);
    }

    [Fact]
    public void HealthMetricValidator_AcceptsValidPayload()
    {
        var validator = new HealthMetricCreateDtoValidator();

        var result = validator.TestValidate(new HealthMetricCreateDto
        {
            Title = "Сахар",
            Unit = "ммоль/л",
            TargetMin = 4,
            TargetMax = 8,
            VisualStyle = MetricVisualStyle.AmberDrop
        });

        result.ShouldNotHaveAnyValidationErrors();
    }

    [Fact]
    public void HealthMetricValidator_RejectsTargetRange_WhenMaxIsLessThanMin()
    {
        var validator = new HealthMetricCreateDtoValidator();

        var result = validator.TestValidate(new HealthMetricCreateDto
        {
            Title = "Сахар",
            Unit = "ммоль/л",
            TargetMin = 8,
            TargetMax = 4,
            VisualStyle = MetricVisualStyle.AmberDrop
        });

        result.ShouldHaveValidationErrorFor(x => x);
    }

    [Fact]
    public void MetricRecordValidator_AcceptsValidPayload()
    {
        var validator = new MetricRecordCreateDtoValidator();

        var result = validator.TestValidate(new MetricRecordCreateDto
        {
            HealthMetricId = Guid.NewGuid(),
            Value = 12,
            RecordedOn = DateTime.UtcNow.Date
        });

        result.ShouldNotHaveAnyValidationErrors();
    }

    [Fact]
    public void MetricRecordValidator_RejectsEmptyMetricId()
    {
        var validator = new MetricRecordCreateDtoValidator();

        var result = validator.TestValidate(new MetricRecordCreateDto
        {
            HealthMetricId = Guid.Empty,
            Value = 12,
            RecordedOn = DateTime.UtcNow.Date
        });

        result.ShouldHaveValidationErrorFor(x => x.HealthMetricId);
    }

    [Fact]
    public void MetricRecordValidator_RejectsDefaultDate()
    {
        var validator = new MetricRecordCreateDtoValidator();

        var result = validator.TestValidate(new MetricRecordCreateDto
        {
            HealthMetricId = Guid.NewGuid(),
            Value = 12,
            RecordedOn = default
        });

        result.ShouldHaveValidationErrorFor(x => x.RecordedOn);
    }

    [Fact]
    public void MedicalVisitValidator_AcceptsValidPayload()
    {
        var validator = new MedicalVisitCreateDtoValidator();

        var result = validator.TestValidate(new MedicalVisitCreateDto
        {
            DoctorName = "Иван Иванов",
            Speciality = "Кардиолог",
            AppointmentDate = DateTime.UtcNow.Date,
            TimeInMinutes = 10 * 60,
            Location = "Клиника",
            VisitType = MedicalVisitType.OneTime
        });

        result.ShouldNotHaveAnyValidationErrors();
    }

    [Fact]
    public void MedicalVisitValidator_RejectsInvalidTime()
    {
        var validator = new MedicalVisitCreateDtoValidator();

        var result = validator.TestValidate(new MedicalVisitCreateDto
        {
            DoctorName = "Иван Иванов",
            Speciality = "Кардиолог",
            AppointmentDate = DateTime.UtcNow.Date,
            TimeInMinutes = 1500,
            Location = "Клиника",
            VisitType = MedicalVisitType.OneTime
        });

        result.ShouldHaveValidationErrorFor(x => x.TimeInMinutes);
    }

    [Fact]
    public void MedicalVisitValidator_RejectsMissingLocation()
    {
        var validator = new MedicalVisitCreateDtoValidator();

        var result = validator.TestValidate(new MedicalVisitCreateDto
        {
            DoctorName = "Иван Иванов",
            Speciality = "Кардиолог",
            AppointmentDate = DateTime.UtcNow.Date,
            TimeInMinutes = 600,
            Location = "",
            VisitType = MedicalVisitType.OneTime
        });

        result.ShouldHaveValidationErrorFor(x => x.Location);
    }
}
