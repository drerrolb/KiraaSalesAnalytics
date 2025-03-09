//
//  Datcode.metal
//  kiraa-sales-analytics
//
//  Created by Errol Brandt on 27/2/2025.
//


#include <metal_stdlib>
using namespace metal;

// -----------------------------------------------------------------------------
// Helper: Compute Calendar Flags
// Updated to handle "year == procYear ± 2" at indices 3..4.
// Layout (32 bits total):
//   0:  this cal year
//   1:  last cal year
//   2:  next cal year
//   3:  prior-prior cal year (year == procYear - 2)
//   4:  subsequent-subs cal year (year == procYear + 2)
//   5..16:  Calendar months (12 bits)
//   17..28: Calendar YTD (12 bits)
//   29..31: Rolling R03, R06, R12
// -----------------------------------------------------------------------------
void computeCalendarFlags(uint year, uint month,
                          uint procYear, uint procMonth,
                          thread char *binary)
{
    // (0..4) Calendar Year Flags
    binary[0] = (year == procYear)       ? '1' : '0';  // this cal year
    binary[1] = (year == procYear - 1)   ? '1' : '0';  // last cal year
    binary[2] = (year == procYear + 1)   ? '1' : '0';  // next cal year
    binary[3] = (year == procYear - 2)   ? '1' : '0';  // prior-prior cal year
    binary[4] = (year == procYear + 2)   ? '1' : '0';  // subsequent-subs cal year

    // (5..16) Calendar Specific Month Flags (12 bits)
    // For i in [1..12], set index = 4 + i => 5..16
    for (uint i = 1; i <= 12; i++) {
        binary[4 + i] = (month == i) ? '1' : '0';
    }

    // (17..28) Calendar YTD (12 bits)
    // For i in [1..12], set index = 16 + i => 17..28
    for (uint i = 1; i <= 12; i++) {
        binary[16 + i] = (i <= month) ? '1' : '0';
    }

    // Compute total months for rolling checks
    int procTotal  = int(procYear) * 12 + int(procMonth);
    int inputTotal = int(year)    * 12 + int(month);
    int diff       = procTotal - inputTotal;

    // (29..31) Calendar Rolling Flags
    binary[29] = (diff >= 0 && diff <  3) ? '1' : '0';  // R03
    binary[30] = (diff >= 0 && diff <  6) ? '1' : '0';  // R06
    binary[31] = (diff >= 0 && diff < 12) ? '1' : '0';  // R12
}

// -----------------------------------------------------------------------------
// Helper: Compute Financial Flags
// Updated to handle "finYear == procYear ± 2" at indices 35..36.
// Layout (32 bits total):
//   32: this fin year
//   33: last fin year
//   34: next fin year
//   35: prior-prior fin year (finYear == procYear - 2)
//   36: subsequent-subs fin year (finYear == procYear + 2)
//   37..48: Financial Period Flags (12 bits)
//   49..60: Financial YTD (12 bits)
//   61..63: Financial Rolling Flags
// -----------------------------------------------------------------------------
void computeFinancialFlags(uint year, uint month, uint finOffset,
                           uint procYear, uint procMonth,
                           thread char *binary)
{
    // 1) Compute the "input" financial parameters for this transaction's date
    uint inputAdjustedMonth = month + finOffset;
    uint inputAdditionalYears = (inputAdjustedMonth - 1) / 12;
    uint inputFinancialYear = year + inputAdditionalYears;
    uint inputFinancialPeriod = ((inputAdjustedMonth - 1) % 12) + 1;

    // (32..36) Financial Year Flags (5 bits)
    binary[32] = (inputFinancialYear == procYear)       ? '1' : '0';  // this fin year
    binary[33] = (inputFinancialYear == procYear - 1)   ? '1' : '0';  // last fin year
    binary[34] = (inputFinancialYear == procYear + 1)   ? '1' : '0';  // next fin year
    binary[35] = (inputFinancialYear == procYear - 2)   ? '1' : '0';  // prior-prior fin year
    binary[36] = (inputFinancialYear == procYear + 2)   ? '1' : '0';  // subsequent-subs fin year

    // (37..48) Financial Period Flags (12 bits)
    // For i in [1..12], set index = 36 + i => 37..48
    for (uint i = 1; i <= 12; i++) {
        binary[36 + i] = (inputFinancialPeriod == i) ? '1' : '0';
    }

    // (49..60) Financial YTD (12 bits)
    // For i in [1..12], set index = 48 + i => 49..60
    for (uint i = 1; i <= 12; i++) {
        binary[48 + i] = (i <= inputFinancialPeriod) ? '1' : '0';
    }

    // 2) Compute "processing" date’s financial parameters
    uint procAdjustedMonth = procMonth + finOffset;
    uint procAdditionalYears = (procAdjustedMonth - 1) / 12;
    uint procFinancialYear   = procYear + procAdditionalYears;
    uint procFinancialPeriod = ((procAdjustedMonth - 1) % 12) + 1;

    // 3) Rolling logic
    int procFinTotal  = int(procFinancialYear)  * 12 + int(procFinancialPeriod);
    int inputFinTotal = int(inputFinancialYear) * 12 + int(inputFinancialPeriod);
    int diffFin       = procFinTotal - inputFinTotal;

    // (61..63) Financial Rolling Flags
    binary[61] = (diffFin >= 0 && diffFin <  3) ? '1' : '0'; // R03
    binary[62] = (diffFin >= 0 && diffFin <  6) ? '1' : '0'; // R06
    binary[63] = (diffFin >= 0 && diffFin < 12) ? '1' : '0'; // R12
}

