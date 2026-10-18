# Friendslop Games Analysis — Reproduction Guide

This guide describes how to reproduce the SQL analysis and connect the resulting data to Power BI.

## Requirements

- SQL Server Management Studio (SSMS)
- Power BI Desktop
- The project CSV files and SQL script

## 1. Import the CSV files into SQL Server

In SSMS, use **Tasks → Import Flat File** to import:

- `data/Friendslop_Data.csv` as `dbo.Friendslop_Data`
- `data/Friendslop_Reviews.csv` as `dbo.Friendslop_Reviews`

During import:

- Set `review_text`, `translated_text`, and `text_clean` to `nvarchar(MAX)`.
- Allow nulls in text columns where needed.
- Confirm the `is_usable` and `is_very_short` flags are imported as `bit`.

Review the inferred data types before finishing the import wizard.

## 2. Run the SQL script

Open `sql/Friendslop_ChaosIndex.sql` in SSMS and run it section by section.

Run sections in order and check the output of the validation queries before continuing.

## 3. Connect Power BI Desktop

In Power BI Desktop:

1. Connect to the SQL Server database used in the previous steps.
2. Load `vw_GameAnalysis` and `ReviewBucketHits`.
3. Create or verify the relationship between the tables on `game_title` as a one-to-many relationship.
4. Open the provided `dashboard/Friendslop_Dashboard.pbix` to inspect the report layout and visuals.

The report contains three pages: Market & Financial Overview, Player Acquisition & Virality, and Sentiment & Product Quality. Era and sub-genre slicers are synchronized across pages.


