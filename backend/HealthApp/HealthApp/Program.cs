using Data;
using Data.Interfaces;
using Data.Repositories;
using Domain.Exceptions;
using HealthApp.Configuration;
using HealthApp.Infrastructure;
using HealthApp.Infrastructure.Auth;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Services.Interfaces;
using Services.Mappers;
using Services.Services;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

builder.Services.AddControllers();
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();

builder.Configuration.AddJsonFile("appsettings.json");
string connection = builder.Configuration.GetConnectionString("EFPostgres")!;
builder.Services.Configure<AuthOptions>(builder.Configuration.GetSection(AuthOptions.SectionName));
builder.Services.AddDbContext<HealthAppDbContext>(options => options.UseNpgsql(connection));
builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<ICurrentUserContext, HttpCurrentUserContext>();
builder.Services.AddHttpClient<IYandexIdentityProviderClient, YandexIdentityProviderClient>();
builder.Services.AddScoped<IGoogleIdentityTokenValidator, GoogleIdentityTokenValidator>();
builder.Services.AddScoped<IJwtTokenFactory, JwtTokenFactory>();
builder.Services.AddScoped<IPasswordHashService, PasswordHashService>();
builder.Services.AddScoped<IRefreshTokenFactory, RefreshTokenFactory>();
builder.Services.AddScoped<IAuthSessionPolicy, AuthSessionPolicy>();

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

builder.Services.AddSwaggerGen();

var app = builder.Build();

// Configure the HTTP request pipeline.
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
    catch (AuthException authException)
    {
        context.Response.StatusCode = (int)authException.StatusCode;
        context.Response.ContentType = "application/json";
        await context.Response.WriteAsJsonAsync(new { message = authException.Message });
    }
});

app.UseHttpsRedirection();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();
