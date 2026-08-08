// Cereont AI — chief-of-staff intelligence backed by OpenAI (primary) + Gemini (fallback).
// API keys are read from Edge Function secrets (never in code):
//   supabase secrets set OPENAI_API_KEY=sk-...  GEMINI_API_KEY=...
// Optional overrides: OPENAI_MODEL (default gpt-4o-mini), GEMINI_MODEL
// (default gemini-2.0-flash).
//
// Actions (POST body { action, ... }):
//   "chat"  → { message, history } → { reply, provider }
//   "brief" → {}                   → { brief, provider }   (structured JSON)
//
// The function authenticates the caller with their Supabase JWT and reads a
// compact snapshot of *their* business (RLS-scoped) to ground the model.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });
}

interface HistoryItem { fromUser: boolean; text: string; }
interface Msg { role: "system" | "user" | "assistant"; content: string; }

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });

  try {
    const authHeader = req.headers.get("Authorization") ?? "";
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } },
    );

    const { data: userData } = await supabase.auth.getUser();
    if (!userData?.user) return json({ error: "Unauthorized" }, 401);

    const body = await req.json().catch(() => ({}));
    const action: string = body.action ?? "chat";
    const context = await buildContext(supabase);

    if (action === "brief") {
      const system =
        "You are Cereont, an AI chief of staff. Produce a morning executive brief " +
        "as STRICT JSON — no prose outside the JSON. Reason like a seasoned COO: " +
        "tie every item to concrete business impact (revenue share, unblocked orders, " +
        "days overdue, cash at risk). Be specific, not generic.\n\n" +
        "Return exactly this shape:\n" +
        "{\n" +
        '  "score": <integer 0-100, overall business health>,\n' +
        '  "score_reason": "<one sentence explaining the score>",\n' +
        '  "greeting": "Good morning" | "Good afternoon" | "Good evening",\n' +
        '  "headline": "<one punchy sentence on the single most important thing today>",\n' +
        '  "priorities": [{"title":"<what>","why":"<business reason with numbers>","action":"<verb-first next step>"}],\n' +
        '  "risks": [{"title":"<risk>","detail":"<impact + why it matters>"}],\n' +
        '  "opportunities": [{"title":"<opportunity>","detail":"<upside + why now>"}],\n' +
        '  "recommendation": "<the one highest-impact action, with the reasoning>"\n' +
        "}\n" +
        "Score lower for overdue tasks/invoices, silent suppliers, at-risk projects, " +
        "customers overdue to reorder; higher for a clean, on-track book. Max 3 items " +
        "per list, most important first. If data is thin, say so briefly in the reason.\n\n" +
        "BUSINESS CONTEXT (JSON):\n" + context;

      const messages: Msg[] = [
        { role: "system", content: system },
        { role: "user", content: "Generate today's executive brief as JSON." },
      ];
      const { text, provider } = await generate(messages, true);
      const brief = parseJson(text);
      return json({ brief, provider });
    }

    if (action === "meeting") {
      const transcript: string = (body.transcript ?? "").toString();
      if (!transcript.trim()) return json({ error: "Empty transcript" }, 400);
      const system =
        "You are Cereont. Turn raw meeting notes/transcript into STRICT JSON — " +
        "no prose outside JSON:\n" +
        "{\n" +
        '  "title": "<short descriptive title>",\n' +
        '  "summary": "<2-3 sentence summary>",\n' +
        '  "decisions": ["<decision>", ...],\n' +
        '  "action_items": [{"text":"<clear, assignable next step>"}]\n' +
        "}\n" +
        "Extract only what's actually in the notes. Action items must be " +
        "concrete and verb-first.";
      const messages: Msg[] = [
        { role: "system", content: system },
        { role: "user", content: transcript },
      ];
      const { text, provider } = await generate(messages, true);
      const meeting = parseJson(text);
      return json({ meeting, provider });
    }

    if (action === "plan_project") {
      const name: string = (body.name ?? "").toString();
      const description: string = (body.description ?? "").toString();
      if (!name.trim()) return json({ error: "Project name required" }, 400);
      const system =
        "You are Cereont, an AI project manager. Turn an idea into a concrete " +
        "plan as STRICT JSON — no prose outside JSON:\n" +
        "{\n" +
        '  "project_type": "<e.g. Business Creation, Technology Product, Construction, Import, Marketing Campaign, Hiring, Research, Personal Goal>",\n' +
        '  "complexity": "Low" | "Medium" | "High",\n' +
        '  "estimated_duration": "<e.g. 6 months>",\n' +
        '  "objective": "<rewrite the idea as ONE specific, measurable outcome>",\n' +
        '  "required_areas": ["<area>", ...],\n' +
        '  "milestones": [{"title":"<milestone>","tasks":[{"title":"<task>","priority":"critical|high|medium|low"}]}],\n' +
        '  "risks": [{"title":"<risk>","probability":"low|medium|high","impact":"low|medium|high","mitigation":"<action>"}]\n' +
        "}\n" +
        "Order milestones logically (idea → planning → execution → completion). " +
        "3–6 milestones, 2–5 tasks each, 2–4 risks. Be specific to THIS project.";
      const messages: Msg[] = [
        { role: "system", content: system },
        {
          role: "user",
          content: `Project: ${name}\nDescription: ${description}\n\n` +
            `Business context for grounding:\n${context}`,
        },
      ];
      const { text, provider } = await generate(messages, true);
      const plan = parseJson(text);
      return json({ plan, provider });
    }

    if (action === "discover") {
      const idea: string = (body.idea ?? "").toString();
      if (!idea.trim()) return json({ error: "Idea required" }, 400);
      const history: { q: string; a: string }[] = Array.isArray(body.history)
        ? body.history
        : [];
      const qa = history
        .map((h, i) => `Q${i + 1}: ${h.q}\nA${i + 1}: ${h.a}`)
        .join("\n");
      const system =
        "You are Cereont's project discovery interviewer. Decide if you have " +
        "enough to build a solid project plan for the user's idea. If not, ask " +
        "the ONE most important still-unknown, relevant question. Cover objective, " +
        "scope, target, location, timeline, budget, resources, constraints, " +
        "success criteria and risks — but only ask what's missing and matters. " +
        "Ask at most ~6 questions total; stop early when you have enough. " +
        'STRICT JSON only: {"done": boolean, "question": string}. ' +
        "When done is true, question may be an empty string.\n\n" +
        "BUSINESS CONTEXT (JSON):\n" + context;
      const messages: Msg[] = [
        { role: "system", content: system },
        {
          role: "user",
          content: `Idea: ${idea}\n\nAnswers so far:\n${qa || "(none yet)"}` +
            `\n\nWhat is the single next question — or are you done?`,
        },
      ];
      const { text, provider } = await generate(messages, true);
      const out = parseJson(text) as Record<string, unknown>;
      return json({
        done: out.done === true,
        question: (out.question ?? "").toString(),
        provider,
      });
    }

    if (action === "blueprint") {
      const idea: string = (body.idea ?? "").toString();
      if (!idea.trim()) return json({ error: "Idea required" }, 400);
      const history: { q: string; a: string }[] = Array.isArray(body.history)
        ? body.history
        : [];
      const qa = history
        .map((h, i) => `Q${i + 1}: ${h.q}\nA${i + 1}: ${h.a}`)
        .join("\n");
      const system =
        "You are Cereont's project architect. From the idea and discovery " +
        "answers, produce a complete project plan as STRICT JSON:\n" +
        "{\n" +
        '  "understanding": {"name":"<short project name>","objective":"<one specific, measurable outcome>","project_type":"<e.g. Business Creation, Technology Product, Construction, Import>","complexity":"Low|Medium|High","category":"<domain>","target":"<key target/scale>","budget":"<budget or empty>","timeline":"<e.g. 12 months>","success_metrics":["..."],"scope_included":["..."],"scope_excluded":["..."]},\n' +
        '  "milestones": [{"title":"<phase/milestone>","tasks":[{"title":"<task>","priority":"critical|high|medium|low"}]}],\n' +
        '  "risks": [{"title":"...","probability":"low|medium|high","impact":"low|medium|high","mitigation":"..."}],\n' +
        '  "assumptions": [{"statement":"...","confidence": <integer 0-100>}]\n' +
        "}\n" +
        "Order milestones logically (discovery → planning → execution → " +
        "completion). 4–7 milestones, 2–5 tasks each, 3–5 risks, 3–5 " +
        "assumptions. Be specific to THIS project.\n\n" +
        "BUSINESS CONTEXT (JSON):\n" + context;
      const messages: Msg[] = [
        { role: "system", content: system },
        {
          role: "user",
          content: `Idea: ${idea}\n\nDiscovery answers:\n${qa || "(none)"}`,
        },
      ];
      const { text, provider } = await generate(messages, true);
      const blueprint = parseJson(text);
      return json({ blueprint, provider });
    }

    if (action === "parse_task") {
      const text: string = (body.text ?? "").toString();
      if (!text.trim()) return json({ error: "text required" }, 400);
      const today = new Date().toISOString().slice(0, 10);
      const system =
        "Extract a single task from the user's text. Return STRICT JSON: " +
        '{"title":"<concise task title>","due":"<ISO-8601 date, or empty>",' +
        '"priority":"critical|high|medium|low"}. ' +
        `Today is ${today}. Resolve relative dates (tomorrow, Friday, next week). ` +
        "Infer priority from urgency words; default medium.";
      const messages: Msg[] = [
        { role: "system", content: system },
        { role: "user", content: text },
      ];
      const { text: out, provider } = await generate(messages, true);
      return json({ task: parseJson(out), provider });
    }

    if (action === "replan") {
      const change: string = (body.change ?? "").toString();
      if (!change.trim()) return json({ error: "change required" }, 400);
      const project = body.project ?? {};
      const system =
        "You are Cereont's project strategist. The user reports a change to " +
        "THIS project. Produce a concise, concrete impact analysis in markdown " +
        "with these sections: **Impact** (which tasks/milestones are affected), " +
        "**New risks**, **Revised timeline** (a realistic estimate), " +
        "**Budget impact**, and **Recommended plan** (specific next steps). " +
        "Ground everything in the project data.\n\nPROJECT (JSON):\n" +
        JSON.stringify(project);
      const messages: Msg[] = [
        { role: "system", content: system },
        { role: "user", content: `Change: ${change}` },
      ];
      const { text, provider } = await generate(messages, false);
      return json({ analysis: text, provider });
    }

    if (action === "scenarios") {
      const project = body.project ?? {};
      const system =
        "You are Cereont's project strategist. Propose exactly 3 what-if " +
        "scenarios for THIS project (e.g. invest more to launch faster; the " +
        "current plan; reduce cost and launch later). For each, give a short " +
        "name and compare Cost, Timeline, Risk and Expected outcome. Keep it " +
        "concise markdown, then end with a one-line recommendation. Ground it " +
        "in the project data.\n\nPROJECT (JSON):\n" + JSON.stringify(project);
      const messages: Msg[] = [
        { role: "system", content: system },
        { role: "user", content: "Give me the scenarios." },
      ];
      const { text, provider } = await generate(messages, false);
      return json({ analysis: text, provider });
    }

    if (action === "extract_document") {
      const text: string = (body.text ?? "").toString();
      if (!text.trim()) return json({ error: "text required" }, 400);
      const system =
        "Extract the actionable essence of this business document (contract, " +
        "quotation, proposal, plan). Return STRICT JSON: " +
        '{"summary":"<2-3 sentences>",' +
        '"tasks":["<obligation, deadline or requirement as an actionable task>"],' +
        '"risks":["<risk or red flag>"]}. Be concise and specific.';
      const messages: Msg[] = [
        { role: "system", content: system },
        { role: "user", content: text.slice(0, 8000) },
      ];
      const { text: out, provider } = await generate(messages, true);
      return json({ doc: parseJson(out), provider });
    }

    // Default: conversational chat.
    const message: string = (body.message ?? "").toString();
    if (!message.trim()) return json({ error: "Empty message" }, 400);
    const history: HistoryItem[] = Array.isArray(body.history)
      ? body.history.slice(-10)
      : [];

    // Optional per-project scope for project chat.
    const projectContext = body.project
      ? "\n\nCURRENT PROJECT (focus your answer on this):\n" +
        JSON.stringify(body.project)
      : "";

    const system =
      "You are Cereont, an AI chief of staff for a business leader. Be concise, " +
      "direct and action-oriented — lead with the recommendation, then the why. " +
      "Ground every answer in the business context below; if the data doesn't " +
      "cover it, say so briefly.\n\n" +
      "FORMAT FOR A NARROW PHONE SCREEN:\n" +
      "- Keep the whole reply short (usually under 150 words).\n" +
      "- Use short paragraphs (1-2 sentences) separated by a blank line.\n" +
      "- Use '- ' bullet points for lists; keep each bullet to one line.\n" +
      "- Use **bold** only to highlight the single most important phrase.\n" +
      "- Do NOT use tables, headings larger than '###', code blocks, or emojis.\n\n" +
      "BUSINESS CONTEXT (JSON):\n" + context + projectContext;

    const messages: Msg[] = [
      { role: "system", content: system },
      ...history.map((m): Msg => ({
        role: m.fromUser ? "user" : "assistant",
        content: m.text,
      })),
      { role: "user", content: message },
    ];
    const { text, provider } = await generate(messages, false);
    return json({ reply: text, provider });
  } catch (e) {
    console.error(e);
    return json({ error: String(e) }, 500);
  }
});

