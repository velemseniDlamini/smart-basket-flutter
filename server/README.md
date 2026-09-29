# Gemini image proxy

Run this local-only proxy with a newly rotated Gemini API key supplied through
the environment. Do not put the key in Flutter, GitHub, source control, or chat:

```sh
GEMINI_API_KEY="your-rotated-key" /usr/bin/python3 server/main.py
```

For local development, the proxy listens on `127.0.0.1:8000`. It accepts JPEG, PNG, or WebP images at
`POST /analyze` and returns product names, visible prices, confidence scores,
verbatim recognized text, and compact receipt-style text. Prices and receipt
fields are omitted or null when not legible; they are never guessed. Do not
deploy this unauthenticated development server publicly.

For Flutter web on the same machine, use the default proxy URL. For a physical
device, use an HTTPS-hosted proxy URL. Do not expose the development server on a
public network. The Render blueprint at the repository root builds
`server/Dockerfile`, checks `/health`, restricts browser CORS to the GitHub Pages
origin, and rate-limits image analysis. Add `GEMINI_API_KEY` as a secret in the
Render dashboard and set the GitHub Actions repository variable
`GEMINI_PROXY_URL` to `https://YOUR-SERVICE.onrender.com/analyze`; never put the
Gemini key in GitHub, Flutter, or source control. Render's free service may sleep
while idle, so the first analysis request after inactivity can take longer.