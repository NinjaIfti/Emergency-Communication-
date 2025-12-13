import 'dart:io';

class AppLogger {
  static final AppLogger instance = AppLogger._init();
  
  AppLogger._init();

  final List<LogEntry> _logs = [];
  static const int _maxLogs = 1000;
  bool _enableConsoleLogging = true;
  LogLevel _minLogLevel = LogLevel.info;

  // Log levels
  void setMinLogLevel(LogLevel level) {
    _minLogLevel = level;
  }

  void setConsoleLogging(bool enabled) {
    _enableConsoleLogging = enabled;
  }

  // Log methods
  void debug(String message, {String? tag}) {
    _log(LogLevel.debug, message, tag: tag);
  }

  void info(String message, {String? tag}) {
    _log(LogLevel.info, message, tag: tag);
  }

  void warning(String message, {String? tag}) {
    _log(LogLevel.warning, message, tag: tag);
  }

  void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  void _log(LogLevel level, String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    if (level.index < _minLogLevel.index) {
      return; // Skip logs below minimum level
    }

    final entry = LogEntry(
      level: level,
      message: message,
      tag: tag,
      timestamp: DateTime.now(),
      error: error,
      stackTrace: stackTrace,
    );

    _logs.add(entry);

    // Keep only last _maxLogs entries
    if (_logs.length > _maxLogs) {
      _logs.removeAt(0);
    }

    // Console logging
    if (_enableConsoleLogging) {
      final prefix = '[${level.name.toUpperCase()}]';
      final tagStr = tag != null ? '[$tag]' : '';
      final timeStr = entry.timestamp.toString().substring(11, 19);
      
      print('$timeStr $prefix $tagStr $message');
      
      if (error != null) {
        print('Error: $error');
      }
      if (stackTrace != null) {
        print('StackTrace: $stackTrace');
      }
    }
  }

  // Get logs
  List<LogEntry> getLogs({LogLevel? minLevel, int? limit}) {
    var filtered = _logs;
    
    if (minLevel != null) {
      filtered = _logs.where((log) => log.level.index >= minLevel.index).toList();
    }
    
    if (limit != null && limit > 0) {
      filtered = filtered.reversed.take(limit).toList().reversed.toList();
    }
    
    return filtered;
  }

  // Get error logs only
  List<LogEntry> getErrorLogs({int? limit}) {
    return getLogs(minLevel: LogLevel.error, limit: limit);
  }

  // Clear logs
  void clearLogs() {
    _logs.clear();
  }

  // Get log count
  int getLogCount({LogLevel? minLevel}) {
    if (minLevel != null) {
      return _logs.where((log) => log.level.index >= minLevel.index).length;
    }
    return _logs.length;
  }

  // Export logs to string
  String exportLogs({LogLevel? minLevel, int? limit}) {
    final logs = getLogs(minLevel: minLevel, limit: limit);
    final buffer = StringBuffer();
    
    for (var log in logs) {
      buffer.writeln(log.toString());
    }
    
    return buffer.toString();
  }
}

enum LogLevel {
  debug,
  info,
  warning,
  error,
}

class LogEntry {
  final LogLevel level;
  final String message;
  final String? tag;
  final DateTime timestamp;
  final Object? error;
  final StackTrace? stackTrace;

  LogEntry({
    required this.level,
    required this.message,
    this.tag,
    required this.timestamp,
    this.error,
    this.stackTrace,
  });

  @override
  String toString() {
    final prefix = '[${level.name.toUpperCase()}]';
    final tagStr = tag != null ? '[$tag]' : '';
    final timeStr = timestamp.toString().substring(11, 19);
    final errorStr = error != null ? ' | Error: $error' : '';
    
    return '$timeStr $prefix $tagStr $message$errorStr';
  }
}

