using FluentAssertions;
using Services.Validation.Infrastructure;

namespace HealthApp.UnitTests.Infrastructure;

public sealed class ValidationHelpersTests
{
    [Theory]
    [InlineData("text")]
    [InlineData(" text ")]
    public void HasText_ReturnsTrue_ForMeaningfulStrings(string value)
    {
        ValidationHelpers.HasText(value).Should().BeTrue();
    }

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("   ")]
    public void HasText_ReturnsFalse_ForEmptyValues(string? value)
    {
        ValidationHelpers.HasText(value).Should().BeFalse();
    }

    [Theory]
    [InlineData("user@example.com")]
    [InlineData("USER.Name+tag@example.co.uk")]
    public void IsValidEmail_ReturnsTrue_ForValidEmail(string email)
    {
        ValidationHelpers.IsValidEmail(email).Should().BeTrue();
    }

    [Theory]
    [InlineData("")]
    [InlineData("not-an-email")]
    [InlineData("missing-at.example.com")]
    public void IsValidEmail_ReturnsFalse_ForInvalidEmail(string email)
    {
        ValidationHelpers.IsValidEmail(email).Should().BeFalse();
    }

    [Theory]
    [InlineData("+7 (999) 123-45-67")]
    [InlineData("8 800 555 35 35")]
    public void IsValidPhone_ReturnsTrue_ForSupportedPhoneFormats(string phone)
    {
        ValidationHelpers.IsValidPhone(phone).Should().BeTrue();
    }

    [Theory]
    [InlineData("abc123")]
    [InlineData("++phone??")]
    public void IsValidPhone_ReturnsFalse_ForUnsupportedPhoneFormats(string phone)
    {
        ValidationHelpers.IsValidPhone(phone).Should().BeFalse();
    }

    [Fact]
    public void IsGuid_ReturnsTrue_ForGuidString()
    {
        ValidationHelpers.IsGuid(Guid.NewGuid().ToString()).Should().BeTrue();
    }

    [Fact]
    public void IsGuid_ReturnsFalse_ForNonGuidString()
    {
        ValidationHelpers.IsGuid("guid").Should().BeFalse();
    }

    [Fact]
    public void IsNumericCode_AllowsSpacesAndValidatesExactLength()
    {
        ValidationHelpers.IsNumericCode(" 12 34 ", 4).Should().BeTrue();
    }

    [Theory]
    [InlineData("123", 4)]
    [InlineData("12A4", 4)]
    public void IsNumericCode_ReturnsFalse_ForWrongLengthOrSymbols(string code, int length)
    {
        ValidationHelpers.IsNumericCode(code, length).Should().BeFalse();
    }

    [Fact]
    public void NormalizeCompact_RemovesSpacesAndTrims()
    {
        ValidationHelpers.NormalizeCompact(" 12 3 4 ").Should().Be("1234");
    }
}
