# Friendslop Games Analysis

**An end-to-end analysis of 33 social multiplayer games and 3,300 Steam player reviews using SQL Server and Power BI.**

This project investigates what distinguishes games in the informal “friendslop” category: inexpensive, chaotic multiplayer games built around playing with friends. I collected game-level data and recent player reviews, cleaned and analyzed them with SQL Server, and built an interactive Power BI dashboard.

**[Open the interactive dashboard](https://app.powerbi.com/view?r=eyJrIjoiMDU2YmEzZDgtOTU4Zi00MDk2LThlYjMtYTI5Nzc5Nzk1NzE2IiwidCI6IjBmZWQwM2EzLTQwMmQtNDYzMy1hOGNkLThiMzA4ODIyMjUzZSIsImMiOjEwfQ%3D%3D)** · [Dashboard PDF](dashboard/Friendslop_Dashboard.pdf) · [Power BI file](dashboard/Friendslop_Dashboard.pbix)

![Market and financial overview dashboard](screenshots/page1_market_overview.png)

## Business question

Why did the friendslop sub-genre take off between 2023 and 2026, and what separates games with large audiences and live player counts from the rest?

The analysis compares release eras, price bands, sub-genres, social features, and language used in positive and negative reviews.

## Key findings

These findings describe **the 33 selected games in this project**, not the entire market. They show associations, not cause and effect.

- **Newer games had higher peaks, but not larger estimated audiences.** Games released from 2023 onward had a median all-time peak of about 71K concurrent players, versus 21K for older games. Their median estimated owners were lower: 6.6M versus 8.5M.
- **A few hits account for most of the 2025 peak.** *Schedule I*, *R.E.P.O.*, and *PEAK* made up about 89% of the combined all-time peak concurrent players for the 2025 releases in the sample.
- **The $5–$9.99 band performed strongly among paid games in this sample.** It had the highest median peak player count (about 107K). This is an observed pattern in the selected games, not a universal pricing recommendation.
- **Bug-related language appeared more often in negative reviews.** Jank/bug keywords appeared in 13.3% of “Not Recommended” reviews and 2.3% of “Recommended” reviews. Chaos/fun keywords appeared in 5.4% of “Recommended” reviews and 2.9% of “Not Recommended” reviews.

The project uses a simple keyword-based **Chaos Index** to compare how often reviews mention chaos/fun, jank/bugs, and betrayal/sabotage. It is a transparent text-analysis approach, not a full sentiment or context-aware language model.

## Dashboard

The Power BI report has three pages:

1. **Market & Financial Overview** — price bands, release eras, peak players, estimated owners, and audience comparisons.
2. **Player Acquisition & Virality** — peak intensity by sub-genre, owners by social feature, and a ranked table of the 33 games.
3. **Sentiment & Product Quality** — keyword rates by review type and game, including bug mentions and review approval.

Use the [interactive dashboard](https://app.powerbi.com/view?r=eyJrIjoiMDU2YmEzZDgtOTU4Zi00MDk2LThlYjMtYTI5Nzc5Nzk1NzE2IiwidCI6IjBmZWQwM2EzLTQwMmQtNDYzMy1hOGNkLThiMzA4ODIyMjUzZSIsImMiOjEwfQ%3D%3D) to switch pages and use the era and sub-genre filters. Static previews are available here:

- [Page 1 — Market overview](screenshots/page1_market_overview.png)
- [Page 2 — Acquisition and virality](screenshots/page2_acquisition_virality.png)
- [Page 3 — Sentiment and quality](screenshots/page3_sentiment_quality.png)

## End-to-end workflow

1. **Collect:** manually compile game-level figures from Steam and Gamalytic; export the 100 most recent Steam reviews per game.
2. **Clean:** standardize game titles, convert numeric fields, translate non-English reviews with Google Sheets `GOOGLETRANSLATE`, remove Steam markup, and flag unusable or very short reviews.
3. **Analyze with SQL Server:** join game and review data, apply keyword matching with word-boundary safeguards, calculate keyword rates, and run comparison queries.
4. **Visualize with Power BI:** build a three-page dashboard connected to SQL Server, with synchronized era and sub-genre filters.

Data were collected on **October 1, 2026**. Of the 3,300 collected reviews, **3,043 were scored** after excluding 18 reviews with failed or missing translations and 239 reviews of three characters or fewer.

## Data and limitations

- **Sample:** 33 hand-picked games — 13 released before 2023 and 20 released from 2023 onward.
- **Sources:** Steam game pages and reviews; Gamalytic estimates for owners and revenue; reviews exported using a third-party Steam review exporter.
- **Estimates:** owner and revenue figures are model estimates and may be inaccurate.
- **Selection bias:** the games were hand-picked and may over-represent well-known titles; games that failed may be missing.
- **Review sample:** 100 most recent reviews per game reflect current sentiment, not necessarily launch sentiment. Review time windows vary by game.
- **Text analysis:** automatic translation can introduce errors, and keyword matching cannot reliably interpret context or negation.

See [the methodology and limitations](docs/METHODOLOGY.md) for more detail and [the reproduction guide](docs/REPRODUCING.md) for setup instructions.

## Repository structure

```text
friendslop-gaming-analytics/
├── README.md
├── LICENSE
├── data/
│   ├── Friendslop_Data.csv
│   ├── Friendslop_Reviews.csv
│   └── ChaosIndex_by_game.csv
├── sql/
│   └── Friendslop_ChaosIndex.sql
├── screenshots/
│   ├── page1_market_overview.png
│   ├── page2_acquisition_virality.png
│   └── page3_sentiment_quality.png
├── dashboard/
│   ├── Friendslop_Dashboard.pbix
│   └── Friendslop_Dashboard.pdf
└── docs/
    ├── METHODOLOGY.md
    └── REPRODUCING.md
```

## Tools

SQL Server (T-SQL, SSMS) · Power BI (DAX) · Google Sheets (`GOOGLETRANSLATE`) · Excel / CSV
