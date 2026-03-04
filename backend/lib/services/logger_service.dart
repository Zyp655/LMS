import 'dart:io';

class Logger {
  Logger._();
  static final instance = Logger._();

  void info(String message, {String? context}) {
    _log('INFO', message, context: context);
  }

  void warn(String message, {String? context}) {
    _log('WARN', message, context: context);
  }

  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? context,
  }) {
    final buffer = StringBuffer(message);
    if (error != null) buffer.write(' | error=$error');
    if (stackTrace != null) buffer.write('\n$stackTrace');
    _log('ERROR', buffer.toString(), context: context);
  }

  void _log(String level, String message, {String? context}) {
    final now = DateTime.now().toIso8601String();
    final ctx = context != null ? ' [$context]' : '';
    stderr.writeln('$now | $level$ctx | $message');
  }
}

final logger = Logger.instance;
