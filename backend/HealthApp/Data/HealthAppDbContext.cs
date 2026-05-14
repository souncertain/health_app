using Domain.Entity;
using Microsoft.EntityFrameworkCore;

namespace Data
{
    public class HealthAppDbContext : DbContext
    {
        public HealthAppDbContext(DbContextOptions<HealthAppDbContext> options)
            : base(options)
        {
        }

        public DbSet<BloodPressure> BloodPressures { get; set; } = null!;
        public DbSet<HealthMetric> HealthMetrics { get; set; } = null!;
        public DbSet<MedicalVisit> MedicalVisits { get; set; } = null!;
        public DbSet<Medication> Medications { get; set; } = null!;
        public DbSet<MedicationDailyStatus> MedicationDailyStatuses { get; set; } = null!;
        public DbSet<MetricRecord> MetricRecords { get; set; } = null!;
        public DbSet<Profile> Profiles { get; set; } = null!;
        public DbSet<User> Users { get; set; } = null!;

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            modelBuilder.Entity<Medication>()
                .Property(x => x.TimesInMinutes)
                .HasColumnType("integer[]");

            modelBuilder.Entity<Medication>()
                .Property(x => x.ScheduledWeekdays)
                .HasColumnType("integer[]");

            modelBuilder.Entity<MedicationDailyStatus>()
                .Property(x => x.Date)
                .HasColumnType("date");

            modelBuilder.Entity<MedicationDailyStatus>()
                .HasIndex(x => new { x.MedicationId, x.Date })
                .IsUnique();
        }

        protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        {
        }
    }
}
