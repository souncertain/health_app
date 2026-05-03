using Data;
using Data.Interfaces;
using Data.Repositpries;
using Microsoft.EntityFrameworkCore;
using Services;
using Services.Interfaces;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

builder.Services.AddControllers();
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();

builder.Configuration.AddJsonFile("appsettings.json");
string connection = builder.Configuration.GetConnectionString("EFPostgres")!;
builder.Services.AddDbContext<HealthAppDbContext>(options => options.UseNpgsql(connection));

builder.Services.AddScoped<IBloodPressureRepository, BloodPressureRepository>();
builder.Services.AddScoped<IBloodPressureService, BloodPressureService>();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.UseAuthorization();

app.MapControllers();

app.Run();
