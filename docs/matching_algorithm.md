# SAME SAME - Matching Algorithm

## Overview

The SAME SAME matching algorithm calculates similarity between users based on their interest evaluations. The algorithm uses weighted scoring to account for interest popularity and provides both category-level and overall match scores.

## Core Concepts

### Interest Weighting

Each interest is assigned a weight based on its popularity:

```
weight = 1 / sqrt(popularity)
```

**Rationale:**
- Less popular interests are more meaningful indicators of similarity
- Popular interests (high popularity) get lower weights
- Rare interests (low popularity) get higher weights
- Square root prevents extreme weighting differences

**Example:**
- Interest with popularity = 100 → weight = 0.1
- Interest with popularity = 1 → weight = 1.0
- Interest with popularity = 0.25 → weight = 2.0

### Interest Evaluation Scoring

For each overlapping interest between two users:

| User A | User B | Score Contribution |
|--------|--------|-------------------|
| Like (+1) | Like (+1) | +2 × weight |
| Dislike (-1) | Dislike (-1) | +2 × weight |
| Like (+1) | Dislike (-1) | -2 × weight |
| Dislike (-1) | Like (+1) | -2 × weight |

**Rationale:**
- Agreement (both like or both dislike) indicates similarity → positive score
- Conflict (opposite evaluations) indicates difference → negative score
- The 2× multiplier ensures balanced scoring

## Category-Level Matching

### Step 1: Calculate Category Score

For each category (e.g., "music", "movies", "books"):

```
score_c = Σ(score_contribution × weight)
```

Where `score_contribution` is:
- `+2 × weight` for agreements
- `-2 × weight` for conflicts

### Step 2: Calculate Maximum Possible Score

```
max_score_c = Σ(2 × weight)
```

This represents the score if all overlapping interests were agreements.

### Step 3: Calculate Category Match

```
match_c = score_c / max_score_c
```

**Result:**
- `match_c` ranges from -1 to +1
- `+1` = perfect agreement on all overlapping interests
- `0` = balanced agreements and conflicts
- `-1` = all conflicts (opposite evaluations)

**Note:** In practice, `match_c` is typically clamped to [0, 1] for display purposes, or negative values indicate strong disagreement.

## Overall Matching

### Base Match

The base match is the average of all category matches:

```
base_match = (Σ match_c) / number_of_categories
```

### Confidence

Confidence measures how much data we have to base the match on:

```
confidence = min(overlap_count / 20, 1)
```

**Rationale:**
- More overlapping interests = higher confidence
- Normalized to [0, 1] range
- 20 overlaps = full confidence (adjustable threshold)

### Final Match

The final match combines base match with confidence:

```
final_match = base_match × (0.5 + 0.5 × confidence)
```

**Formula Breakdown:**
- `0.5 + 0.5 × confidence` ranges from 0.5 to 1.0
- Low confidence (few overlaps) → final_match = base_match × 0.5
- High confidence (many overlaps) → final_match = base_match × 1.0

**Rationale:**
- Penalizes matches with low overlap (less data)
- Rewards matches with high overlap (more reliable)
- Ensures matches with few data points are scored conservatively

## Example Calculation

### Scenario

**User A's Interests:**
- Music: Rock (like), Jazz (like), Pop (dislike)
- Movies: Action (like), Horror (dislike)

**User B's Interests:**
- Music: Rock (like), Jazz (dislike), Pop (like)
- Movies: Action (like), Horror (dislike)

**Interest Popularities:**
- Rock: 50 → weight = 0.141
- Jazz: 10 → weight = 0.316
- Pop: 100 → weight = 0.100
- Action: 80 → weight = 0.112
- Horror: 30 → weight = 0.183

### Category: Music

**Overlaps:**
- Rock: Both like → +2 × 0.141 = +0.282
- Jazz: A likes, B dislikes → -2 × 0.316 = -0.632
- Pop: A dislikes, B likes → -2 × 0.100 = -0.200

**Scores:**
- `score_c = 0.282 - 0.632 - 0.200 = -0.550`
- `max_score_c = 2 × (0.141 + 0.316 + 0.100) = 1.114`
- `match_c = -0.550 / 1.114 = -0.494`

### Category: Movies

**Overlaps:**
- Action: Both like → +2 × 0.112 = +0.224
- Horror: Both dislike → +2 × 0.183 = +0.366

**Scores:**
- `score_c = 0.224 + 0.366 = 0.590`
- `max_score_c = 2 × (0.112 + 0.183) = 0.590`
- `match_c = 0.590 / 0.590 = 1.000`

### Overall

- `base_match = (-0.494 + 1.000) / 2 = 0.253`
- `overlap_count = 5`
- `confidence = min(5 / 20, 1) = 0.25`
- `final_match = 0.253 × (0.5 + 0.5 × 0.25) = 0.253 × 0.625 = 0.158`

## Implementation Notes

### Edge Function: `get_matches`

1. Load user's interests with popularity
2. Calculate weights for each interest
3. Load all other users' interests
4. For each other user:
   - Find overlapping interests
   - Group by category
   - Calculate `match_c` for each category
   - Calculate `base_match`, `confidence`, `final_match`
5. Apply preference filters (age, gender, min_match_percent)
6. Sort by `final_match` descending
7. Return top 50

### Edge Function: `get_match_details`

1. Load both users' interests
2. Find all overlapping interests
3. Group by category
4. For each category:
   - Calculate `match_c`
   - List `both_liked`, `both_disliked`, `conflicts`
   - Get affinity from `user_category_stats`
5. Calculate overall stats
6. Return full comparison

## Filtering

### User Preferences

Users can filter matches by:
- **Gender**: `preferred_genders` array
- **Age Range**: `age_min` to `age_max`
- **Distance**: `radius_km` (future: geospatial query)
- **Minimum Match**: `min_match_percent` (0-100)

### Application in `get_matches`

1. Load user preferences
2. Apply filters to profile query:
   - `WHERE gender IN (preferred_genders)`
   - `WHERE age BETWEEN age_min AND age_max`
3. After calculating `final_match`:
   - `WHERE final_match >= (min_match_percent / 100)`

## Performance Optimizations

1. **Pre-computed Stats**: `user_category_stats` table stores category-level aggregates
2. **Indexes**: Strategic indexes on foreign keys and search fields
3. **Batch Processing**: Process all matches in single query where possible
4. **Limit Results**: Top 50 matches prevents excessive computation
5. **Weighted Scoring**: Calculated once per interest, reused across users

## Future Enhancements

1. **Geospatial Matching**: Use PostGIS for distance-based filtering
2. **Temporal Weighting**: Recent ratings weighted higher
3. **Category Importance**: User-defined category weights
4. **Machine Learning**: Train model on successful matches
5. **A/B Testing**: Test different confidence formulas

