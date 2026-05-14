using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Data.Migrations
{
    /// <inheritdoc />
    public partial class MedicationDailyStatuses : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "DayStatuses",
                table: "medications");

            migrationBuilder.CreateTable(
                name: "medication_daily_statuses",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    MedicationId = table.Column<Guid>(type: "uuid", nullable: false),
                    Date = table.Column<DateOnly>(type: "date", nullable: false),
                    Status = table.Column<int>(type: "integer", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    LastUpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_medication_daily_statuses", x => x.Id);
                    table.ForeignKey(
                        name: "FK_medication_daily_statuses_medications_MedicationId",
                        column: x => x.MedicationId,
                        principalTable: "medications",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_medication_daily_statuses_MedicationId_Date",
                table: "medication_daily_statuses",
                columns: new[] { "MedicationId", "Date" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "medication_daily_statuses");

            migrationBuilder.AddColumn<string>(
                name: "DayStatuses",
                table: "medications",
                type: "jsonb",
                nullable: false,
                defaultValue: "");
        }
    }
}
