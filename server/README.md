# Gemini image proxy

Run this local-only proxy with a newly rotated Gemini API key supplied through
the environment. Do not put the key in Flutter, GitHub, source control, or chat:

```sh
GEMINI_API_KEY="your-rotated-key" /usr/bin/python3 server/main.py
```

The proxy listens on `127.0.0.1:8000`. It accepts JPEG, PNG, or WebP images at
`POST /analyze` and returns product names, visible prices, confidence scores,
verbatim recognized text, and compact receipt-style text. Prices and receipt
fields are omitted or null when not legible; they are never guessed. Do not
deploy this unauthenticated development server publicly.

For Flutter web on the same machine, use the default proxy URL. For a physical
device, set `GEMINI_PROXY_URL` to the development computer's LAN address, for
example `http://192.168.1.20:8000/analyze`, and start the proxy with
`HOST=0.0.0.0` on a trusted private network. Use an authenticated,
rate-limited HTTPS proxy for production.