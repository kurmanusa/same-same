// SAME SAME - Get Matches Edge Function
// Returns top 50 matches for a user sorted by final_match score

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface MatchResult {
  user_id: string;
  display_name: string;
  age: number | null;
  gender: string | null;
  bio: string | null;
  location_city: string | null;
  location_country: string | null;
  base_match: number;
  confidence: number;
  final_match: number;
  overlap_count: number;
  matched_categories: Array<{
    category: string;
    match_c: number;
  }>;
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Get user_id from request
    const { user_id } = await req.json();

    if (!user_id) {
      return new Response(
        JSON.stringify({ error: "user_id is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      {
        global: {
          headers: { Authorization: req.headers.get("Authorization")! },
        },
      }
    );

    // Get user preferences
    const { data: preferences, error: prefError } = await supabaseClient
      .from("user_preferences")
      .select("*")
      .eq("user_id", user_id)
      .single();

    if (prefError && prefError.code !== "PGRST116") {
      throw prefError;
    }

    // Get user's interests (using new schema: user_interest_items)
    const { data: userInterests, error: userIntError } = await supabaseClient
      .from("user_interest_items")
      .select(`
        item_id,
        value,
        interest_items:item_id (
          id,
          label,
          list_codes
        )
      `)
      .eq("user_id", user_id);

    if (userIntError) throw userIntError;

    if (!userInterests || userInterests.length === 0) {
      return new Response(
        JSON.stringify({ matches: [] }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Build user interest map: { item_id: { value, listCodes } }
    const userInterestMap = new Map<number, { value: number; listCodes: string[] }>();
    for (const ui of userInterests) {
      const interest = (ui.interest_items as any);
      if (interest && interest.list_codes) {
        userInterestMap.set(ui.item_id, {
          value: ui.value,
          listCodes: interest.list_codes || [],
        });
      }
    }

    // Get all other users' interests
    const { data: allUserInterests, error: allIntError } = await supabaseClient
      .from("user_interest_items")
      .select(`
        user_id,
        item_id,
        value,
        interest_items:item_id (
          id,
          list_codes
        )
      `)
      .neq("user_id", user_id);

    if (allIntError) throw allIntError;

    // Group by user_id and calculate matches
    // Now we match by list_codes (categories) instead of single category
    const userMatches = new Map<string, {
      scores: Map<string, { score: number; maxScore: number }>;
      overlapCount: number;
    }>();

    for (const otherUi of allUserInterests || []) {
      const otherUserId = otherUi.user_id;
      const itemId = otherUi.item_id;
      const otherValue = otherUi.value;
      const interest = (otherUi.interest_items as any);

      if (!interest || !interest.list_codes) continue;

      const userInterest = userInterestMap.get(itemId);
      if (!userInterest) continue; // No overlap

      // Get common list codes (categories) between user and other user
      const userListCodes = new Set(userInterest.listCodes);
      const otherListCodes = new Set(interest.list_codes);
      const commonCategories = Array.from(userListCodes).filter(code => otherListCodes.has(code));

      if (commonCategories.length === 0) continue; // No common categories

      // Use equal weight for all items (no popularity field in new schema)
      const weight = 1.0;

      if (!userMatches.has(otherUserId)) {
        userMatches.set(otherUserId, {
          scores: new Map(),
          overlapCount: 0,
        });
      }

      const match = userMatches.get(otherUserId)!;
      match.overlapCount++;

      // Add score to each common category
      for (const category of commonCategories) {
        if (!match.scores.has(category)) {
          match.scores.set(category, { score: 0, maxScore: 0 });
        }

        const catScore = match.scores.get(category)!;
        catScore.maxScore += 2 * weight;

        // Calculate score contribution
        if (userInterest.value === otherValue) {
          // Both like or both dislike: +2 * weight
          catScore.score += 2 * weight;
        } else {
          // Conflict: -2 * weight
          catScore.score -= 2 * weight;
        }
      }
    }

    // Get profiles for matched users
    const matchedUserIds = Array.from(userMatches.keys());
    if (matchedUserIds.length === 0) {
      return new Response(
        JSON.stringify({ matches: [] }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Build query with filters
    let profileQuery = supabaseClient
      .from("profiles")
      .select("*")
      .in("id", matchedUserIds);

    // Apply preference filters
    if (preferences) {
      if (preferences.preferred_genders && preferences.preferred_genders.length > 0) {
        profileQuery = profileQuery.in("gender", preferences.preferred_genders);
      }
      if (preferences.age_min) {
        profileQuery = profileQuery.gte("age", preferences.age_min);
      }
      if (preferences.age_max) {
        profileQuery = profileQuery.lte("age", preferences.age_max);
      }
    }

    const { data: profiles, error: profileError } = await profileQuery;

    if (profileError) throw profileError;

    // Calculate final scores and build results
    const results: MatchResult[] = [];

    for (const profile of profiles || []) {
      const match = userMatches.get(profile.id);
      if (!match) continue;

      // Calculate category matches
      const matchedCategories: Array<{ category: string; match_c: number }> = [];
      let totalBaseScore = 0;
      let totalMaxScore = 0;

      for (const [category, catScore] of match.scores.entries()) {
        const match_c = catScore.maxScore > 0
          ? catScore.score / catScore.maxScore
          : 0;

        matchedCategories.push({ category, match_c });

        totalBaseScore += catScore.score;
        totalMaxScore += catScore.maxScore;
      }

      // Base match: average of category matches
      const base_match = matchedCategories.length > 0
        ? matchedCategories.reduce((sum, c) => sum + c.match_c, 0) / matchedCategories.length
        : 0;

      // Confidence: based on overlap count (more overlap = higher confidence)
      // Normalize to 0-1 range (assuming reasonable overlap range)
      const confidence = Math.min(match.overlapCount / 20, 1);

      // Final match: base_match * (0.5 + 0.5 * confidence)
      const final_match = base_match * (0.5 + 0.5 * confidence);

      // Apply minimum match filter
      if (preferences && preferences.min_match_percent) {
        const minMatch = preferences.min_match_percent / 100;
        if (final_match < minMatch) continue;
      }

      results.push({
        user_id: profile.id,
        display_name: profile.display_name,
        age: profile.age,
        gender: profile.gender,
        bio: profile.bio,
        location_city: profile.location_city,
        location_country: profile.location_country,
        base_match,
        confidence,
        final_match,
        overlap_count: match.overlapCount,
        matched_categories: matchedCategories,
      });
    }

    // Sort by final_match descending and limit to top 50
    results.sort((a, b) => b.final_match - a.final_match);
    const topResults = results.slice(0, 50);

    return new Response(
      JSON.stringify({ matches: topResults }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});

