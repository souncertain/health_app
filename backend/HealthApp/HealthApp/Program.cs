using Data;
using Data.Interfaces;
using Data.Repositories;
using Domain.Dto.Auth;
using Domain.Dto.BloodPressure;
using Domain.Dto.HealthMetric;
using Domain.Dto.MedicalVisit;
using Domain.Dto.Medication;
using Domain.Dto.MetricRecords;
using Domain.Dto.Profile;
using Domain.Dto.User;
using Domain.Exceptions;
using FluentValidation;
using HealthApp.Configuration;
using HealthApp.Infrastructure;
using HealthApp.Infrastructure.Ai;
using HealthApp.Infrastructure.Auth;
using HealthApp.Infrastructure.Email;
using Localization.Validation;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using Services.Interfaces;
using Services.Mappers;
using Services.Services;
using Services.Validation.Infrastructure;
using Services.Validation.Validators;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.Configure<ApiBehaviorOptions>(options =>
{
    options.SuppressModelStateInvalidFilter = true;
});

builder.Configuration.AddJsonFile("appsettings.json");
string connection = builder.Configuration.GetConnectionString("EFPostgres")!;
builder.Services.Configure<AuthOptions>(builder.Configuration.GetSection(AuthOptions.SectionName));
builder.Services.Configure<EmailOptions>(builder.Configuration.GetSection(EmailOptions.SectionName));
builder.Services.Configure<DoctorNoteScannerOptions>(builder.Configuration.GetSection(DoctorNoteScannerOptions.SectionName));
builder.Services.AddDbContext<HealthAppDbContext>(options => options.UseNpgsql(connection));
builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<ICurrentUserContext, HttpCurrentUserContext>();
builder.Services.AddHttpClient<IYandexIdentityProviderClient, YandexIdentityProviderClient>();
builder.Services.AddHttpClient<IDoctorNoteScannerService, OpenAiDoctorNoteScannerService>();
builder.Services.AddScoped<IGoogleIdentityTokenValidator, GoogleIdentityTokenValidator>();
builder.Services.AddScoped<IJwtTokenFactory, JwtTokenFactory>();
builder.Services.AddScoped<IPasswordHashService, PasswordHashService>();
builder.Services.AddScoped<IRefreshTokenFactory, RefreshTokenFactory>();
builder.Services.AddScoped<IOneTimeCodeFactory, OneTimeCodeFactory>();
builder.Services.AddScoped<IAuthSessionPolicy, AuthSessionPolicy>();
builder.Services.AddScoped<IPasswordResetPolicy, PasswordResetPolicy>();
builder.Services.AddScoped<IEmailConfirmationPolicy, EmailConfirmationPolicy>();
builder.Services.AddScoped<IAccountEmailSender, ConfigurableAccountEmailSender>();
builder.Services.AddScoped<IRequestValidationService, RequestValidationService>();

builder.Services.AddScoped<IValidator<AuthRegisterDto>, AuthRegisterDtoValidator>();
builder.Services.AddScoped<IValidator<AuthLoginDto>, AuthLoginDtoValidator>();
builder.Services.AddScoped<IValidator<AuthConfirmEmailDto>, AuthConfirmEmailDtoValidator>();
builder.Services.AddScoped<IValidator<AuthResendEmailConfirmationDto>, AuthResendEmailConfirmationDtoValidator>();
builder.Services.AddScoped<IValidator<AuthForgotPasswordRequestDto>, AuthForgotPasswordRequestDtoValidator>();
builder.Services.AddScoped<IValidator<AuthResetPasswordDto>, AuthResetPasswordDtoValidator>();
builder.Services.AddScoped<IValidator<AuthRefreshDto>, AuthRefreshDtoValidator>();
builder.Services.AddScoped<IValidator<AuthLogoutDto>, AuthLogoutDtoValidator>();
builder.Services.AddScoped<IValidator<AuthGoogleSignInDto>, AuthGoogleSignInDtoValidator>();
builder.Services.AddScoped<IValidator<AuthYandexSignInDto>, AuthYandexSignInDtoValidator>();
builder.Services.AddScoped<IValidator<BloodPressureCreateDto>, BloodPressureCreateDtoValidator>();
builder.Services.AddScoped<IValidator<HealthMetricCreateDto>, HealthMetricCreateDtoValidator>();
builder.Services.AddScoped<IValidator<MedicalVisitCreateDto>, MedicalVisitCreateDtoValidator>();
builder.Services.AddScoped<IValidator<MedicationCreateDto>, MedicationCreateDtoValidator>();
builder.Services.AddScoped<IValidator<MedicationDailyStatusUpsertDto>, MedicationDailyStatusUpsertDtoValidator>();
builder.Services.AddScoped<IValidator<MetricRecordCreateDto>, MetricRecordCreateDtoValidator>();
builder.Services.AddScoped<IValidator<ProfileCreateDto>, ProfileCreateDtoValidator>();
builder.Services.AddScoped<IValidator<ProfilePageUpdateDto>, ProfilePageUpdateDtoValidator>();
builder.Services.AddScoped<IValidator<UserCreateDto>, UserCreateDtoValidator>();

