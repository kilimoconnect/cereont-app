# `ai` Edge Function — OpenAI + Gemini

Cereont's chief-of-staff chat. Calls **OpenAI** first and falls back to
**Gemini** if OpenAI errors or times out. API keys stay server-side as function
secrets; the app never sees them. The function authenticates the caller with
their Supabase JWT and reads a compact, RLS-scoped snapshot of their business to
ground the model.

## 1. Set the secrets

```bash
supabase secrets set OPENAI_API_KEY=sk-xxxxxxxx
supabase secrets set GEMINI_API_KEY=AIzaSyxxxxxxxx
# optional model overrides:
supabase secrets set OPENAI_MODEL=gpt-4o-mini
supabase secrets set GEMINI_MODEL=gemini-2.0-flash
```

(You can also set these under **Dashboard → Edge Functions → Manage secrets**.)
`SUPABASE_URL` and `SUPABASE_ANON_KEY` are injected automatically.

## 2. Deploy

With the [Supabase CLI](https://supabase.com/docs/guides/cli):

```bash
supabase login
supabase link --project-ref ckrmgjxoxscdcprakbzc
supabase functions deploy ai
```

No CLI? In the **Dashboard → Edge Functions → Create a function**, name it `ai`,
and paste the contents of `index.ts`.

## 3. Request / response

Request body (the app sends this):

```json
{
  "action": "chat",
  "message": "What should I focus on today?",
  "history": [{ "fromUser": true, "text": "..." }]
}
```

Response:

```json
{ "reply": "…", "provider": "openai" }
```

## Fallback behaviour

If the function is missing, unauthenticated, or both providers fail, the Flutter
app silently falls back to its offline rules engine
(`lib/services/ai_engine.dart`), so chat always works. `AppState.lastAiProvider`
records which backend answered (`openai` / `gemini` / `offline`).
