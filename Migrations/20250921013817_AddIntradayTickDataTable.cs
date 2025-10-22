using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace KiteMarketDataService.Worker.Migrations
{
    /// <inheritdoc />
    public partial class AddIntradayTickDataTable : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "IntradayTickData",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    BusinessDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    TickTimestamp = table.Column<DateTime>(type: "datetime2", nullable: false),
                    TickTime = table.Column<TimeSpan>(type: "time", nullable: false),
                    InstrumentToken = table.Column<long>(type: "bigint", nullable: false),
                    TradingSymbol = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    IndexName = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    Strike = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    OptionType = table.Column<string>(type: "nvarchar(2)", maxLength: 2, nullable: false),
                    ExpiryDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    OpenPrice = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    HighPrice = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    LowPrice = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    ClosePrice = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    LastPrice = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    LowerCircuitLimit = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    UpperCircuitLimit = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    Volume = table.Column<long>(type: "bigint", nullable: false),
                    LastQuantity = table.Column<long>(type: "bigint", nullable: false),
                    BuyQuantity = table.Column<long>(type: "bigint", nullable: false),
                    SellQuantity = table.Column<long>(type: "bigint", nullable: false),
                    AveragePrice = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    OpenInterest = table.Column<decimal>(type: "decimal(15,2)", precision: 15, scale: 2, nullable: false),
                    OiDayHigh = table.Column<decimal>(type: "decimal(15,2)", precision: 15, scale: 2, nullable: false),
                    OiDayLow = table.Column<decimal>(type: "decimal(15,2)", precision: 15, scale: 2, nullable: false),
                    NetChange = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    SpotPrice = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    Delta = table.Column<decimal>(type: "decimal(10,6)", precision: 10, scale: 6, nullable: false),
                    Gamma = table.Column<decimal>(type: "decimal(10,8)", precision: 10, scale: 8, nullable: false),
                    Theta = table.Column<decimal>(type: "decimal(10,6)", precision: 10, scale: 6, nullable: false),
                    Vega = table.Column<decimal>(type: "decimal(10,6)", precision: 10, scale: 6, nullable: false),
                    Rho = table.Column<decimal>(type: "decimal(10,6)", precision: 10, scale: 6, nullable: false),
                    ImpliedVolatility = table.Column<decimal>(type: "decimal(8,2)", precision: 8, scale: 2, nullable: false),
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
                    HasValidData = table.Column<bool>(type: "bit", nullable: false),
                    IsMarketOpen = table.Column<bool>(type: "bit", nullable: false),
                    DataSource = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_IntradayTickData", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_IntradayTickData_BusinessDate",
                table: "IntradayTickData",
                column: "BusinessDate");

            migrationBuilder.CreateIndex(
                name: "IX_IntradayTickData_BusinessDate_IndexName_StrikeType",
                table: "IntradayTickData",
                columns: new[] { "BusinessDate", "IndexName", "StrikeType" });

            migrationBuilder.CreateIndex(
                name: "IX_IntradayTickData_BusinessDate_TickTimestamp_IndexName",
                table: "IntradayTickData",
                columns: new[] { "BusinessDate", "TickTimestamp", "IndexName" });

            migrationBuilder.CreateIndex(
                name: "IX_IntradayTickData_ExpiryDate",
                table: "IntradayTickData",
                column: "ExpiryDate");

            migrationBuilder.CreateIndex(
                name: "IX_IntradayTickData_IndexName",
                table: "IntradayTickData",
                column: "IndexName");

            migrationBuilder.CreateIndex(
                name: "IX_IntradayTickData_IndexName_ExpiryDate_Strike_OptionType_TickTimestamp",
                table: "IntradayTickData",
                columns: new[] { "IndexName", "ExpiryDate", "Strike", "OptionType", "TickTimestamp" });

            migrationBuilder.CreateIndex(
                name: "IX_IntradayTickData_InstrumentToken",
                table: "IntradayTickData",
                column: "InstrumentToken");

            migrationBuilder.CreateIndex(
                name: "IX_IntradayTickData_InstrumentToken_TickTimestamp",
                table: "IntradayTickData",
                columns: new[] { "InstrumentToken", "TickTimestamp" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_IntradayTickData_IsMarketOpen",
                table: "IntradayTickData",
                column: "IsMarketOpen");

            migrationBuilder.CreateIndex(
                name: "IX_IntradayTickData_OptionType",
                table: "IntradayTickData",
                column: "OptionType");

            migrationBuilder.CreateIndex(
                name: "IX_IntradayTickData_Strike",
                table: "IntradayTickData",
                column: "Strike");

            migrationBuilder.CreateIndex(
                name: "IX_IntradayTickData_StrikeType",
                table: "IntradayTickData",
                column: "StrikeType");

            migrationBuilder.CreateIndex(
                name: "IX_IntradayTickData_TickTime",
                table: "IntradayTickData",
                column: "TickTime");

            migrationBuilder.CreateIndex(
                name: "IX_IntradayTickData_TickTimestamp",
                table: "IntradayTickData",
                column: "TickTimestamp");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "IntradayTickData");
        }
    }
}
