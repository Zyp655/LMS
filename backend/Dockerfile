FROM dart:stable AS build

RUN dart pub global activate dart_frog_cli

WORKDIR /app

COPY pubspec.* ./
RUN dart pub get

COPY . .
RUN dart pub get --offline
RUN dart pub global run dart_frog build
RUN dart compile exe build/bin/server.dart -o build/bin/server

FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=build /app/build/bin/server /app/bin/server

RUN mkdir -p /app/uploads/documents /app/uploads/videos

EXPOSE 8080

ENV PORT=8080

CMD ["/app/bin/server"]
