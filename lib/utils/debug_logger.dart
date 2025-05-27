import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class DebugLogger {
  static final DebugLogger _instance = DebugLogger._internal();
  static DebugLogger get instance => _instance;
  
  File? _logFile;
  bool _isInitialized = false;
  final List<String> _buffer = [];
  
  DebugLogger._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/logs');
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }
      
      final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _logFile = File('${logDir.path}/skillex_$date.log');
      
      if (!await _logFile!.exists()) {
        await _logFile!.create();
      }
      
      _isInitialized = true;
      _buffer.add('Logger initialisé');
      await _flushBuffer();
    } catch (e) {
      _buffer.add('Erreur lors de l\'initialisation du logger: $e');
      await _flushBuffer();
    }
  }

  Future<void> _flushBuffer() async {
    if (_logFile != null) {
      try {
        await _logFile!.writeAsString('${_buffer.join('\n')}\n', mode: FileMode.append);
        _buffer.clear();
      } catch (e) {
        // En cas d'erreur d'écriture, on garde les messages en mémoire
        _buffer.add('Erreur lors de l\'écriture du log: $e');
      }
    }
  }

  Future<void> log(String message, {String? tag, LogLevel level = LogLevel.info}) async {
    if (!_isInitialized) await initialize();
    
    try {
      final timestamp = DateFormat('HH:mm:ss.SSS').format(DateTime.now());
      final logMessage = '[$timestamp][${level.name.toUpperCase()}]${tag != null ? '[$tag]' : ''} $message';
      
      _buffer.add(logMessage);
      await _flushBuffer();
      
      // En mode debug, on peut utiliser assert pour afficher dans la console
      assert(() {
        debugPrint(logMessage);
        return true;
      }());
    } catch (e) {
      _buffer.add('Erreur lors de l\'écriture du log: $e');
      await _flushBuffer();
    }
  }

  Future<void> logError(String message, {String? tag, Object? error, StackTrace? stackTrace}) async {
    final errorMessage = error != null 
        ? '$message\nErreur: $error${stackTrace != null ? '\nStack trace: $stackTrace' : ''}'
        : message;
    await log(errorMessage, tag: tag, level: LogLevel.error);
  }

  Future<void> logWarning(String message, {String? tag}) async {
    await log(message, tag: tag, level: LogLevel.warning);
  }

  Future<void> logInfo(String message, {String? tag}) async {
    await log(message, tag: tag, level: LogLevel.info);
  }

  Future<void> logDebug(String message, {String? tag}) async {
    await log(message, tag: tag, level: LogLevel.debug);
  }

  Future<String> getLogs() async {
    if (!_isInitialized) await initialize();
    try {
      return await _logFile?.readAsString() ?? 'Aucun log disponible';
    } catch (e) {
      return 'Erreur lors de la lecture des logs: $e';
    }
  }

  Future<void> clearLogs() async {
    if (!_isInitialized) await initialize();
    try {
      await _logFile?.writeAsString('');
      await log('Logs effacés');
    } catch (e) {
      _buffer.add('Erreur lors de l\'effacement des logs: $e');
      await _flushBuffer();
    }
  }
}

enum LogLevel {
  debug,
  info,
  warning,
  error
} 