// ---- Model routing (OpenAI primary, Gemini fallback) ----------------------
async function generate(
  messages: Msg[],
  wantJson: boolean,
): Promise<{ text: string; provider: string }> {
  try {
    return { text: await callOpenAI(messages, wantJson), provider: "openai" };
  } catch (e) {
    console.error("OpenAI failed, falling back to Gemini:", e);
    return { text: await callGemini(messages, wantJson), provider: "gemini" };
  }
}

async function callOpenAI(messages: Msg[], wantJson: boolean): Promise<string> {
  const key = Deno.env.get("OPENAI_API_KEY");
  if (!key) throw new Error("OPENAI_API_KEY not set");
  const model = Deno.env.get("OPENAI_MODEL") ?? "gpt-4o-mini";

  const res = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${key}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model,
      messages,
      temperature: 0.3,
      max_tokens: 900,
      ...(wantJson ? { response_format: { type: "json_object" } } : {}),
    }),
  });
  if (!res.ok) throw new Error(`OpenAI ${res.status}: ${await res.text()}`);
  const data = await res.json();
  const text = data.choices?.[0]?.message?.content?.trim();
  if (!text) throw new Error("OpenAI returned empty content");
  return text;
}

async function callGemini(messages: Msg[], wantJson: boolean): Promise<string> {
  const key = Deno.env.get("GEMINI_API_KEY");
  if (!key) throw new Error("GEMINI_API_KEY not set");
  const model = Deno.env.get("GEMINI_MODEL") ?? "gemini-2.0-flash";

  const system = messages.filter((m) => m.role === "system")
    .map((m) => m.content).join("\n\n");
  const contents = messages.filter((m) => m.role !== "system").map((m) => ({
    role: m.role === "assistant" ? "model" : "user",
    parts: [{ text: m.content }],
  }));

  const res = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${key}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        systemInstruction: system ? { parts: [{ text: system }] } : undefined,
        contents,
        generationConfig: {
          temperature: 0.3,
          maxOutputTokens: 900,
          ...(wantJson ? { responseMimeType: "application/json" } : {}),
        },
      }),
    },
  );
  if (!res.ok) throw new Error(`Gemini ${res.status}: ${await res.text()}`);
  const data = await res.json();
  const text = data.candidates?.[0]?.content?.parts?.[0]?.text?.trim();
  if (!text) throw new Error("Gemini returned empty content");
  return text;
}

