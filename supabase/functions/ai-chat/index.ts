const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const json = (body: Record<string, unknown>, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });

// The deployed function keeps GEMINI_API_KEY in Supabase Edge Function Secrets.
// JWT verification remains enabled: only a signed-in app user can call it.
Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") return json({ error: "Method not allowed" }, 405);

  try {
    const payload = await request.json();
    const message = typeof payload.message === "string" ? payload.message.trim() : "";
    const context = payload.context ?? {};
    if (!message || message.length > 1000) {
      return json({ error: "Question must contain 1-1000 characters" }, 400);
    }

    const apiKey = Deno.env.get("GEMINI_API_KEY");
    if (!apiKey) return json({ error: "AI service is not configured" }, 503);

    const prompt = [
      "You are a helpful financial assistant for the Flutter app Otbasy kapitaly.",
      "Answer in Kazakh, clearly and briefly. Use the supplied budget context only.",
      "Do not invent transactions, do not promise financial results, and do not give medical or legal advice.",
      `Budget context: ${JSON.stringify(context)}`,
      `User question: ${message}`,
    ].join("\n");

    const response = await fetch(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent?key=" + apiKey,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          contents: [{ role: "user", parts: [{ text: prompt }] }],
          generationConfig: { temperature: 0.35, maxOutputTokens: 350 },
        }),
      },
    );
    const data = await response.json();
    if (!response.ok) {
      console.error("Gemini error", response.status, data);
      return json({ error: "Gemini жауап бере алмады" }, 502);
    }
    const answer = data.candidates?.[0]?.content?.parts
      ?.map((part: { text?: string }) => part.text ?? "")
      .join("")
      .trim();
    if (!answer) return json({ error: "Empty AI response" }, 502);
    return json({ answer });
  } catch (error) {
    console.error("ai-chat error", error);
    return json({ error: "AI сұрауын орындау мүмкін болмады" }, 500);
  }
});
