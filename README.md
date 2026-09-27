# Smart Basket

## GitHub Pages

The `Deploy Flutter Web to GitHub Pages` workflow builds and publishes the app
when a commit is pushed to `main`. Create a GitHub repository, push this project
to its `main` branch, then set **Settings > Pages > Build and deployment >
Source** to **GitHub Actions**. The site will be available at
`https://OWNER.github.io/REPOSITORY/`.

The web build works over HTTPS, so a phone browser can grant camera access.
Allow camera permission when prompted.

## Image Analysis

GitHub Pages only hosts static files. The image-analysis API must be hosted
separately at an authenticated, rate-limited HTTPS endpoint. Set the repository
Actions variable `GEMINI_PROXY_URL` to that endpoint to include it in the next
web build. Never put the Gemini API key in the Flutter app or a GitHub Actions
variable. The development proxy in `server/` is unauthenticated and must not be
exposed publicly.
