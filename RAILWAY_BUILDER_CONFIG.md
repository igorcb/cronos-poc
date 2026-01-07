# Railway Builder Configuration

## Build System: Dockerfile

This project uses **Dockerfile** as the build system on Railway.app.

### Why Dockerfile?

- The project uses **npm** (package-lock.json), not Yarn
- Railpack and Nixpacks auto-detection were looking for yarn.lock
- Dockerfile gives us explicit control over the build process

### Build Process

See [Dockerfile](Dockerfile) for the complete build configuration:

1. Base image: `ruby:3.3.0-slim`
2. System dependencies: PostgreSQL client, Node.js, npm, libvips
3. Ruby gems: `bundle install`
4. Node packages: `npm install --legacy-peer-deps`
5. Asset compilation: `rails assets:precompile`
6. Runtime: Puma server on port 3000

### Railway Settings

**Settings > Build > Builder**: Dockerfile (selected manually)

### Deployment

The `Procfile` defines two processes:
- **web**: `bundle exec puma -C config/puma.rb`
- **release**: `bin/rails db:migrate db:seed` (runs before web)

### Environment Variables Required

See [DEPLOY_QUICK_START.md](DEPLOY_QUICK_START.md) for complete list:
- `RAILS_MASTER_KEY`
- `ADMIN_EMAIL`
- `ADMIN_PASSWORD`
- `RAILS_ENV=production`
- `DATABASE_URL` (auto-provided by Railway PostgreSQL)
- `RAILS_SERVE_STATIC_FILES=true`
- `RAILS_LOG_TO_STDOUT=true`

---

**Last Updated**: 2026-01-07
**Railway Project**: cronos-poc
**Builder**: Dockerfile
