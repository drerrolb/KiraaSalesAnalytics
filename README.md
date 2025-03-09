# KiraaSalesAnalytics

Below is the updated documentation incorporating the new command‑line parameters.

Sales Analytics Integration

Welcome to Sales Analytics Integration
A powerful Swift‑based tool designed to process and analyze large sales datasets quickly and efficiently.

Overview

Sales Analytics Integration is a command‑line tool written in Swift. It loads CSV data into a DataFrame, processes the data in manageable chunks, and performs detailed analytics. The project is built with a focus on clear user feedback and visually appealing output.

The tool features:
    •    CSV Data Loading: Robust handling of CSV files, ensuring data is loaded correctly.
    •    Chunk Processing: Breaks down large datasets into chunks for parallel processing.
    •    User-Friendly Output: Includes custom text art and clear, formatted progress messages.
    •    Detailed Logging: Integrated logging with real‑time feedback on operations.
    •    Configurable Parameters: Easily modify settings such as the source file path, execution date, fiscal offset, and model.

Features

Custom Branding

Upon launch, the tool displays a unique text art logo:

░██████╗░█████╗░░█████╗░░░███╗░░
██╔════╝██╔══██╗██╔══██╗░████║░░
╚█████╗░███████║██║░░██║██╔██║░░
░╚═══██╗██╔══██║██║░░██║╚═╝██║░░
██████╔╝██║░░██║╚█████╔╝███████╗
╚═════╝░╚═╝░░╚═╝░╚════╝░╚══════╝

Progress Feedback

The app provides clear step‑by‑step output, including file validation, CSV load progress, and analytics execution details (e.g., timestamps, parameters, processing status).

Detailed Execution Report

At the end of processing, a final boxed message displays the execution result, including execution time, status, and messages.

Field Mapping & Analytics

Configurable mappings are used to interpret sales data fields for comprehensive analysis.

Installation
    1.    Clone the repository:

git clone https://github.com/Knowledge-Orchestrator/kiraa-sales-analytics/
cd sales-analytics-integration


    2.    Open the Project in Xcode:
Open the project using Xcode and build the target.
    3.    Prepare the Data:
Place your source CSV file (source-sales.csv) in the designated folder (e.g., /Users/e2mq173/Projects/KO-source/SA01/upload/)
Or let the tool automatically use source-sales.csv from your Documents directory.

Usage

After building the project, run the command‑line tool. The process flow is as follows:
    1.    Startup:
Displays a welcome message along with the text art logo.
    2.    File Validation:
Confirms the existence of the CSV file and prints its details (e.g., file location, creation date, file size).
    3.    Parameter Configuration:
Outputs the execution parameters (source file, instance, integration, execution date, calendar year/month, fiscal offset) in a friendly format.
    4.    CSV Loading & Analytics:
Loads the CSV into a DataFrame, processes the data in chunks, and provides progress feedback with timestamps.
    5.    Final Report:
Once processing is complete, a final boxed message summarizes the execution results.

Command‑Line Parameters

This tool accepts the following named parameters:
    •    --source
Description: Full path to the CSV source file.
Default: If omitted, defaults to source-sales.csv located in your Documents directory.
    •    --date
Description: The execution date in yyyy-MM-dd format.
Default: If omitted, today’s date is used.
    •    --offset
Description: Fiscal offset as an integer.
Default: 0 if not provided.
    •    --model
Description: Model identifier to use. Only SA01 is supported.
Default: SA01 if not provided.

Example Invocations
    1.    Default Parameters:
Uses all default values (i.e. source file from Documents, today’s date, an offset of 0, and model SA01):

swift run KiraaSalesAnalytics


    2.    Custom Parameters:
Specify a custom source file, date, fiscal offset, and model:

swift run KiraaSalesAnalytics --source "/Users/e2mq173/Documents/source-sales.csv" --date "2025-03-01" --offset 2 --model SA01


    3.    Display Help:

swift run KiraaSalesAnalytics --help



Example Output

Welcome to Sales Analytics!

░██████╗░█████╗░░█████╗░░░███╗░░
██╔════╝██╔══██╗██╔══██╗░████║░░
╚█████╗░███████║██║░░██║██╔██║░░
░╚═══██╗██╔══██║██║░░██║╚═╝██║░░
██████╔╝██║░░██║╚█████╔╝███████╗
╚═════╝░╚═╝░░╚═╝░╚════╝░╚══════╝

Step 1.0  
Validate that the CSV file is found in the specified location.  
> CSV file 'source-sales.csv' found at /path/to/your/source-sales.csv

Step 2.0  
Starting execution of Sales Analytics Integration with the following parameters:
  > Source File:   /path/to/your/source-sales.csv
  > Instance:      1
  > Integration:   1
  > Model:         SA01
  > Current Year:  2025
  > Current Month: 2
  > Fiscal Offset: 3

...

╔══════════════════════════════════════════════════════╗
║                                                      ║
║                  *** COMPLETE ***                    ║
║                                                      ║
║  Execution Message : Processing completed...       ║
║  Execution Time    : 00:01:00                         ║
║  Execution Status  : Success                        ║
║                                                      ║
╚══════════════════════════════════════════════════════╝

Code Structure
    •    KiraaSalesAnalytics.swift:
The main entry point that parses command‑line parameters, validates input, and dispatches the integration based on the provided model.
    •    SA01Integration.swift:
Contains the logic for the SA01 integration module including CSV file validation, parameter output, and executing the analytics.
    •    SA01Execute.swift:
Implements the core processing logic for CSV loading, data chunking, and analytics execution.
    •    BoxedHelper.swift:
Houses helper functions for printing formatted, boxed messages and user feedback.
    •    SA01FieldMapping.swift:
Defines field mapping and metadata structures essential for interpreting the sales data.
    •    LoggerManager:
Integrated logging framework to capture detailed runtime information.

This documentation provides a comprehensive overview of the Sales Analytics Integration tool, including its configurable parameters, installation instructions, and usage examples. Use the provided command‑line parameters to tailor the integration to your specific needs.
