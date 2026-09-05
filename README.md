# StudyWISE

StudyWISE is an AI-powered study companion that helps students learn faster. It automatically generates smart notes from course materials (PDF, TXT, DOCX) and YouTube videos using Google Gemini. Built on Rails 8, Hotwire, and the Solid Stack, it provides a fast, modern study dashboard right out of the box.

## Features

- **Smart Note Generation**: Asynchronously process PDFs, documents, and YouTube videos into comprehensive study notes via Gemini.
- **Material Management**: Upload, organize, and manage study materials in a personalized dashboard.
- **Modern Rails Stack**: Built on Rails 8.0, PostgreSQL, Hotwire (Turbo + Stimulus), Tailwind CSS, and Solid Queue/Cache/Cable.
- **Easy Deployment**: Kamal-ready configuration for zero-downtime deployment.

## Installation

### Prerequisites

- Ruby 3.2+
- PostgreSQL
- Redis (optional, depending on cache setup)

### Quickstart

Get StudyWISE up and running locally in minutes:

```bash
# Clone the repository
git clone https://github.com/your-username/studywise.git
cd studywise

# Install dependencies
bundle install

# Setup the database
bin/rails db:prepare

# Seed the database with a demo user and materials
bin/rails db:seed

# Start the application
bin/dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

**Demo Account**
- **Email:** `demo@studywise.app`
- **Password:** `password123`

## Configuration

StudyWISE uses `.env` files for environment variable configuration.

### AI Integration (Google Gemini)

To enable AI-powered note generation, you need a Google Gemini API key. Without this key, StudyWISE generates fallback local notes.

```bash
export GEMINI_API_KEY=your_gemini_api_key
```

### YouTube Integration

To process YouTube videos, configure the YouTube Data API:

```bash
export YOUTUBE_API_KEY=your_youtube_api_key
export YOUTUBE_TRANSCRIPT_LANGS=en,en-US # Optional
```

## Development

StudyWISE includes a standard test suite:

```bash
bin/rails test
```

Next features currently in development:
1. Google OAuth authentication.
2. Password reset and email verification flows.
3. Export functionality for chat transcripts and quiz PDFs.
4. Highlight-to-chat and timed quiz mode.

## Deployment

Kamal configuration is included in `config/deploy.yml`.

1. Copy the secrets template:
   ```bash
   cp .kamal/secrets.example .kamal/secrets
   ```
2. Set your production values in `.kamal/secrets`.
3. Export deploy host and registry environment variables:
   ```bash
   export KAMAL_WEB_HOST=your_web_host
   export KAMAL_APP_HOST=your_app_host
   export KAMAL_REGISTRY_USERNAME=your_registry_username
   ```
4. Validate config and deploy:
   ```bash
   ./bin/kamal config
   ./bin/kamal setup
   ./bin/kamal deploy
   ```

## Contributing

We welcome contributions! Please follow standard Ruby conventions and ensure tests pass before submitting a pull request.

## License

This project is licensed under the MIT License.
