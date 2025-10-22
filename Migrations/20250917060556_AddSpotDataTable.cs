using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace KiteMarketDataService.Worker.Migrations
{
    /// <inheritdoc />
    public partial class AddSpotDataTable : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "SpotData",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    IndexName = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    TradingDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    QuoteTimestamp = table.Column<DateTime>(type: "datetime2", nullable: false),
                    OpenPrice = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    HighPrice = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    LowPrice = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    ClosePrice = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    LastPrice = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    Volume = table.Column<long>(type: "bigint", nullable: false),
                    Change = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    ChangePercent = table.Column<decimal>(type: "decimal(5,2)", precision: 5, scale: 2, nullable: false),
                    CreatedDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    LastUpdated = table.Column<DateTime>(type: "datetime2", nullable: false),
                    DataSource = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    IsMarketOpen = table.Column<bool>(type: "bit", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SpotData", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_SpotData_IndexName",
                table: "SpotData",
                column: "IndexName");

            migrationBuilder.CreateIndex(
                name: "IX_SpotData_IndexName_TradingDate",
                table: "SpotData",
                columns: new[] { "IndexName", "TradingDate" });

            migrationBuilder.CreateIndex(
                name: "IX_SpotData_QuoteTimestamp",
                table: "SpotData",
                column: "QuoteTimestamp");

            migrationBuilder.CreateIndex(
                name: "IX_SpotData_TradingDate",
                table: "SpotData",
                column: "TradingDate");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "SpotData");
        }
    }
}
