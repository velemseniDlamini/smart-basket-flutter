# Smart Basket

## GitHub Pages

The `Deploy Flutter Web to GitHub Pages` workflow builds and publishes the app
when a commit is pushed to `main`. Create a GitHub repository, push this project
to its `main` branch, then set **Settings > Pages > Build and deployment >
Source** to **GitHub Actions**. The site will be available at
`https://OWNER.github.io/REPOSITORY/`.

The web build works over HTTPS, so a phone browser can grant camera access.
The scanner uses the rear-facing camera only, and its web preview leaves Flutter
controls touchable. When configured, it reads a frame automatically about every
seven seconds and displays extracted label text.

## Image Analysis

GitHub Pages only hosts static files. The image-analysis API must be hosted
separately at an authenticated, rate-limited HTTPS endpoint. Set the repository
Actions variable `GEMINI_PROXY_URL` to that endpoint to include it in the next
web build. Never put the Gemini API key in the Flutter app or a GitHub Actions
variable. Without `GEMINI_PROXY_URL`, the camera preview still works but price
reading is unavailable. The development proxy in `server/` is unauthenticated
and must not be exposed publicly.

## Supabase

The Flutter app uses Supabase Auth for email/password accounts and stores
itemized receipts in `public.shopping_receipts`. Run
[`supabase/schema.sql`](supabase/schema.sql) in the Supabase SQL Editor to
create the table and user-scoped row-level security policies. Keep RLS enabled;
the app uses only the public publishable key and must never contain a
service-role key.

Local builds use the project URL and publishable key defined in `lib/main.dart`.
GitHub Pages receives the same public values by default; override them with the
Actions repository variables `SUPABASE_URL` and
`SUPABASE_PUBLISHABLE_KEY` if needed. Add the deployed GitHub Pages URL to
Supabase Auth's allowed redirect URLs, and configure email confirmation
according to the desired sign-up flow.
