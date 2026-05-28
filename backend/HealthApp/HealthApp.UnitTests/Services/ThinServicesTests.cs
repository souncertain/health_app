using AutoMapper;
using Data.Interfaces;
using Domain.Dto.BloodPressure;
using Domain.Dto.HealthMetric;
using Domain.Dto.Medication;
using Domain.Dto.MetricRecords;
using Domain.Entity;
using Enums;
using FluentAssertions;
using HealthApp.UnitTests.TestDoubles;
using Moq;
using Services.Services;

namespace HealthApp.UnitTests.Services;

public sealed class ThinServicesTests
{
    [Fact]
    public async Task BloodPressureService_GetAverageValues_MapsTupleToDto()
    {
        var repository = new Mock<IBloodPressureRepository>();
        repository.Setup(x => x.GetAverageValues()).ReturnsAsync((121, 79, 64));

        var service = new BloodPressureService(repository.Object, Mock.Of<IMapper>(), new TrackingValidationService());

        var result = await service.GetAverageValues();

        result.Should().BeEquivalentTo(new BloodPressureAverageDataDto
        {
            Systolic = 121,
            Diastolic = 79,
            Pulse = 64
        });
    }

    [Fact]
    public async Task BloodPressureService_GetByDateInterval_UsesMapper()
    {
        var repository = new Mock<IBloodPressureRepository>();
        var mapper = new Mock<IMapper>();
        var entities = new List<BloodPressure> { new() { Id = Guid.NewGuid() } };
        var mapped = new List<BloodPressureDetailsDto> { new() { Id = entities[0].Id } };

        repository.Setup(x => x.GetByDateInterval(7)).ReturnsAsync(entities);
        mapper.Setup(x => x.Map<List<BloodPressureDetailsDto>>(entities)).Returns(mapped);

        var service = new BloodPressureService(repository.Object, mapper.Object, new TrackingValidationService());

        var result = await service.GetByDateInterval(7);

        result.Should().BeSameAs(mapped);
    }

    [Fact]
    public async Task BloodPressureService_GetLastValues_UsesMapper()
    {
        var repository = new Mock<IBloodPressureRepository>();
        var mapper = new Mock<IMapper>();
        var entities = new List<BloodPressure> { new() { Id = Guid.NewGuid() } };
        var mapped = new List<BloodPressureDetailsDto> { new() { Id = entities[0].Id } };

        repository.Setup(x => x.GetLastValues(3)).ReturnsAsync(entities);
        mapper.Setup(x => x.Map<List<BloodPressureDetailsDto>>(entities)).Returns(mapped);

        var service = new BloodPressureService(repository.Object, mapper.Object, new TrackingValidationService());

        var result = await service.GetLastValues(3);

        result.Should().BeSameAs(mapped);
    }

    [Fact]
    public async Task HealthMetricService_AddRecordToHealthMetric_MapsRepositoryResult()
    {
        var repository = new Mock<IHealthMetricRepository>();
        var mapper = new Mock<IMapper>();
        var metric = new HealthMetric { Id = Guid.NewGuid(), Title = "Sugar" };
        var dto = new HealthMetricDetailsDto { Id = metric.Id, Title = "Sugar", Unit = "mmol/L" };

        repository.Setup(x => x.AddRecordToHealthMetric(It.IsAny<Guid>(), It.IsAny<Guid>())).ReturnsAsync(metric);
        mapper.Setup(x => x.Map<HealthMetricDetailsDto>(metric)).Returns(dto);

        var service = new HealthMetricService(repository.Object, mapper.Object, new TrackingValidationService());

        var result = await service.AddRecordToHealthMetric(Guid.NewGuid(), Guid.NewGuid());

        result.Should().BeSameAs(dto);
    }

    [Fact]
    public async Task HealthMetricService_GetMetricTrend_DelegatesToRepository()
    {
        var repository = new Mock<IHealthMetricRepository>();
        repository.Setup(x => x.GetMetricTrend(It.IsAny<Guid>())).ReturnsAsync(MetricTrend.Up);

        var service = new HealthMetricService(repository.Object, Mock.Of<IMapper>(), new TrackingValidationService());

        var result = await service.GetMetricTrend(Guid.NewGuid());

        result.Should().Be(MetricTrend.Up);
    }

