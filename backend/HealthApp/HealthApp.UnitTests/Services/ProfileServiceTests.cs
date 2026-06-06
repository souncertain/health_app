using AutoMapper;
using Data.Interfaces;
using Domain.Dto.Profile;
using Domain.Entity;
using Enums;
using FluentAssertions;
using HealthApp.UnitTests.TestDoubles;
using Moq;
using Services.Services;
using ProfileEntity = Domain.Entity.Profile;
using UserEntity = Domain.Entity.User;

namespace HealthApp.UnitTests.Services;

public sealed class ProfileServiceTests
{
    [Fact]
    public async Task GetCurrentProfilePage_ReturnsFallbackPage_WhenProfileDoesNotExist()
    {
        var repository = new Mock<IProfileRepository>();
        var bloodPressureRepository = new Mock<IBloodPressureRepository>();
        var user = new UserEntity
        {
            Id = Guid.NewGuid(),
            Email = "user@example.com",
            CreatedAt = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc),
            LastUpdatedAt = new DateTime(2026, 1, 2, 0, 0, 0, DateTimeKind.Utc)
        };
        var stats = new ProfileStatsDto { BloodPressureReadingsCount = 4 };

        repository.Setup(x => x.GetCurrentUser(It.IsAny<CancellationToken>())).ReturnsAsync(user);
        repository.Setup(x => x.GetCurrentProfile(It.IsAny<CancellationToken>())).ReturnsAsync((ProfileEntity?)null);
        repository.Setup(x => x.GetCurrentProfileStats(It.IsAny<CancellationToken>())).ReturnsAsync(stats);

        var service = new ProfileService(repository.Object, bloodPressureRepository.Object, Mock.Of<IMapper>(), new TrackingValidationService());

        var result = await service.GetCurrentProfilePage(CancellationToken.None);

