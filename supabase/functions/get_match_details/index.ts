// SAME SAME - Get Match Details Edge Function
// Returns full comparison between two users

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface CategoryComparison {
  category: string;
  match_c: number;
  overlap_c: number;
  both_liked: string[];
  both_disliked: string[];
  conflicts: Array<{
    interest: string;
    user_value: number;
    other_value: number;
  }>;
  user_affinity: number;
  other_affinity: number;
}

interface MatchDetails {
  user_id: string;
  other_user_id: string;
  user_profile: any;
  other_profile: any;
  categories: CategoryComparison[];
  overall: {
    base_match: number;
    confidence: number;
    final_match: number;
    total_overlap: number;
    total_interests_user: number;
    total_interests_other: number;
  };
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Get user_id and other_user_id from request
    const { user_id, other_user_id } = await req.json();

    if (!user_id || !other_user_id) {
      return new Response(
        JSON.stringify({ error: "user_id and other_user_id are required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (user_id === other_user_id) {
      return new Response(
        JSON.stringify({ error: "user_id and other_user_id must be different" }),
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

    // Get both profiles
    const { data: profiles, error: profileError } = await supabaseClient
      .from("profiles")
      .select("*")
      .in("id", [user_id, other_user_id]);

    if (profileError) throw profileError;
    if (!profiles || profiles.length !== 2) {
      return new Response(
        JSON.stringify({ error: "One or both users not found" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const userProfile = profiles.find((p) => p.id === user_id);
    const otherProfile = profiles.find((p) => p.id === other_user_id);

    if (!userProfile || !otherProfile) {
      return new Response(
        JSON.stringify({ error: "User profiles not found" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Get both users' interests with full details (using new schema: user_interest_items)
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

    const { data: otherInterests, error: otherIntError } = await supabaseClient
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
      .eq("user_id", other_user_id);

    if (otherIntError) throw otherIntError;

    // Build interest maps
    const userInterestMap = new Map<number, { value: number; interest: any }>();
    const otherInterestMap = new Map<number, { value: number; interest: any }>();

    for (const ui of userInterests || []) {
      const interest = ui.interest_items as any;
      if (interest) {
        userInterestMap.set(ui.item_id, {
          value: ui.value,
          interest,
        });
      }
    }

    for (const oi of otherInterests || []) {
      const interest = oi.interest_items as any;
      if (interest) {
        otherInterestMap.set(oi.item_id, {
          value: oi.value,
          interest,
        });
      }
    }

    // Find overlapping interests and group by list_code (category)
    // Since items can belong to multiple categories (list_codes), we need to handle that
    const categoryData = new Map<string, {
      interests: Array<{
        item_id: number;
        label: string;
        user_value: number;
        other_value: number;
        weight: number;
      }>;
    }>();

    let totalOverlap = 0;
    const weight = 1.0; // Equal weight for all items (no popularity in new schema)

    for (const [itemId, userData] of userInterestMap.entries()) {
      const otherData = otherInterestMap.get(itemId);
      if (!otherData) continue;

      totalOverlap++;
      const userListCodes = userData.interest.list_codes || [];
      const otherListCodes = otherData.interest.list_codes || [];
      
      // Find common list codes (categories) between both users
      const commonCategories = userListCodes.filter((code: string) => 
        otherListCodes.includes(code)
      );

      // If no common categories, skip this item
      if (commonCategories.length === 0) continue;

      // Add this interest to each common category
      for (const category of commonCategories) {
        if (!categoryData.has(category)) {
          categoryData.set(category, { interests: [] });
        }

        categoryData.get(category)!.interests.push({
          item_id: itemId,
          label: userData.interest.label,
          user_value: userData.value,
          other_value: otherData.value,
          weight,
        });
      }
    }

    // Build category comparisons
    const categories: CategoryComparison[] = [];

    for (const [category, data] of categoryData.entries()) {
      let score = 0;
      let maxScore = 0;
      const bothLiked: string[] = [];
      const bothDisliked: string[] = [];
      const conflicts: Array<{
        interest: string;
        user_value: number;
        other_value: number;
      }> = [];

      for (const interest of data.interests) {
        maxScore += 2 * interest.weight;

        if (interest.user_value === interest.other_value) {
          if (interest.user_value === 1) {
            score += 2 * interest.weight;
            bothLiked.push(interest.label);
          } else {
            score += 2 * interest.weight;
            bothDisliked.push(interest.label);
          }
        } else {
          score -= 2 * interest.weight;
          conflicts.push({
            interest: interest.label,
            user_value: interest.user_value,
            other_value: interest.other_value,
          });
        }
      }

      const match_c = maxScore > 0 ? score / maxScore : 0;
      const overlap_c = data.interests.length;
      // No user_category_stats in new schema, set to 0
      const userAffinity = 0;
      const otherAffinity = 0;

      categories.push({
        category,
        match_c,
        overlap_c,
        both_liked: bothLiked,
        both_disliked: bothDisliked,
        conflicts,
        user_affinity: userAffinity,
        other_affinity: otherAffinity,
      });
    }

    // Sort categories by match_c descending
    categories.sort((a, b) => b.match_c - a.match_c);

    // Calculate overall stats
    const base_match = categories.length > 0
      ? categories.reduce((sum, c) => sum + c.match_c, 0) / categories.length
      : 0;

    const confidence = Math.min(totalOverlap / 20, 1);
    const final_match = base_match * (0.5 + 0.5 * confidence);

    const result: MatchDetails = {
      user_id,
      other_user_id,
      user_profile: {
        id: userProfile.id,
        display_name: userProfile.display_name,
        age: userProfile.age,
        gender: userProfile.gender,
        bio: userProfile.bio,
        location_city: userProfile.location_city,
        location_country: userProfile.location_country,
      },
      other_profile: {
        id: otherProfile.id,
        display_name: otherProfile.display_name,
        age: otherProfile.age,
        gender: otherProfile.gender,
        bio: otherProfile.bio,
        location_city: otherProfile.location_city,
        location_country: otherProfile.location_country,
      },
      categories,
      overall: {
        base_match,
        confidence,
        final_match,
        total_overlap: totalOverlap,
        total_interests_user: userInterests?.length || 0,
        total_interests_other: otherInterests?.length || 0,
      },
    };

    return new Response(
      JSON.stringify(result),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});

