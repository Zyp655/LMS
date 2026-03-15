# backend

[![style: dart frog lint][dart_frog_lint_badge]][dart_frog_lint_link]
[![License: MIT][license_badge]][license_link]
[![Powered by Dart Frog](https://img.shields.io/endpoint?url=https://tinyurl.com/dartfrog-badge)](https://dart-frog.dev)

An example application built with dart_frog

## Environment Setup

This backend uses environment variables for database configuration to keep sensitive credentials secure.

### Initial Setup

1. Copy the example environment file:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` and update with your actual database credentials:
   ```
   DB_HOST=localhost
   DB_NAME=alarmm_db
   DB_USERNAME=postgres
   DB_PASSWORD=your_actual_password
   DB_PORT=5432
   ```

3. The `.env` file is already in `.gitignore` and will not be committed to version control.

### Running the Backend

```bash
dart_frog dev
```

The application will automatically load the environment variables from `.env` on startup.



[dart_frog_lint_badge]: https://img.shields.io/badge/style-dart_frog_lint-1DF9D2.svg
[dart_frog_lint_link]: https://pub.dev/packages/dart_frog_lint
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT