import 'dart:convert';
import 'package:redis/redis.dart';
import 'package:backend/helpers/env_helper.dart';
import 'package:backend/helpers/log.dart';

class RedisService {
  RedisConnection? _connection;
  Command? _command;
  bool _connected = false;

  static final RedisService _instance = RedisService._internal();
  factory RedisService() => _instance;
  RedisService._internal();

  Future<void> connect() async {
    if (_connected) return;
    try {
      final env = loadEnv();
      final redisUrl = env['REDIS_URL'] ?? 'redis://localhost:6379';
      final uri = Uri.parse(redisUrl);
      final host = uri.host.isEmpty ? 'localhost' : uri.host;
      final port = uri.port == 0 ? 6379 : uri.port;

      _connection = RedisConnection();
      _command = await _connection!.connect(host, port);

      final password = uri.userInfo.contains(':')
          ? uri.userInfo.split(':').last
          : (uri.userInfo.isNotEmpty ? uri.userInfo : null);
      if (password != null && password.isNotEmpty) {
        await _command!.send_object(['AUTH', password]);
      }

      _connected = true;
      Log.info('Redis', 'Connected to $host:$port');
    } catch (e) {
      Log.warning('Redis', 'Failed to connect: $e — falling back to no-cache');
      _connected = false;
    }
  }

  bool get isConnected => _connected;

  Future<String?> get(String key) async {
    if (!_connected) return null;
    try {
      final result = await _command!.send_object(['GET', key]);
      if (result == null) return null;
      return result.toString();
    } catch (e) {
      Log.warning('Redis', 'GET $key failed: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getJson(String key) async {
    final raw = await get(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> set(String key, String value, {int ttlSeconds = 300}) async {
    if (!_connected) return;
    try {
      await _command!.send_object(['SET', key, value, 'EX', '$ttlSeconds']);
    } catch (e) {
      Log.warning('Redis', 'SET $key failed: $e');
    }
  }

  Future<void> setJson(String key, Map<String, dynamic> value,
      {int ttlSeconds = 300}) async {
    await set(key, jsonEncode(value), ttlSeconds: ttlSeconds);
  }

  Future<void> delete(String key) async {
    if (!_connected) return;
    try {
      await _command!.send_object(['DEL', key]);
    } catch (e) {
      Log.warning('Redis', 'DEL $key failed: $e');
    }
  }

  Future<void> deletePattern(String pattern) async {
    if (!_connected) return;
    try {
      final keys = await _command!.send_object(['KEYS', pattern]);
      if (keys is List && keys.isNotEmpty) {
        for (final key in keys) {
          await _command!.send_object(['DEL', key.toString()]);
        }
      }
    } catch (e) {
      Log.warning('Redis', 'DEL pattern $pattern failed: $e');
    }
  }

  Future<int> increment(String key, {int ttlSeconds = 60}) async {
    if (!_connected) return 0;
    try {
      final result = await _command!.send_object(['INCR', key]);
      final count = int.tryParse(result.toString()) ?? 0;
      if (count == 1) {
        await _command!.send_object(['EXPIRE', key, '$ttlSeconds']);
      }
      return count;
    } catch (e) {
      Log.warning('Redis', 'INCR $key failed: $e');
      return 0;
    }
  }

  Future<int?> ttl(String key) async {
    if (!_connected) return null;
    try {
      final result = await _command!.send_object(['TTL', key]);
      return int.tryParse(result.toString());
    } catch (e) {
      return null;
    }
  }
}