var authOptions = builder.Configuration.GetSection(AuthOptions.SectionName).Get<AuthOptions>() ?? new AuthOptions();
if (string.IsNullOrWhiteSpace(authOptions.Jwt.SigningKey) || authOptions.Jwt.SigningKey.Length < 32)
{
    throw new InvalidOperationException("Auth:Jwt:SigningKey must be configured and contain at least 32 characters.");
}

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateIssuerSigningKey = true,
            ValidateLifetime = true,
            ValidIssuer = authOptions.Jwt.Issuer,
            ValidAudience = authOptions.Jwt.Audience,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(authOptions.Jwt.SigningKey)),
            ClockSkew = TimeSpan.FromMinutes(Math.Max(0, authOptions.Jwt.ClockSkewMinutes))
        };
    });
builder.Services.AddAuthorization();

builder.Services.AddAutoMapper(mc =>
{
    mc.AddProfile(typeof(BloodPressureMapper));
    mc.AddProfile(typeof(UserMapper));
    mc.AddProfile(typeof(MedicalVisitMapper));
    mc.AddProfile(typeof(MedicationMapper));
    mc.AddProfile(typeof(ProfileMapper));
    mc.AddProfile(typeof(MetricRecordMapper));
    mc.AddProfile(typeof(HealthMetricMapper));
});

builder.Services.AddScoped<IBloodPressureRepository, BloodPressureRepository>();
builder.Services.AddScoped<IAuthRepository, AuthRepository>();
builder.Services.AddScoped<IUserRepository, UserRepository>();
builder.Services.AddScoped<IMedicalVisitRepository, MedicalVisitRepository>();
builder.Services.AddScoped<IMedicationRepository, MedicationRepository>();
builder.Services.AddScoped<IProfileRepository, ProfileRepository>();
builder.Services.AddScoped<IHealthMetricRepository, HealthMetricRepository>();
builder.Services.AddScoped<IMetricRecordRepository, MetricRecordRepository>();

builder.Services.AddScoped<IBloodPressureService, BloodPressureService>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<IMedicalVisitService, MedicalVisitService>();
builder.Services.AddScoped<IMedicationService, MedicationService>();
builder.Services.AddScoped<IProfileService, ProfileService>();
builder.Services.AddScoped<IHealthMetricService, HealthMetricService>();
builder.Services.AddScoped<IMetricRecordService, MetricRecordService>();

builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "HealthApp API",
        Version = "v1"
    });

    options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Description = "Insert only the JWT access token. Swagger will add the Bearer prefix automatically."
    });

    options.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors(x => x.AllowAnyOrigin());
app.Use(async (context, next) =>
{
    try
    {
        await next();
    }
    catch (ValidationException validationException)
    {
        context.Response.StatusCode = StatusCodes.Status400BadRequest;
        context.Response.ContentType = "application/json";

        var errors = validationException.Errors
            .GroupBy(x => x.PropertyName)
            .ToDictionary(
                group => group.Key,
                group => group
                    .Select(x => x.ErrorMessage)
                    .Distinct(StringComparer.Ordinal)
                    .ToArray());

        var uiMessage = validationException.Errors
            .Select(x => x.ErrorMessage)
            .FirstOrDefault(x => !string.IsNullOrWhiteSpace(x))
            ?? ValidationMessages.RequestValidationFailed;

        await context.Response.WriteAsJsonAsync(new
        {
            message = ValidationMessages.RequestValidationFailed,
            uiMessage,
            errors
        });
    }
    catch (AuthException authException)
    {
        context.Response.StatusCode = (int)authException.StatusCode;
        context.Response.ContentType = "application/json";
        await context.Response.WriteAsJsonAsync(new { message = authException.Message });
    }
    catch (ApiException apiException)
    {
        context.Response.StatusCode = (int)apiException.StatusCode;
        context.Response.ContentType = "application/json";
        await context.Response.WriteAsJsonAsync(new { message = apiException.Message });
    }
});

app.UseHttpsRedirection();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();

public partial class Program
{
}