// -----------------------------------------------------------------------------
// Kernel: processDateCode
// Expanded to produce 65 chars total: 64 bits + 1 null terminator
// -----------------------------------------------------------------------------
kernel void processDateCode(
    device const uint *dateCodes               [[buffer(0)]], // Input: Array of date codes (YYYYMMDD)
    device       char *binaryStrings           [[buffer(1)]], // Output: Array of binary strings (flags)
    device const uint *processDate             [[buffer(2)]], // Input: Processing Date (YYYYMMDD)
    device const uint *financialOffset         [[buffer(3)]], // Input: Financial Offset (months)
    device       uint *calendarProcessingDate  [[buffer(4)]], // Output: Calendar Processing Date (YYYYMMDD)
    device       uint *financialProcessingDate [[buffer(5)]], // Output: Financial Processing Date (YYYYMMDD)
    uint id [[thread_position_in_grid]])
{
    // 1) Parse the main inputs
    uint date = dateCodes[id];
    uint procDate = *processDate;
    uint finOffset = *financialOffset;

    // 2) Decompose the processing date
    uint procYear  = procDate / 10000;
    uint procMonth = (procDate / 100) % 100;
    uint procDay   =  procDate % 100;

    // 3) Compute the “financial processing date” (with offset)
    uint adjustedMonth   = procMonth + finOffset;
    uint additionalYears = (adjustedMonth - 1) / 12;
    uint finYear         = procYear + additionalYears;
    uint finMonth        = ((adjustedMonth - 1) % 12) + 1;
    uint finDate         = (finYear * 10000) + (finMonth * 100) + procDay;

    // Save to output buffers
    *calendarProcessingDate  = procDate;
    *financialProcessingDate = finDate;

    // 4) Decompose the transaction date (YYYYMMDD)
    uint year  = date / 10000;
    uint month = (date / 100) % 100;
    uint day   =  date % 100;

    // 5) Prepare a 65-char array: 64 bits + null terminator
    thread char binary[65];

    // Initialize to '0'
    for (uint i = 0; i < 65; i++) {
        binary[i] = '0';
    }

    // 6) Populate the Calendar (indices 0..31)
    computeCalendarFlags(year, month, procYear, procMonth, binary);

    // 7) Populate the Financial (indices 32..63)
    computeFinancialFlags(year, month, finOffset, procYear, procMonth, binary);

    // 8) Null-terminate at index 64
    binary[64] = '\0';

    // 9) Copy to the output buffer for this thread
    for (uint i = 0; i < 65; i++) {
        binaryStrings[id * 65 + i] = binary[i];
    }
}