        result.Email.Should().Be("user@example.com");
        result.NotificationsEnabled.Should().BeTrue();
        result.CreatedAt.Should().Be(user.CreatedAt);
        result.UpdatedAt.Should().Be(user.LastUpdatedAt);
        result.Stats.Should().BeSameAs(stats);
    }

    [Fact]
    public async Task GetCurrentProfilePage_MapsExistingProfile()
    {
        var repository = new Mock<IProfileRepository>();
        var bloodPressureRepository = new Mock<IBloodPressureRepository>();
        var birthday = DateTime.UtcNow.Date.AddYears(-25);
        var profile = new ProfileEntity
        {
            Id = Guid.NewGuid(),
            FirstName = "Иван",
            LastName = "Петров",
            Birthday = birthday,
            Sex = Sex.Male,
            Height = 181.2,
            Weight = 76.5,
            BloodType = BloodType.AB,
            ResusPhactor = true,
            PrimaryDoctor = "Терапевт",
            EmergencyContactName = "Мама",
            EmergencyContactDetails = "+79990000000",
            NotificationsEnabled = false,
            CreatedAt = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc),
            LastUpdatedAt = new DateTime(2026, 1, 5, 0, 0, 0, DateTimeKind.Utc)
        };
        var user = new UserEntity { Id = Guid.NewGuid(), Email = "ivan@example.com", Profile = profile };
        var stats = new ProfileStatsDto { MedicationsCount = 3 };

        repository.Setup(x => x.GetCurrentUser(It.IsAny<CancellationToken>())).ReturnsAsync(user);
        repository.Setup(x => x.GetCurrentProfile(It.IsAny<CancellationToken>())).ReturnsAsync(profile);
        repository.Setup(x => x.GetCurrentProfileStats(It.IsAny<CancellationToken>())).ReturnsAsync(stats);

        var service = new ProfileService(repository.Object, bloodPressureRepository.Object, Mock.Of<IMapper>(), new TrackingValidationService());

        var result = await service.GetCurrentProfilePage(CancellationToken.None);

        result.FullName.Should().Be("Иван Петров");
        result.Email.Should().Be("ivan@example.com");
        result.Gender.Should().Be("male");
        result.Age.Should().Be(25);
        result.BloodType.Should().Be("AB+");
        result.HeightCm.Should().Be(181);
        result.WeightKg.Should().Be(76.5);
        result.NotificationsEnabled.Should().BeFalse();
        result.Stats.Should().BeSameAs(stats);
    }

    [Fact]
    public async Task SaveCurrentProfile_Throws_WhenCurrentUserCannotBeResolved()
    {
        var repository = new Mock<IProfileRepository>();
        var bloodPressureRepository = new Mock<IBloodPressureRepository>();
        repository.Setup(x => x.GetCurrentUser(It.IsAny<CancellationToken>())).ReturnsAsync((UserEntity?)null);
        var validationService = new TrackingValidationService();
        var service = new ProfileService(repository.Object, bloodPressureRepository.Object, Mock.Of<IMapper>(), validationService);
        var dto = new ProfilePageUpdateDto { Email = "user@example.com" };

        var action = () => service.SaveCurrentProfile(dto, CancellationToken.None);

        await action.Should().ThrowAsync<InvalidOperationException>()
            .WithMessage("*current user*");
        validationService.ValidatedModels.Should().ContainSingle().Which.Should().BeSameAs(dto);
    }

    [Fact]
    public async Task SaveCurrentProfile_CreatesProfile_WhenItDoesNotExist()
    {
        var repository = new Mock<IProfileRepository>();
        var bloodPressureRepository = new Mock<IBloodPressureRepository>();
        var validationService = new TrackingValidationService();
        var user = new UserEntity { Id = Guid.NewGuid(), Email = "old@example.com" };
        ProfileEntity? createdProfile = null;
        var stats = new ProfileStatsDto();

        repository.Setup(x => x.GetCurrentUser(It.IsAny<CancellationToken>())).ReturnsAsync(user);
        repository.Setup(x => x.GetCurrentProfile(It.IsAny<CancellationToken>())).ReturnsAsync(() => createdProfile);
        repository.Setup(x => x.GetCurrentProfileStats(It.IsAny<CancellationToken>())).ReturnsAsync(stats);
        repository.Setup(x => x.Create(It.IsAny<ProfileEntity>(), It.IsAny<CancellationToken>()))
            .Callback<ProfileEntity, CancellationToken>((profile, _) =>
            {
                createdProfile = profile;
                user.Profile = profile;
                profile.User = user;
            })
            .Returns(Task.CompletedTask);
        repository.Setup(x => x.Save(It.IsAny<CancellationToken>())).Returns(Task.CompletedTask);

        var service = new ProfileService(repository.Object, bloodPressureRepository.Object, Mock.Of<IMapper>(), validationService);
        var dto = new ProfilePageUpdateDto
        {
            FullName = "  Анна   Смирнова  ",
            Email = "  anna@example.com ",
            Gender = "female",
            Age = 30,
            BloodType = "0-",
            HeightCm = 170,
            WeightKg = 58.5,
            PrimaryDoctor = "  Терапевт ",
            EmergencyContactName = "  Папа ",
            EmergencyContactDetails = "  +79991234567 ",
            NotificationsEnabled = false
        };

        var result = await service.SaveCurrentProfile(dto, CancellationToken.None);

        createdProfile.Should().NotBeNull();
        createdProfile!.FirstName.Should().Be("Анна");
        createdProfile.LastName.Should().Be("Смирнова");
        createdProfile.Sex.Should().Be(Sex.Female);
        createdProfile.BloodType.Should().Be(BloodType._0);
        createdProfile.ResusPhactor.Should().BeFalse();
        createdProfile.Height.Should().Be(170);
        createdProfile.Weight.Should().Be(58.5);
        createdProfile.PrimaryDoctor.Should().Be("Терапевт");
        createdProfile.EmergencyContactName.Should().Be("Папа");
        createdProfile.EmergencyContactDetails.Should().Be("+79991234567");
        createdProfile.NotificationsEnabled.Should().BeFalse();
        createdProfile.Birthday.Should().Be(DateTime.UtcNow.Date.AddYears(-30));
        user.Email.Should().Be("anna@example.com");
        repository.Verify(x => x.Create(It.IsAny<ProfileEntity>(), It.IsAny<CancellationToken>()), Times.Once);
        repository.Verify(x => x.Update(It.IsAny<ProfileEntity>(), It.IsAny<CancellationToken>()), Times.Never);
        repository.Verify(x => x.Save(It.IsAny<CancellationToken>()), Times.Once);
        result.FullName.Should().Be("Анна Смирнова");
        result.Email.Should().Be("anna@example.com");
    }

    [Fact]
    public async Task SaveCurrentProfile_UpdatesExistingProfile()
    {
        var repository = new Mock<IProfileRepository>();
        var bloodPressureRepository = new Mock<IBloodPressureRepository>();
        var validationService = new TrackingValidationService();
        var profile = new ProfileEntity
        {
            Id = Guid.NewGuid(),
            UserId = Guid.NewGuid(),
            FirstName = "Старое",
            LastName = "Имя",
            NotificationsEnabled = true,
            CreatedAt = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc)
        };
        var user = new UserEntity { Id = profile.UserId, Email = "old@example.com", Profile = profile };
        var stats = new ProfileStatsDto();

        repository.Setup(x => x.GetCurrentUser(It.IsAny<CancellationToken>())).ReturnsAsync(user);
        repository.Setup(x => x.GetCurrentProfile(It.IsAny<CancellationToken>())).ReturnsAsync(profile);
        repository.Setup(x => x.GetCurrentProfileStats(It.IsAny<CancellationToken>())).ReturnsAsync(stats);
        repository.Setup(x => x.Update(profile, It.IsAny<CancellationToken>())).Returns(Task.CompletedTask);
        repository.Setup(x => x.Save(It.IsAny<CancellationToken>())).Returns(Task.CompletedTask);

        var service = new ProfileService(repository.Object, bloodPressureRepository.Object, Mock.Of<IMapper>(), validationService);
        var dto = new ProfilePageUpdateDto
        {
            FullName = "Моноимя",
            Email = "new@example.com",
            Gender = "male",
            NotificationsEnabled = true
        };

        var result = await service.SaveCurrentProfile(dto, CancellationToken.None);

        profile.FirstName.Should().Be("Моноимя");
        profile.LastName.Should().BeEmpty();
        profile.Sex.Should().Be(Sex.Male);
        user.Email.Should().Be("new@example.com");
        repository.Verify(x => x.Update(profile, It.IsAny<CancellationToken>()), Times.Once);
        repository.Verify(x => x.Create(It.IsAny<ProfileEntity>(), It.IsAny<CancellationToken>()), Times.Never);
        result.FullName.Should().Be("Моноимя");
    }

    [Fact]
    public async Task GetCurrentHealthInsights_ReturnsCalculatedInsights()
    {
        var repository = new Mock<IProfileRepository>();
        var bloodPressureRepository = new Mock<IBloodPressureRepository>();
        var profile = new ProfileEntity
        {
            Height = 180,
            Weight = 92,
        };
        var now = DateTime.UtcNow;
        var readings = new List<BloodPressure>
        {
            new() { Systolic = 138, Diastolic = 86, Pulse = 78, RecordedAt = now.AddDays(-1) },
            new() { Systolic = 136, Diastolic = 84, Pulse = 76, RecordedAt = now.AddDays(-2) },
            new() { Systolic = 132, Diastolic = 82, Pulse = 75, RecordedAt = now.AddDays(-5) },
            new() { Systolic = 126, Diastolic = 80, Pulse = 74, RecordedAt = now.AddDays(-9) },
            new() { Systolic = 124, Diastolic = 78, Pulse = 73, RecordedAt = now.AddDays(-12) },
        };

        repository.Setup(x => x.GetCurrentProfile(It.IsAny<CancellationToken>())).ReturnsAsync(profile);
        bloodPressureRepository.Setup(x => x.GetLastValues(30)).ReturnsAsync(readings);

        var service = new ProfileService(repository.Object, bloodPressureRepository.Object, Mock.Of<IMapper>(), new TrackingValidationService());

        var result = await service.GetCurrentHealthInsights(CancellationToken.None);

        result.BloodPressure.HasReadings.Should().BeTrue();
        result.BloodPressure.LatestCategory.Should().Be("highStage1");
        result.BloodPressure.Trend.Should().NotBeNullOrEmpty();
        result.BodyMass.HasBodyMassData.Should().BeTrue();
        result.BodyMass.Bmi.Should().BeApproximately(28.4, 0.1);
        result.BodyMass.Category.Should().Be("overweight");
        result.RiskSignals.Should().NotBeEmpty();
        result.RiskSignals.Select(x => x.Key).Should().Contain("bloodPressureAttention");
        result.RiskSignals.Select(x => x.Key).Should().Contain("overweightRisk");
    }

    [Fact]
    public async Task GetCurrentHealthInsights_UsesPediatricAssessment_ForChildrenUnder13()
    {
        var repository = new Mock<IProfileRepository>();
        var bloodPressureRepository = new Mock<IBloodPressureRepository>();
        var now = DateTime.UtcNow;
        var profile = new ProfileEntity
        {
            Birthday = now.Date.AddYears(-10),
            Height = 145,
            Weight = 38,
        };
        var readings = new List<BloodPressure>
        {
            new() { Systolic = 118, Diastolic = 76, Pulse = 82, RecordedAt = now.AddDays(-1) },
            new() { Systolic = 116, Diastolic = 74, Pulse = 80, RecordedAt = now.AddDays(-3) },
        };

        repository.Setup(x => x.GetCurrentProfile(It.IsAny<CancellationToken>())).ReturnsAsync(profile);
        bloodPressureRepository.Setup(x => x.GetLastValues(30)).ReturnsAsync(readings);

        var service = new ProfileService(repository.Object, bloodPressureRepository.Object, Mock.Of<IMapper>(), new TrackingValidationService());

        var result = await service.GetCurrentHealthInsights(CancellationToken.None);

        result.BloodPressure.LatestCategory.Should().Be("requiresPediatricAssessment");
        result.BloodPressure.NormalRangePercent.Should().BeNull();
    }
}
