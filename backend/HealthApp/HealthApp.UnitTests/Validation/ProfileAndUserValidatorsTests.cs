using Domain.Dto.Profile;
using Domain.Dto.User;
using FluentValidation.TestHelper;
using Services.Validation.Validators;

namespace HealthApp.UnitTests.Validation;

public sealed class ProfileAndUserValidatorsTests
{
    [Fact]
    public void ProfileCreateValidator_AcceptsValidPayload()
    {
        var validator = new ProfileCreateDtoValidator();
        var dto = new ProfileCreateDto
        {
            FirstName = "Иван",
            LastName = "Петров",
            Birthday = DateTime.UtcNow.Date.AddYears(-30),
            AvatarUrl = "https://example.com/avatar.png",
            Height = 180,
            Weight = 80
        };

        var result = validator.TestValidate(dto);

        result.ShouldNotHaveAnyValidationErrors();
    }

    [Fact]
    public void ProfileCreateValidator_RejectsFutureBirthday()
    {
        var validator = new ProfileCreateDtoValidator();

        var result = validator.TestValidate(new ProfileCreateDto
        {
            FirstName = "Иван",
            LastName = "Петров",
            Birthday = DateTime.UtcNow.Date.AddDays(1)
        });

        result.ShouldHaveValidationErrorFor(x => x.Birthday);
    }

    [Fact]
    public void ProfileCreateValidator_RejectsInvalidAvatarUrl()
    {
        var validator = new ProfileCreateDtoValidator();

        var result = validator.TestValidate(new ProfileCreateDto
        {
            FirstName = "Иван",
            LastName = "Петров",
            AvatarUrl = "not-a-url"
        });

        result.ShouldHaveValidationErrorFor(x => x.AvatarUrl);
    }

    [Fact]
    public void ProfilePageUpdateValidator_AcceptsValidPayload()
    {
        var validator = new ProfilePageUpdateDtoValidator();
        var dto = new ProfilePageUpdateDto
        {
            FullName = "Иван Петров",
            Email = "ivan@example.com",
            Gender = "male",
            Age = 30,
            BloodType = "AB+",
            HeightCm = 180,
            WeightKg = 80.5,
            PrimaryDoctor = "Терапевт",
            EmergencyContactName = "Мама",
            EmergencyContactDetails = "+79990000000"
        };

        var result = validator.TestValidate(dto);

        result.ShouldNotHaveAnyValidationErrors();
    }

    [Fact]
    public void ProfilePageUpdateValidator_RejectsInvalidGender()
    {
        var validator = new ProfilePageUpdateDtoValidator();

        var result = validator.TestValidate(new ProfilePageUpdateDto
        {
            FullName = "Иван",
            Email = "ivan@example.com",
            Gender = "robot"
        });

        result.ShouldHaveValidationErrorFor(x => x.Gender);
    }

    [Fact]
    public void ProfilePageUpdateValidator_RejectsInvalidBloodType()
    {
        var validator = new ProfilePageUpdateDtoValidator();

        var result = validator.TestValidate(new ProfilePageUpdateDto
        {
            FullName = "Иван",
            Email = "ivan@example.com",
            BloodType = "XX"
        });

        result.ShouldHaveValidationErrorFor(x => x.BloodType);
    }

    [Fact]
    public void ProfilePageUpdateValidator_RejectsAgeOutsideRange()
    {
        var validator = new ProfilePageUpdateDtoValidator();

        var result = validator.TestValidate(new ProfilePageUpdateDto
        {
            FullName = "Иван",
            Email = "ivan@example.com",
            Age = 140
        });

        result.ShouldHaveValidationErrorFor(x => x.Age);
    }

    [Fact]
    public void ProfilePageUpdateValidator_RejectsMissingEmail()
    {
        var validator = new ProfilePageUpdateDtoValidator();

        var result = validator.TestValidate(new ProfilePageUpdateDto
        {
            FullName = "Иван",
            Email = " "
        });

        result.ShouldHaveValidationErrorFor(x => x.Email);
    }

    [Fact]
    public void UserCreateValidator_AcceptsValidPayload()
    {
        var validator = new UserCreateDtoValidator();

        var result = validator.TestValidate(new UserCreateDto
        {
            Email = "user@example.com",
            Password = "Secret123",
            Phone = "+79990000000"
        });

        result.ShouldNotHaveAnyValidationErrors();
    }

    [Fact]
    public void UserCreateValidator_RejectsShortPassword()
    {
        var validator = new UserCreateDtoValidator();

        var result = validator.TestValidate(new UserCreateDto
        {
            Email = "user@example.com",
            Password = "12345"
        });

        result.ShouldHaveValidationErrorFor(x => x.Password);
    }
}
