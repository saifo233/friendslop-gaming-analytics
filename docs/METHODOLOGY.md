# Friendslop Games Analysis — Methodology

This document records the data sources, preparation steps, keyword rules, and limitations for the Friendslop Games Analysis project.

## Research questions

The analysis asks why the friendslop sub-genre took off between 2023 and 2026 and what distinguishes games with large audiences and live player counts.

Sub-questions:

1. Did games released from 2023 onward reach larger audiences than older social multiplayer games?
2. Which price points, sub-genres, and social features are associated with larger audiences and more engaged players?
3. Are “chaos” and “jank” terms in player reviews associated with review sentiment or estimated sales?

## Data sources and collection

Game-level data include release year, price, all-time peak concurrent players, lifetime Steam review counts, estimated owners, and estimated revenue.

- **Steam:** game title, release year, price, peak players, total reviews, positive reviews, and negative reviews.
- **Gamalytic:** estimated owners and revenue.
- **Player reviews:** 100 most recent reviews per game, exported using the third-party exporter at exportcomments.com.

All data were collected on **October 1, 2026**. Game-level figures were copied manually from Steam pages and Gamalytic profiles into a spreadsheet. Reviews were exported per game. No scraping scripts or APIs were used.

## Game selection

The sample contains 33 hand-picked multiplayer/co-op games centered on playing with friends that appear in community or press discussion of friendslop or are adjacent to the category. Older titles were included as a baseline for the 2023-and-later wave.

- Games: 33 (13 pre-2023; 20 released from 2023 onward)
- Sub-genres: Co-op Survival/Puzzle (9), Physics Sandbox (8), Extraction Horror (6), Simulation (6), Social Deduction (4)
- Key social features: Physics Sabotage (12), Proximity Chat (11), Task Coordination (7), Deception (3)
- Paid/free: 28/5

Categories such as sub-genre and key social feature were assigned manually.

## Data files

### `data/Friendslop_Data.csv` — one row per game

| Column | Meaning |
|---|---|
| `game_title` | Game name; used to join to the reviews table |
| `release_year` | Release year |
| `era` | `Pre-2023` or `2023+` |
| `sub_genre`, `key_social_feature` | Hand-assigned categories |
| `price_usd`, `price_type` | Steam price; `Free` when price is zero |
| `peak_players` | All-time peak concurrent players |
| `positive_reviews`, `negative_reviews`, `total_reviews`, `positive_pct` | Lifetime Steam review counts and positive share |
| `estimated_owners` | Gamalytic estimate |
| `owners_per_review` | `estimated_owners / total_reviews` |
| `estimated_revenue_usd` | Estimated revenue; see limitations below |

### `data/Friendslop_Reviews.csv` — one row per review

The file contains 3,300 rows (100 reviews per game).

| Column | Meaning |
|---|---|
| `review_id` | Unique review number |
| `game_title` | Joins to the game table |
| `review_type` | `Recommended` or `Not Recommended` |
| `review_text` | Original review text |
| `translated_text` | English translation using Google Sheets `GOOGLETRANSLATE`; unchanged for English reviews |
| `text_clean` | Translation with Steam markup removed; used for keyword matching |
| `is_usable`, `exclusion_reason` | Whether a review could be scored and, if not, why |
| `char_count`, `is_very_short` | Cleaned text length and flag for text of three characters or fewer |

## Cleaning and preparation

- Trimmed stray spaces and corrected title mismatches so the two tables join on `game_title` (33 of 33 game titles matched).
- Converted owner counts and years from text to numeric values.
- Checked and corrected swapped or mistyped owner and revenue values against the source; small errors may still remain.
- About half of the reviews were not in English. These were translated using Google Sheets `GOOGLETRANSLATE`; original text was retained alongside the translation.
- Removed Steam markup, including tags such as `[strike]` and emoticon codes, from translated text.
- Flagged 18 reviews with failed or missing translations as unusable.
- Flagged 239 reviews of three characters or fewer as very short and excluded them from scoring.
- Final scored set: **3,043 reviews**, or 82–100 reviews per game.

## Chaos Index and keyword matching

The SQL analysis lower-cases cleaned review text, replaces punctuation with spaces, and pads the text with spaces to support boundary-aware matching.

- Stems are matched from the start of a word (for example, `scream` can match `screamed` and `screaming`).
- Short words such as `lag` are matched as whole words.
- A review is flagged at most once per keyword bucket, even if it contains several keywords from that bucket.
- Each game's keyword rate is the share of scored reviews containing at least one keyword from the bucket.

| Bucket | Keywords |
|---|---|
| Chaos and fun | `scream`, `laugh`, `chao` (chaos/chaotic), `hilarious`, `funny`, `yell` |
| Jank and bugs | `jank`, `glitch`, `bug`, `broken`, `crash`, `lag`, `laggy`, `clunky` |
| Betrayal and sabotage | `betray`, `troll`, `sabotag`, `grief`, `kill`, `steal` |

Plain substring wildcards can create false positives in gaming text: `kill` can match “skill,” `troll` can match “strolling” or “controller,” and `mic` can match “dynamic.” In this dataset, `%kill%` matched 63 reviews compared with 38 using word-start matching.

The betrayal bucket is too sparse for strong analysis: it matched 57 reviews in total, about two-thirds due to the word `kill`. It is included for completeness only.

## Analysis choices and definitions

- Medians are used throughout because audience sizes and peak players are highly skewed; the top five games account for roughly half of estimated owners.
- Free games remain in analyses except revenue comparisons, because their revenue is not captured consistently by the data.
- Scatter plots use logarithmic scales because a few games have much larger audiences than the rest.
- **Peak intensity** is defined as all-time peak concurrent players divided by estimated owners. It approximates the share of estimated owners who were playing at the same time at the game's all-time peak; it is not a measure of unique active users.

## Limitations

1. **Small, hand-picked sample:** 33 games, with only 3–12 games in each sub-genre. The selection may over-represent well-known games and omit failures, so results should not be generalized to the whole market.
2. **Manual data entry:** copying figures by hand creates transcription risk. Values were checked against sources and some errors corrected, but small errors may remain.
3. **Estimated owners and revenue:** Gamalytic figures are model estimates and may be inaccurate. Revenue for free-to-play games is not comparable with paid games and is excluded from revenue comparisons.
4. **Recent reviews only:** the 100 most recent reviews per game reflect current sentiment, not sentiment at launch. The period covered varies by game.
5. **Machine translation:** automatically translated slang and gaming terminology can be mistranslated. Eighteen reviews with failed or missing translations were excluded from scoring.
6. **Simple keyword matching:** it does not reliably account for negation (for example, “not buggy”) or context. Most reviews contain no keyword from a given bucket.
7. **Sparse betrayal category:** only 57 reviews matched, with about two-thirds of matches from `kill`; interpret this category cautiously.
8. **Age and release-year effects:** older games have had longer to accumulate owners, and 2026 is a partial year.
9. **All-time peak metric:** peak players are all-time peaks, not launch peaks.
10. **Association, not causation:** the results do not establish cause and effect.

## Main interpretation

In this sample, bug-related terms appear more often in negative reviews than positive reviews, while chaos/fun terms are relatively uncommon in both. This suggests a hypothesis that technical issues may forgive some bugs that produce entertainment for a short while, but not if they stay and are game-breaking.
