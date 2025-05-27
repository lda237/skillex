import 'dart:io';
import 'package:skillex/utils/debug_logger.dart';

class EnvironmentChecker {
  static Future<void> checkEnvironment() async {
    final logger = DebugLogger.instance;
    await logger.initialize();
    
    await logger.logInfo('🔍 Vérification de l\'environnement Skillex...\n');

    // Vérifier Java
    await _checkJava();
    
    // Vérifier Flutter
    await _checkFlutter();
    
    // Vérifier les variables d'environnement
    await _checkEnvironmentVariables();
    
    // Vérifier l'espace disque
    await _checkDiskSpace();
    
    // Vérifier la mémoire
    await _checkMemory();
    
    await logger.logInfo('\n✅ Vérification terminée');
  }

  static Future<void> _checkJava() async {
    final logger = DebugLogger.instance;
    await logger.logInfo('📦 Vérification de Java...');
    try {
      final result = await Process.run('java', ['-version']);
      await logger.logInfo('Version Java: ${result.stderr}');
      
      if (result.stderr.toString().contains('version "24')) {
        await logger.logInfo('✅ Java 24 détecté');
      } else {
        await logger.logWarning('⚠️ Version Java non standard détectée');
      }
    } catch (e) {
      await logger.logError('❌ Erreur lors de la vérification de Java', error: e);
    }
  }

  static Future<void> _checkFlutter() async {
    final logger = DebugLogger.instance;
    await logger.logInfo('\n📱 Vérification de Flutter...');
    try {
      final result = await Process.run('flutter', ['doctor', '-v']);
      await logger.logInfo(result.stdout);
    } catch (e) {
      await logger.logError('❌ Erreur lors de la vérification de Flutter', error: e);
    }
  }

  static Future<void> _checkEnvironmentVariables() async {
    final logger = DebugLogger.instance;
    await logger.logInfo('\n🔧 Vérification des variables d\'environnement...');
    final envVars = Platform.environment;
    
    if (envVars.containsKey('JAVA_HOME')) {
      await logger.logInfo('✅ JAVA_HOME: ${envVars['JAVA_HOME']}');
    } else {
      await logger.logWarning('❌ JAVA_HOME non défini');
    }
    
    if (envVars.containsKey('ANDROID_HOME')) {
      await logger.logInfo('✅ ANDROID_HOME: ${envVars['ANDROID_HOME']}');
    } else {
      await logger.logWarning('❌ ANDROID_HOME non défini');
    }
  }

  static Future<void> _checkDiskSpace() async {
    final logger = DebugLogger.instance;
    await logger.logInfo('\n💾 Vérification de l\'espace disque...');
    try {
      final directory = Directory.current;
      final stat = await directory.stat();
      final freeSpace = await _getFreeDiskSpace(directory.path);
      
      await logger.logInfo('Espace libre: ${(freeSpace / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB');
      await logger.logInfo('Espace total: ${(stat.size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB');
    } catch (e) {
      await logger.logError('❌ Erreur lors de la vérification de l\'espace disque', error: e);
    }
  }

  static Future<void> _checkMemory() async {
    final logger = DebugLogger.instance;
    await logger.logInfo('\n🧠 Vérification de la mémoire...');
    try {
      if (Platform.isWindows) {
        final result = await Process.run('wmic', ['OS', 'get', 'FreePhysicalMemory,TotalVisibleMemorySize', '/Value']);
        await logger.logInfo(result.stdout);
      } else {
        final result = await Process.run('free', ['-h']);
        await logger.logInfo(result.stdout);
      }
    } catch (e) {
      await logger.logError('❌ Erreur lors de la vérification de la mémoire', error: e);
    }
  }

  static Future<int> _getFreeDiskSpace(String path) async {
    if (Platform.isWindows) {
      final result = await Process.run('wmic', ['logicaldisk', 'get', 'freespace,caption']);
      final lines = result.stdout.toString().split('\n');
      for (var line in lines) {
        if (line.contains(path[0])) {
          final parts = line.trim().split(RegExp(r'\s+'));
          if (parts.length >= 2) {
            return int.tryParse(parts[1]) ?? 0;
          }
        }
      }
      return 0;
    } else {
      final result = await Process.run('df', ['-k', path]);
      final lines = result.stdout.toString().split('\n');
      if (lines.length >= 2) {
        final parts = lines[1].trim().split(RegExp(r'\s+'));
        if (parts.length >= 4) {
          return int.tryParse(parts[3]) ?? 0;
        }
      }
      return 0;
    }
  }
} 