    [Fact]
    public async Task MetricRecordService_GetMetricRecordGraphProjections_DelegatesToRepository()
    {
        var repository = new Mock<IMetricRecordRepository>();
        var projections = new List<MetricRecordGraphProjection> { new() { Value = 12, RecordedAt = DateTime.UtcNow } };
        repository.Setup(x => x.GetMetricRecordGraphProjections()).ReturnsAsync(projections);

        var service = new MetricRecordService(repository.Object, Mock.Of<IMapper>(), new TrackingValidationService());

        var result = await service.GetMetricRecordGraphProjections();

        result.Should().BeSameAs(projections);
    }

    [Fact]
    public async Task MedicationService_GetSoonestNotification_DelegatesToRepository()
    {
        var repository = new Mock<IMedicationRepository>();
        var notifications = new List<MedicationSoonestNotificationDto>
        {
            new() { Name = "Test", DosageValue = 1, DosageUnit = "tablet", ScheduledAt = DateTime.UtcNow }
        };

        repository.Setup(x => x.GetSoonestNotification()).ReturnsAsync(notifications);

        var service = new MedicationService(repository.Object, Mock.Of<IMapper>(), new TrackingValidationService());

        var result = await service.GetSoonestNotification();

        result.Should().BeSameAs(notifications);
    }

    [Fact]
    public async Task MedicationService_GetMedicationStatuses_DelegatesToRepository()
    {
        var repository = new Mock<IMedicationRepository>();
        var statuses = new MedicationStatusesDto { TakenCount = 1, PendingCount = 2, MissedCount = 3 };
        repository.Setup(x => x.GetMedicationStatuses()).ReturnsAsync(statuses);

        var service = new MedicationService(repository.Object, Mock.Of<IMapper>(), new TrackingValidationService());

        var result = await service.GetMedicationStatuses();

        result.Should().BeSameAs(statuses);
    }

    [Fact]
    public async Task MedicationService_SetMedicationDailyStatus_ValidatesMapsAndReturnsDto()
    {
        var repository = new Mock<IMedicationRepository>();
        var mapper = new Mock<IMapper>();
        var validationService = new TrackingValidationService();
        var medicationId = Guid.NewGuid();
        var date = new DateOnly(2026, 5, 26);
        var entity = new MedicationDailyStatus
        {
            Id = Guid.NewGuid(),
            MedicationId = medicationId,
            Date = date,
            Status = MedicationDayStatus.Taken
        };
        var dto = new MedicationDailyStatusDetailsDto
        {
            Id = entity.Id,
            MedicationId = medicationId,
            Date = date,
            Status = MedicationDayStatus.Taken
        };

        repository.Setup(x => x.SetMedicationDailyStatus(medicationId, date, MedicationDayStatus.Taken, It.IsAny<CancellationToken>()))
            .ReturnsAsync(entity);
        mapper.Setup(x => x.Map<MedicationDailyStatusDetailsDto>(entity)).Returns(dto);

        var service = new MedicationService(repository.Object, mapper.Object, validationService);

        var result = await service.SetMedicationDailyStatus(medicationId, date, MedicationDayStatus.Taken, CancellationToken.None);

        validationService.ValidatedModels.Should().ContainSingle()
            .Which.Should().BeOfType<MedicationDailyStatusUpsertDto>();
        result.Should().BeSameAs(dto);
    }

    [Fact]
    public async Task MedicationService_SetMedicationDailyStatus_ReturnsNull_WhenRepositoryReturnsNull()
    {
        var repository = new Mock<IMedicationRepository>();
        repository.Setup(x => x.SetMedicationDailyStatus(It.IsAny<Guid>(), It.IsAny<DateOnly>(), It.IsAny<MedicationDayStatus?>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((MedicationDailyStatus?)null);

        var service = new MedicationService(repository.Object, Mock.Of<IMapper>(), new TrackingValidationService());

        var result = await service.SetMedicationDailyStatus(Guid.NewGuid(), new DateOnly(2026, 5, 26), null, CancellationToken.None);

        result.Should().BeNull();
    }
}
