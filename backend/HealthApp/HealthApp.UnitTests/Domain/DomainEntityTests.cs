using Domain.Entity;
using Enums;
using FluentAssertions;

namespace HealthApp.UnitTests.Domain;

public sealed class DomainEntityTests
{
    [Theory]
    [InlineData(119, 79, BloodPressureCategory.Normal)]
    [InlineData(120, 79, BloodPressureCategory.Elevated)]
    [InlineData(130, 79, BloodPressureCategory.HighStage1)]
    [InlineData(140, 89, BloodPressureCategory.HighStage2)]
    [InlineData(181, 100, BloodPressureCategory.HypertensiveCrisis)]
    public void BloodPressure_Category_ReturnsExpectedBand(int systolic, int diastolic, BloodPressureCategory expected)
    {
        var bloodPressure = new BloodPressure
        {
            Systolic = systolic,
            Diastolic = diastolic,
            Pulse = 70,
        };

        bloodPressure.Category.Should().Be(expected);
    }

    [Theory]
    [InlineData(DayOfWeek.Monday, 1)]
    [InlineData(DayOfWeek.Sunday, 7)]
    public void Medication_ToIsoWeekday_MapsDayOfWeekCorrectly(DayOfWeek dayOfWeek, int expected)
    {
        Medication.ToIsoWeekday(dayOfWeek).Should().Be(expected);
    }

    [Fact]
    public void Medication_IsScheduledForWeekday_ReturnsTrue_WhenWeekdayPresent()
    {
        var medication = new Medication
        {
            ScheduledWeekdays = new List<int> { 1, 3, 5 }
        };

        medication.IsScheduledForWeekday(3).Should().BeTrue();
    }

    [Fact]
    public void Medication_IsScheduledForDate_ReturnsFalse_WhenDateWeekdayIsMissing()
    {
        var medication = new Medication
        {
            ScheduledWeekdays = new List<int> { 1, 2, 3 }
        };

        medication.IsScheduledForDate(new DateOnly(2026, 5, 31)).Should().BeFalse();
    }

    [Fact]
    public void MedicalVisit_ScheduledAt_ComposesDateAndTime()
    {
        var visit = new MedicalVisit
        {
            AppointmentDate = new DateTime(2026, 5, 23),
            TimeInMinutes = 14 * 60 + 45
        };

        visit.ScheduledAt.Should().Be(new DateTime(2026, 5, 23, 14, 45, 0));
    }
}
