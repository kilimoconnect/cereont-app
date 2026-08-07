// Cereont — Gmail sync. Pulls recent Gmail messages using the caller's Google
// OAuth access token (passed from the app), AI-triages each new one, and
// inserts it into the `emails` table for the caller's company.
//
// The app obtains the access token by signing in / connecting with the Gmail
// read-only scope, then passes session.providerToken here. No long-lived token
// is stored server-side in this version.
//
// Requires OPENAI_API_KEY (and optionally GEMINI_API_KEY / OPENAI_MODEL).

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
    const user = userData?.user;
    if (!user) return json({ error: "Unauthorized" }, 401);

    const body = await req.json().catch(() => ({}));
    const providerToken: string = (body.providerToken ?? "").toString();
    if (!providerToken) {
      return json({ error: "Missing Google access token — connect Gmail first" }, 400);
    }
    const max = Math.min(Number(body.max ?? 10), 25);

    // Company for this user.
    const { data: member } = await supabase
      .from("company_members")
      .select("company_id")
      .eq("user_id", user.id)
      .order("created_at")
      .limit(1)
      .maybeSingle();
    const companyId = member?.company_id;
    if (!companyId) return json({ error: "No company for user" }, 400);

    // List recent messages.
    const listRes = await fetch(
      `https://gmail.googleapis.com/gmail/v1/users/me/messages?maxResults=${max}&q=${
        encodeURIComponent("newer_than:14d -in:chats")
      }`,
      { headers: { Authorization: `Bearer ${providerToken}` } },
    );
    if (!listRes.ok) {
      return json(
        { error: `Gmail list failed: ${listRes.status} ${await listRes.text()}` },
        502,
      );
    }
    const list = await listRes.json();
    const ids: string[] = (list.messages ?? []).map((m: { id: string }) => m.id);

    let synced = 0;
    for (const id of ids) {
      // Skip if already imported.
      const { data: existing } = await supabase
        .from("emails")
        .select("id")
        .eq("company_id", companyId)
        .eq("provider_message_id", id)
        .maybeSingle();
      if (existing) continue;

      const msgRes = await fetch(
        `https://gmail.googleapis.com/gmail/v1/users/me/messages/${id}?format=full`,
        { headers: { Authorization: `Bearer ${providerToken}` } },
      );
      if (!msgRes.ok) continue;
      const msg = await msgRes.json();

      const headers: { name: string; value: string }[] =
        msg.payload?.headers ?? [];
      const h = (n: string) =>
        headers.find((x) => x.name.toLowerCase() === n.toLowerCase())?.value ??
          "";
      const from = h("From");
      const subject = h("Subject");
      const snippet: string = msg.snippet ?? "";
      const body = extractBody(msg.payload) || snippet;
      const receivedAt = msg.internalDate
        ? new Date(Number(msg.internalDate)).toISOString()
        : new Date().toISOString();

      const triage = await triageEmail(from, subject, body);

      const fromName = from.replace(/<[^>]*>/, "").replace(/"/g, "").trim() ||
        from;
      const fromAddress = (from.match(/<([^>]+)>/)?.[1]) ?? from;

      const { error } = await supabase.from("emails").insert({
        company_id: companyId,
        from_name: fromName,
        from_address: fromAddress,
        subject,
        body: body.slice(0, 8000),
        received_at: receivedAt,
        kind: triage.kind,
        priority: triage.priority,
        ai_summary: triage.summary,
        ai_action: triage.action,
        provider: "gmail",
        provider_message_id: id,
      });
      if (!error) synced++;
    }

    // Record the connected mailbox / last sync.
    const address = user.email ?? null;
    await supabase.from("email_accounts").upsert({
      company_id: companyId,
      user_id: user.id,
      provider: "gmail",
      email_address: address,
      last_synced: new Date().toISOString(),
    }, { onConflict: "company_id,provider,email_address" });

    return json({ synced, scanned: ids.length });
  } catch (e) {
    console.error(e);
    return json({ error: String(e) }, 500);
  }
});

function extractBody(payload: unknown): string {
  const p = payload as {
    mimeType?: string;
    body?: { data?: string };
    parts?: unknown[];
  };
  if (!p) return "";
  if (p.mimeType === "text/plain" && p.body?.data) return decode(p.body.data);
  if (p.parts) {
    for (const part of p.parts) {
      const t = extractBody(part);
      if (t) return t;
    }
  }
  if (p.body?.data) return decode(p.body.data);
  return "";
}

function decode(data: string): string {
  try {
    const b64 = data.replace(/-/g, "+").replace(/_/g, "/");
    return new TextDecoder().decode(
      Uint8Array.from(atob(b64), (c) => c.charCodeAt(0)),
    );
  } catch (_) {
    return "";
  }
}

interface Triage {
  kind: string;
  priority: string;
  summary: string;
  action: string;
}

async function triageEmail(
  from: string,
  subject: string,
  body: string,
): Promise<Triage> {
  const key = Deno.env.get("OPENAI_API_KEY");
  const fallback: Triage = {
    kind: "general",
    priority: "medium",
    summary: subject || "(no subject)",
    action: "",
  };
  if (!key) return fallback;
  const model = Deno.env.get("OPENAI_MODEL") ?? "gpt-4o-mini";

  const sys =
    "Classify this business email. Return STRICT JSON: " +
    '{"kind": one of ["customer_inquiry","supplier_quote","purchase_order","contract","invoice","meeting_request","general"], ' +
    '"priority": one of ["critical","high","medium","low"], ' +
    '"summary": "<one line>", "action": "<suggested next step or empty>"}';
  const content = `From: ${from}\nSubject: ${subject}\n\n${body.slice(0, 4000)}`;

  try {
    const res = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${key}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model,
        temperature: 0.1,
        max_tokens: 300,
        response_format: { type: "json_object" },
        messages: [
          { role: "system", content: sys },
          { role: "user", content },
        ],
      }),
    });
    if (!res.ok) return fallback;
    const data = await res.json();
    const parsed = JSON.parse(data.choices?.[0]?.message?.content ?? "{}");
    return {
      kind: parsed.kind ?? "general",
      priority: parsed.priority ?? "medium",
      summary: (parsed.summary ?? subject ?? "").toString(),
      action: (parsed.action ?? "").toString(),
    };
  } catch (_) {
    return fallback;
  }
}
