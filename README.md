# StudyWISE

Initial build of StudyWISE on `Rails 8 + Hotwire + Solid Stack`.

## Stack

- Rails 8.0.x
- PostgreSQL
- Hotwire (Turbo + Stimulus)
- Tailwind CSS
- Solid Queue / Solid Cache / Solid Cable

## Implemented in this first slice

- Authentication (sign up / sign in / logout) with `has_secure_password`.
- User-scoped dashboard and material ownership.
- Material management (`index/new/create/show/edit/delete`).
- Active Storage support for source file upload (PDF/TXT/MD/DOCX/PPTX).
- Async smart note generation via `NoteGenerationJob`.
- `ruby_llm`-backed Gemini integration (`GEMINI_API_KEY`), with local fallback.
- YouTube processing with YouTube Data API integration (`YOUTUBE_API_KEY`) and transcript fallbacks.
- Seed data for demo user/material/note.

## Run locally

1. Install gems:
   `bundle install`
2. Setup database:
   `bin/rails db:prepare`
3. Seed demo data:
   `bin/rails db:seed`
4. Start app:
   `bin/dev`
5. Open:
   `http://localhost:3000`

Demo account after seeding:
- Email: `demo@studywise.app`
- Password: `password123`

Optional Gemini integration:
- Set env var before boot:
  `export GEMINI_API_KEY=your_key_here`
- Without this key, StudyWISE generates a fallback local note.

Optional YouTube Data API integration:
- Set env var before boot:
  `export YOUTUBE_API_KEY=your_key_here`
- Optional language preference:
  `export YOUTUBE_TRANSCRIPT_LANGS=en,en-US`

## Kamal deployment bootstrap

Kamal scaffolding is now included:
- `config/deploy.yml`
- `.kamal/secrets.example`

Setup steps:
1. Copy secrets template:
   `cp .kamal/secrets.example .kamal/secrets`
2. Set real values in `.kamal/secrets`.
3. Export deploy host/registry env vars:
   `export KAMAL_WEB_HOST=...`
   `export KAMAL_APP_HOST=...`
   `export KAMAL_REGISTRY_USERNAME=...`
4. Validate config:
   `./bin/kamal config`
5. First deploy:
   `./bin/kamal setup`
   `./bin/kamal deploy`

## Next build steps

1. Add Google OAuth on top of password auth.
2. Add password reset + email verification flow.
3. Add export flows (chat transcript and quiz PDF).
4. Add highlight-to-chat and timed quiz mode.
5. Add load testing and deployment hardening.