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

        var service = new ProfileService(repository.Object, Mock.Of<IMapper>(), new TrackingValidationService());

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

        var service = new ProfileService(repository.Object, Mock.Of<IMapper>(), new TrackingValidationService());

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
        repository.Setup(x => x.GetCurrentUser(It.IsAny<CancellationToken>())).ReturnsAsync((UserEntity?)null);
        var validationService = new TrackingValidationService();
        var service = new ProfileService(repository.Object, Mock.Of<IMapper>(), validationService);
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

        var service = new ProfileService(repository.Object, Mock.Of<IMapper>(), validationService);
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

        var service = new ProfileService(repository.Object, Mock.Of<IMapper>(), validationService);
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
}
