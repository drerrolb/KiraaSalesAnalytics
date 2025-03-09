//
//  ActualVolumeThisCalendarYear.swift
//  kiraa-sales-analytics
//
//  Created by Errol Brandt on 1/3/2025.
//

struct ActualVolumeThisCalendarYear {
    static let dictionary: [String: [String: String]] = [
    
        // Current calendar year values
        "volume_this_year_current_month_actual_volume": [
            "FieldType": "volume",
            "YearType": "thiscalyear",
            "TimePeriod": "currentcalendarmonth",
            "MeasureType": "actual"
        ],
        "volume_this_year_current_ytd_actual_volume": [
            "FieldType": "volume",
            "YearType": "thiscalyear",
            "TimePeriod": "currentcalendarytd",
            "MeasureType": "actual"
        ],
        "volume_this_year_current_fy_actual_volume": [
            "FieldType": "volume",
            "YearType": "thiscalyear",
            "TimePeriod": "currentcalendarfy", // Verify if this should be "currentcalendaryear"
            "MeasureType": "actual"
        ],
    
        // Periods (P01 - P12)
        "volume_this_year_january_month_actual_volume": [
            "FieldType": "volume",
            "YearType": "thiscalyear",
            "TimePeriod": "januarymonth",
            "MeasureType": "actual"
        ],
        "volume_this_year_february_month_actual_volume": [
            "FieldType": "volume",
            "YearType": "thiscalyear",
            "TimePeriod": "februarymonth",
            "MeasureType": "actual"
        ],
        "volume_this_year_march_month_actual_volume": [
            "FieldType": "volume",
            "YearType": "thiscalyear",
            "TimePeriod": "marchmonth",
            "MeasureType": "actual"
        ],
        "volume_this_year_april_month_actual_volume": [
            "FieldType": "volume",
            "YearType": "thiscalyear",
            "TimePeriod": "aprilmonth",
            "MeasureType": "actual"
        ],
        "volume_this_year_may_month_actual_volume": [
            "FieldType": "volume",
            "YearType": "thiscalyear",
            "TimePeriod": "maymonth",
            "MeasureType": "actual"
        ],
        "volume_this_year_june_month_actual_volume": [
            "FieldType": "volume",
            "YearType": "thiscalyear",
            "TimePeriod": "junemonth",
            "MeasureType": "actual"
        ],
        "volume_this_year_july_month_actual_volume": [
            "FieldType": "volume",
            "YearType": "thiscalyear",
            "TimePeriod": "julymonth",
            "MeasureType": "actual"
        ],
        "volume_this_year_august_month_actual_volume": [
            "FieldType": "volume",
            "YearType": "thiscalyear",
            "TimePeriod": "augustmonth",
            "MeasureType": "actual"
        ],
        "volume_this_year_september_month_actual_volume": [
            "FieldType": "volume",
            "YearType": "thiscalyear",
            "TimePeriod": "septembermonth",
            "MeasureType": "actual"
        ],
        "volume_this_year_october_month_actual_volume": [
            "FieldType": "volume",
            "YearType": "thiscalyear",
            "TimePeriod": "octobermonth",
            "MeasureType": "actual"
        ],
        "volume_this_year_november_month_actual_volume": [
            "FieldType": "volume",
            "YearType": "thiscalyear",
            "TimePeriod": "novembermonth",
            "MeasureType": "actual"
        ],
        "volume_this_year_december_month_actual_volume": [
            "FieldType": "volume",
            "YearType": "thiscalyear",
            "TimePeriod": "decembermonth",
            "MeasureType": "actual"
        ]
    ]
}
