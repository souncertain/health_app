using Domain.Dto.Auth;
using FluentValidation.TestHelper;
using Moq;
using Services.Interfaces;
using Services.Validation.Validators;

namespace HealthApp.UnitTests.Validation;

public sealed class AuthValidatorsTests
{
    [Fact]
    public void AuthRegisterValidator_AcceptsValidDto()
    {
        var validator = new AuthRegisterDtoValidator();
        var dto = new AuthRegisterDto
        {
            Email = "user@example.com",
            Password = "Secret123",
            Phone = "+79991234567",
            DeviceId = "device-id",
            DeviceName = "Phone"
        };

        var result = validator.TestValidate(dto);

        result.ShouldNotHaveAnyValidationErrors();
    }

    [Fact]
    public void AuthRegisterValidator_RejectsInvalidEmail()
    {
        var validator = new AuthRegisterDtoValidator();

        var result = validator.TestValidate(new AuthRegisterDto
        {
            Email = "bad-email",
            Password = "Secret123"
        });

        result.ShouldHaveValidationErrorFor(x => x.Email);
    }

    [Fact]
    public void AuthRegisterValidator_RejectsTooShortPassword()
    {
        var validator = new AuthRegisterDtoValidator();

        var result = validator.TestValidate(new AuthRegisterDto
        {
            Email = "user@example.com",
            Password = "12345"
        });

        result.ShouldHaveValidationErrorFor(x => x.Password);
    }

    [Fact]
    public void AuthRegisterValidator_RejectsInvalidPhone()
    {
        var validator = new AuthRegisterDtoValidator();

        var result = validator.TestValidate(new AuthRegisterDto
        {
            Email = "user@example.com",
            Password = "Secret123",
            Phone = "abc"
        });

        result.ShouldHaveValidationErrorFor(x => x.Phone);
    }

    [Fact]
    public void AuthLoginValidator_AcceptsValidDto()
    {
        var validator = new AuthLoginDtoValidator();
        var dto = new AuthLoginDto
        {
            Email = "user@example.com",
            Password = "Secret123"
        };

        var result = validator.TestValidate(dto);

        result.ShouldNotHaveAnyValidationErrors();
    }

    [Fact]
    public void AuthLoginValidator_RejectsMissingPassword()
    {
        var validator = new AuthLoginDtoValidator();

        var result = validator.TestValidate(new AuthLoginDto
        {
            Email = "user@example.com",
            Password = " "
        });

        result.ShouldHaveValidationErrorFor(x => x.Password);
    }

    [Fact]
    public void AuthForgotPasswordValidator_RejectsBlankEmail()
    {
        var validator = new AuthForgotPasswordRequestDtoValidator();

        var result = validator.TestValidate(new AuthForgotPasswordRequestDto
        {
            Email = " "
        });

        result.ShouldHaveValidationErrorFor(x => x.Email);
    }

    [Fact]
    public void AuthResetPasswordValidator_AcceptsValidDto()
    {
        var policy = new Mock<IPasswordResetPolicy>();
        policy.SetupGet(x => x.CodeLength).Returns(6);
        var validator = new AuthResetPasswordDtoValidator(policy.Object);
        var dto = new AuthResetPasswordDto
        {
            Email = "user@example.com",
            Code = "123456",
            NewPassword = "NewSecret123"
        };

        var result = validator.TestValidate(dto);

        result.ShouldNotHaveAnyValidationErrors();
    }

    [Fact]
    public void AuthResetPasswordValidator_RejectsWrongCodeLength()
    {
        var policy = new Mock<IPasswordResetPolicy>();
        policy.SetupGet(x => x.CodeLength).Returns(6);
        var validator = new AuthResetPasswordDtoValidator(policy.Object);

        var result = validator.TestValidate(new AuthResetPasswordDto
        {
            Email = "user@example.com",
            Code = "1234",
            NewPassword = "NewSecret123"
        });

        result.ShouldHaveValidationErrorFor(x => x.Code);
    }

    [Fact]
    public void AuthRefreshValidator_RejectsInvalidSessionId()
    {
        var validator = new AuthRefreshDtoValidator();

        var result = validator.TestValidate(new AuthRefreshDto
        {
            RefreshSessionId = "not-a-guid",
            RefreshToken = "token"
        });

        result.ShouldHaveValidationErrorFor(x => x.RefreshSessionId);
    }

    [Fact]
    public void AuthLogoutValidator_RejectsMissingToken()
    {
        var validator = new AuthLogoutDtoValidator();

        var result = validator.TestValidate(new AuthLogoutDto
        {
            RefreshSessionId = Guid.NewGuid().ToString(),
            RefreshToken = " "
        });

        result.ShouldHaveValidationErrorFor(x => x.RefreshToken);
    }

    [Fact]
    public void AuthGoogleValidator_RejectsMissingIdToken()
    {
        var validator = new AuthGoogleSignInDtoValidator();

        var result = validator.TestValidate(new AuthGoogleSignInDto
        {
            IdToken = ""
        });

        result.ShouldHaveValidationErrorFor(x => x.IdToken);
    }

    [Fact]
    public void AuthYandexValidator_RejectsTooLongDeviceName()
    {
        var validator = new AuthYandexSignInDtoValidator();

        var result = validator.TestValidate(new AuthYandexSignInDto
        {
            AccessToken = "token",
            DeviceName = new string('a', 201)
        });

        result.ShouldHaveValidationErrorFor(x => x.DeviceName);
    }
}