// Parse model JSON, tolerating ```json fences or stray prose.
function parseJson(text: string): unknown {
  try {
    return JSON.parse(text);
  } catch (_) {
    const start = text.indexOf("{");
    const end = text.lastIndexOf("}");
    if (start !== -1 && end > start) {
      return JSON.parse(text.slice(start, end + 1));
    }
    throw new Error("Model did not return valid JSON");
  }
}

async function buildContext(supabase: ReturnType<typeof createClient>) {
  const [company, customers, suppliers, tasks, inbox, projects, events] =
    await Promise.all([
      supabase.from("companies").select("name,industry,goals,currency")
        .limit(1).maybeSingle(),
      supabase.from("customers")
        .select("name,segment,lifetime_value,last_order,reorder_cycle_days,notes,tags")
        .limit(50),
      supabase.from("suppliers")
        .select("name,on_time_rate,lead_time_days,payment_terms,notes")
        .limit(50),
      supabase.from("tasks")
        .select("title,priority,status,due,source")
        .neq("status", "done").limit(50),
      supabase.from("emails")
        .select("from_name,subject,kind,priority,ai_summary,deadline")
        .eq("handled", false).limit(30),
      supabase.from("projects")
        .select("name,status,deadline,progress").limit(30),
      supabase.from("calendar_events")
        .select("title,start_at,kind").limit(30),
    ]);

  return JSON.stringify({
    today: new Date().toISOString().slice(0, 10),
    company: company.data ?? null,
    customers: customers.data ?? [],
    suppliers: suppliers.data ?? [],
    openTasks: tasks.data ?? [],
    unhandledInbox: inbox.data ?? [],
    projects: projects.data ?? [],
    calendar: events.data ?? [],
  });
}
