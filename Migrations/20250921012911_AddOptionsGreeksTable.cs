using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace KiteMarketDataService.Worker.Migrations
{
    /// <inheritdoc />
    public partial class AddOptionsGreeksTable : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "OptionsGreeks",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    BusinessDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    QuoteTimestamp = table.Column<DateTime>(type: "datetime2", nullable: false),
                    CalculationTime = table.Column<DateTime>(type: "datetime2", nullable: false),
                    InstrumentToken = table.Column<long>(type: "bigint", nullable: false),
                    TradingSymbol = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    IndexName = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    Strike = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    OptionType = table.Column<string>(type: "nvarchar(2)", maxLength: 2, nullable: false),
                    ExpiryDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    SpotPrice = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    LastPrice = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    LowerCircuitLimit = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    UpperCircuitLimit = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    OpenInterest = table.Column<decimal>(type: "decimal(15,2)", precision: 15, scale: 2, nullable: false),
                    Volume = table.Column<long>(type: "bigint", nullable: false),
                    RiskFreeRate = table.Column<decimal>(type: "decimal(5,2)", precision: 5, scale: 2, nullable: false),
                    DividendYield = table.Column<decimal>(type: "decimal(5,2)", precision: 5, scale: 2, nullable: false),
                    TimeToExpiry = table.Column<decimal>(type: "decimal(10,6)", precision: 10, scale: 6, nullable: false),
                    ImpliedVolatility = table.Column<decimal>(type: "decimal(8,2)", precision: 8, scale: 2, nullable: false),
                    Delta = table.Column<decimal>(type: "decimal(10,6)", precision: 10, scale: 6, nullable: false),
                    Gamma = table.Column<decimal>(type: "decimal(10,8)", precision: 10, scale: 8, nullable: false),
                    Theta = table.Column<decimal>(type: "decimal(10,6)", precision: 10, scale: 6, nullable: false),
                    Vega = table.Column<decimal>(type: "decimal(10,6)", precision: 10, scale: 6, nullable: false),
                    Rho = table.Column<decimal>(type: "decimal(10,6)", precision: 10, scale: 6, nullable: false),
                    TheoreticalPrice = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    PriceDeviation = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    PriceDeviationPercent = table.Column<decimal>(type: "decimal(8,2)", precision: 8, scale: 2, nullable: false),
                    Moneyness = table.Column<decimal>(type: "decimal(10,4)", precision: 10, scale: 4, nullable: false),
                    StrikeType = table.Column<string>(type: "nvarchar(10)", maxLength: 10, nullable: false),
                    IntrinsicValue = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    TimeValue = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    PredictedLow = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    PredictedHigh = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    ConfidenceScore = table.Column<decimal>(type: "decimal(5,2)", precision: 5, scale: 2, nullable: false),
                    HistoricalVolatility = table.Column<decimal>(type: "decimal(8,2)", precision: 8, scale: 2, nullable: false),
                    VolatilitySkew = table.Column<decimal>(type: "decimal(8,2)", precision: 8, scale: 2, nullable: false),
                    VolatilityRank = table.Column<decimal>(type: "decimal(5,2)", precision: 5, scale: 2, nullable: false),
                    MaximumLoss = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    MaximumGain = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    BreakEvenPoint = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    PutCallRatio = table.Column<decimal>(type: "decimal(10,4)", precision: 10, scale: 4, nullable: false),
                    VolumeRatio = table.Column<decimal>(type: "decimal(10,4)", precision: 10, scale: 4, nullable: false),
                    MarketSentiment = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    IsActive = table.Column<bool>(type: "bit", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_OptionsGreeks", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_OptionsGreeks_BusinessDate",
                table: "OptionsGreeks",
                column: "BusinessDate");

            migrationBuilder.CreateIndex(
                name: "IX_OptionsGreeks_BusinessDate_IndexName",
                table: "OptionsGreeks",
                columns: new[] { "BusinessDate", "IndexName" });

            migrationBuilder.CreateIndex(
                name: "IX_OptionsGreeks_CalculationTime",
                table: "OptionsGreeks",
                column: "CalculationTime");

            migrationBuilder.CreateIndex(
                name: "IX_OptionsGreeks_ExpiryDate",
                table: "OptionsGreeks",
                column: "ExpiryDate");

            migrationBuilder.CreateIndex(
                name: "IX_OptionsGreeks_IndexName",
                table: "OptionsGreeks",
                column: "IndexName");

            migrationBuilder.CreateIndex(
                name: "IX_OptionsGreeks_IndexName_ExpiryDate_Strike_OptionType",
                table: "OptionsGreeks",
                columns: new[] { "IndexName", "ExpiryDate", "Strike", "OptionType" });

            migrationBuilder.CreateIndex(
                name: "IX_OptionsGreeks_InstrumentToken",
                table: "OptionsGreeks",
                column: "InstrumentToken");

            migrationBuilder.CreateIndex(
                name: "IX_OptionsGreeks_OptionType",
                table: "OptionsGreeks",
                column: "OptionType");

            migrationBuilder.CreateIndex(
                name: "IX_OptionsGreeks_QuoteTimestamp",
                table: "OptionsGreeks",
                column: "QuoteTimestamp");

            migrationBuilder.CreateIndex(
                name: "IX_OptionsGreeks_QuoteTimestamp_InstrumentToken",
                table: "OptionsGreeks",
                columns: new[] { "QuoteTimestamp", "InstrumentToken" });

            migrationBuilder.CreateIndex(
                name: "IX_OptionsGreeks_Strike",
                table: "OptionsGreeks",
                column: "Strike");

            migrationBuilder.CreateIndex(
                name: "IX_OptionsGreeks_StrikeType",
                table: "OptionsGreeks",
                column: "StrikeType");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "OptionsGreeks");
        }
    }
}
