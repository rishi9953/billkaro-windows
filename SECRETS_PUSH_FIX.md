# Fix GitHub push blocked by Twilio secret

GitHub blocked your push because **Twilio Account SID and Auth Token** were committed in:

- `lib/app/modules/Whatsapp Marketing/twilioapi_service.dart` (in history)

The repo now uses **environment variables** for Twilio (no secrets in code). You still need to **rewrite git history** so the old commits no longer contain the secret, then force-push.

---

## 1. Add your real Twilio values to `.env` (local only)

Copy from `.env.example` and set in your **local** `.env` (never commit `.env`):

```env
TWILIO_ACCOUNT_SID=ACxxxxxxxx...
TWILIO_AUTH_TOKEN=your_auth_token
TWILIO_WHATSAPP_NUMBER=whatsapp:+14155238886
```

Get these from [Twilio Console](https://console.twilio.com). If the secret was already rotated in Twilio, use the new values.

---

## 2. Rewrite history to remove the secret from old commits

**First**, commit the safe Twilio service and related changes (so the latest commit uses env vars, not secrets):

```powershell
git add "lib/app/modules/Whatsapp Marketing/twilioapi_service.dart" .env.example scripts/ SECRETS_PUSH_FIX.md
git commit -m "Use env vars for Twilio; add script to fix history"
```

Then run the following in **PowerShell** from the repo root (`d:\Flutter Projects\billkaro_windows`).

**2.1** Copy the fix script to a location **outside** the repo (filter-branch checks out old commits, so the script must not be inside the repo during the rewrite):

```powershell
Copy-Item "scripts\fix-twilio-secret-in-history.ps1" "C:\temp\fix-twilio-secret-in-history.ps1"
```

**2.2** Rewrite all commits that contain the file (replace the secrets with placeholders):

```powershell
git filter-branch -f --tree-filter "powershell -ExecutionPolicy Bypass -File C:\temp\fix-twilio-secret-in-history.ps1" c5fc5b3^..HEAD
```

**2.3** Force-push (this overwrites `main` on GitHub; make sure no one else is pushing to `main`):

```powershell
git push --force-with-lease origin main
```

---

## 3. Optional: rotate the exposed Twilio secret

Because the real Account SID and Auth Token were in commits, treat them as **exposed**. In [Twilio Console](https://console.twilio.com) → Account → API keys & tokens, **regenerate the Auth Token** and use the new value in your local `.env`.

---

## Summary

| Step | Action |
|------|--------|
| 1 | Put Twilio keys in local `.env` (see `.env.example`) |
| 2 | `Copy-Item scripts\fix-twilio-secret-in-history.ps1 C:\temp\` |
| 3 | `git filter-branch -f --tree-filter "powershell -ExecutionPolicy Bypass -File C:\temp\fix-twilio-secret-in-history.ps1" c5fc5b3^..HEAD` |
| 4 | `git push --force-with-lease origin main` |
| 5 | Rotate Twilio Auth Token in Twilio Console and update `.env` |

After this, the branch should push successfully and no secrets will remain in history.
