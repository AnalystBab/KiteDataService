using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace KiteMarketDataService.Worker.Migrations
{
    /// <inheritdoc />
    public partial class AddFullInstrumentsTable : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "FullInstruments",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    InstrumentToken = table.Column<long>(type: "bigint", nullable: false),
                    ExchangeToken = table.Column<long>(type: "bigint", nullable: false),
                    TradingSymbol = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Name = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: true),
                    LastPrice = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    Expiry = table.Column<DateTime>(type: "datetime2", nullable: true),
                    Strike = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    TickSize = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    LotSize = table.Column<int>(type: "int", nullable: false),
                    InstrumentType = table.Column<string>(type: "nvarchar(10)", maxLength: 10, nullable: true),
                    Segment = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    Exchange = table.Column<string>(type: "nvarchar(10)", maxLength: 10, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    IsIndex = table.Column<bool>(type: "bit", nullable: false),
                    IndexName = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_FullInstruments", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_FullInstruments_Exchange",
                table: "FullInstruments",
                column: "Exchange");

            migrationBuilder.CreateIndex(
                name: "IX_FullInstruments_IndexName",
                table: "FullInstruments",
                column: "IndexName");

            migrationBuilder.CreateIndex(
                name: "IX_FullInstruments_InstrumentType",
                table: "FullInstruments",
                column: "InstrumentType");

            migrationBuilder.CreateIndex(
                name: "IX_FullInstruments_IsIndex",
                table: "FullInstruments",
                column: "IsIndex");

            migrationBuilder.CreateIndex(
                name: "IX_FullInstruments_IsIndex_IndexName",
                table: "FullInstruments",
                columns: new[] { "IsIndex", "IndexName" });

            migrationBuilder.CreateIndex(
                name: "IX_FullInstruments_TradingSymbol",
                table: "FullInstruments",
                column: "TradingSymbol");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "FullInstruments");
        }
    }
}
