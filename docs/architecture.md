# SAME SAME - Backend Architecture

## Overview

SAME SAME is a matching system that connects people based on deep similarity in interests, tastes, topics, and personal identity markers. This document describes the database architecture, data flows, and system design.

## Database Schema

### Core Tables

#### 1. `profiles`
Stores user profile information linked to Supabase Auth users.

**Key Fields:**
- `id`: UUID primary key, references `auth.users(id)`
- `display_name`: User's display name
- `age`, `gender`: Demographics
- `bio`: User biography
- `location_country`, `location_city`, `lat`, `lng`: Geographic location
- `languages`: Array of languages spoken
- `rated_count`: Number of interests rated (auto-updated by trigger)

**Indexes:**
- GIN index on `languages` for array queries
- Composite index on `location_country, location_city`
- Index on `lat, lng` for geospatial queries

#### 2. `interests`
Master catalog of all available interests.

**Key Fields:**
- `id`: BigSerial primary key
- `category`: Interest category (e.g., "music", "movies", "books")
- `label`: Interest name
- `popularity`: Float value for popularity weighting (default 0)

**Usage:**
- Populated by administrators
- Used to calculate weighted matching scores
- Lower popularity = higher weight in matching algorithm

#### 3. `user_interests`
User evaluations of interests.

**Key Fields:**
- `user_id`: References `profiles(id)`
- `interest_id`: References `interests(id)`
- `value`: `-1` (dislike) or `+1` (like)
- `rated_at`: Timestamp

**Primary Key:** `(user_id, interest_id)`

**Triggers:**
- Updates `profiles.rated_count` on insert/delete
- Recalculates `user_category_stats` on any change

#### 4. `user_category_stats`
Pre-computed aggregate statistics per category per user.

**Key Fields:**
- `user_id`: References `profiles(id)`
- `category`: Interest category
- `rated_count`: Number of interests rated in this category
- `likes_count`: Number of likes in this category
- `dislikes_count`: Number of dislikes in this category
- `affinity`: Calculated as `(likes - dislikes) / rated_count`

**Primary Key:** `(user_id, category)`

**Purpose:**
- Optimizes matching queries
- Provides quick category-level insights
- Auto-updated by trigger when `user_interests` changes

#### 5. `user_preferences`
User-defined filters for match suggestions.

**Key Fields:**
- `user_id`: References `profiles(id)`
- `preferred_genders`: Array of acceptable genders
- `age_min`, `age_max`: Age range filter
- `radius_km`: Maximum distance in kilometers
- `min_match_percent`: Minimum match percentage threshold (0-100)

**Usage:**
- Applied in `get_matches` edge function
- Users can customize who they want to see

#### 6. `user_likes`
One-way "likes" between users.

**Key Fields:**
- `from_user`: User who sent the like
- `to_user`: User who received the like
- `created_at`: Timestamp

**Primary Key:** `(from_user, to_user)`

**Note:** This is a one-way relationship. Mutual likes can be detected by querying both directions.

#### 7. `chats`
Chat conversations between two users.

**Key Fields:**
- `id`: UUID primary key
- `user1`, `user2`: The two participants
- `created_at`: When chat was created

**Constraints:**
- Unique constraint on `(user1, user2)` to prevent duplicates
- Check constraint ensures `user1 != user2`

#### 8. `messages`
Individual messages within chats.

**Key Fields:**
- `id`: UUID primary key
- `chat_id`: References `chats(id)`
- `sender`: References `profiles(id)`
- `text`: Message content
- `created_at`: When message was sent
- `read_at`: When message was read (NULL if unread)

**Indexes:**
- Composite index on `(chat_id, created_at)` for chat history
- Index on `sender` for user queries
- Partial index on unread messages

## Data Flows

### User Registration Flow

1. User signs up via Supabase Auth
2. Profile created in `profiles` table with `id = auth.users.id`
3. User can optionally create `user_preferences` record
4. User starts rating interests in `user_interests`

### Interest Rating Flow

1. User rates an interest (like/dislike)
2. Insert into `user_interests`
3. Trigger updates `profiles.rated_count`
4. Trigger recalculates `user_category_stats` for that category

### Matching Flow

1. User calls `get_matches` edge function
2. Function:
   - Loads user's interests and preferences
   - Queries all other users' interests
   - Calculates weighted scores per category
   - Applies preference filters (age, gender, match threshold)
   - Returns top 50 matches sorted by `final_match`

### Chat Flow

1. User initiates chat (creates `chats` record)
2. Users send messages (insert into `messages`)
3. Messages can be marked as read (update `read_at`)
4. RLS ensures users can only see their own chats

## Row Level Security (RLS)

All tables have RLS enabled with the following patterns:

- **Profiles**: Readable by all, writable only by owner
- **Interests**: Readable by all (master list)
- **User Interests**: Only accessible by the user
- **User Category Stats**: Only accessible by the user
- **User Preferences**: Only accessible by the user
- **User Likes**: Users can see likes they sent
- **Chats**: Users can only see chats they participate in
- **Messages**: Users can only see messages in their chats

## Edge Functions

### `get_matches`

**Input:**
```json
{
  "user_id": "uuid"
}
```

**Output:**
```json
{
  "matches": [
    {
      "user_id": "uuid",
      "display_name": "string",
      "age": number,
      "gender": "string",
      "bio": "string",
      "location_city": "string",
      "location_country": "string",
      "base_match": number,
      "confidence": number,
      "final_match": number,
      "overlap_count": number,
      "matched_categories": [
        {
          "category": "string",
          "match_c": number
        }
      ]
    }
  ]
}
```

**Algorithm:**
- Calculates weighted scores per interest
- Aggregates to category-level matches
- Applies preference filters
- Returns top 50 sorted by `final_match`

### `get_match_details`

**Input:**
```json
{
  "user_id": "uuid",
  "other_user_id": "uuid"
}
```

**Output:**
```json
{
  "user_id": "uuid",
  "other_user_id": "uuid",
  "user_profile": { ... },
  "other_profile": { ... },
  "categories": [
    {
      "category": "string",
      "match_c": number,
      "overlap_c": number,
      "both_liked": ["string"],
      "both_disliked": ["string"],
      "conflicts": [
        {
          "interest": "string",
          "user_value": number,
          "other_value": number
        }
      ],
      "user_affinity": number,
      "other_affinity": number
    }
  ],
  "overall": {
    "base_match": number,
    "confidence": number,
    "final_match": number,
    "total_overlap": number,
    "total_interests_user": number,
    "total_interests_other": number
  }
}
```

## Triggers

### `update_profile_rated_count`
- Fires on `INSERT` or `DELETE` in `user_interests`
- Increments/decrements `profiles.rated_count`

### `update_user_category_stats`
- Fires on `INSERT`, `UPDATE`, or `DELETE` in `user_interests`
- Recalculates all stats for the affected category
- Updates `user_category_stats` table

### `update_updated_at_column`
- Fires on `UPDATE` for `profiles` and `user_preferences`
- Sets `updated_at` to current timestamp

## Performance Considerations

1. **Indexes**: Strategic indexes on foreign keys, search fields, and composite keys
2. **Pre-computed Stats**: `user_category_stats` avoids recalculating aggregates
3. **GIN Indexes**: Array fields (`languages`) use GIN for efficient queries
4. **Edge Functions**: Matching logic runs server-side to reduce client load
5. **Pagination**: `get_matches` limits to top 50 results

## Future Enhancements

- Geospatial matching using PostGIS (already enabled)
- Real-time chat using Supabase Realtime
- Interest recommendations based on category stats
- Mutual likes detection and notifications
- Match history and analytics

