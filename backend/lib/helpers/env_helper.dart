import 'dart:io';
import 'package:dotenv/dotenv.dart';

DotEnv? _cached;

DotEnv loadEnv() {
  if (_cached != null) return _cached!;
  final env = DotEnv(includePlatformEnvironment: true);
  if (File('.env').existsSync()) {
    env.load();
  }
  _cached = env;
  return env;
}
