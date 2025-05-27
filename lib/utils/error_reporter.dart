import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'debug_logger.dart';

class ErrorReporter {
  static final ErrorReporter _instance = ErrorReporter._internal();
  static ErrorReporter get instance => _instance;

  static const String _supportEmail = 'dev@mediasystem.cm';
  static const String _errorReportEmail = 'error-skillex@mediasystem.cm';
  
  ErrorReporter._internal();

  Future<void> sendErrorReport({
    required String errorMessage,
    Object? error,
    StackTrace? stackTrace,
    String? additionalInfo,
  }) async {
    try {
      // Collecter les informations système
      final packageInfo = await PackageInfo.fromPlatform();
      final systemInfo = await _collectSystemInfo();
      final logs = await DebugLogger.instance.getLogs();
      
      // Créer le rapport
      final report = _createErrorReport(
        errorMessage: errorMessage,
        error: error,
        stackTrace: stackTrace,
        additionalInfo: additionalInfo,
        packageInfo: packageInfo,
        systemInfo: systemInfo,
        logs: logs,
      );

      // Sauvegarder le rapport localement
      await _saveReportLocally(report);

      // Envoyer le rapport par email
      await _sendReportByEmail(report);

      // Logger l'envoi du rapport
      await DebugLogger.instance.logInfo(
        'Rapport d\'erreur envoyé',
        tag: 'ErrorReporter',
      );
    } catch (e) {
      await DebugLogger.instance.logError(
        'Échec de l\'envoi du rapport d\'erreur',
        tag: 'ErrorReporter',
        error: e,
      );
    }
  }

  Future<Map<String, dynamic>> _collectSystemInfo() async {
    return {
      'platform': Platform.operatingSystem,
      'version': Platform.operatingSystemVersion,
      'locale': Platform.localeName,
      'numberOfProcessors': Platform.numberOfProcessors,
      'localHostname': Platform.localHostname,
      'environment': Platform.environment,
      'memory': await _getMemoryInfo(),
      'diskSpace': await _getDiskSpaceInfo(),
    };
  }

  Future<Map<String, dynamic>> _getMemoryInfo() async {
    if (Platform.isWindows) {
      final result = await Process.run('wmic', ['OS', 'get', 'FreePhysicalMemory,TotalVisibleMemorySize', '/Value']);
      return {'raw': result.stdout};
    } else {
      final result = await Process.run('free', ['-h']);
      return {'raw': result.stdout};
    }
  }

  Future<Map<String, dynamic>> _getDiskSpaceInfo() async {
    final directory = await getApplicationDocumentsDirectory();
    final stat = await directory.stat();
    return {
      'total': stat.size,
      'path': directory.path,
    };
  }

  String _createErrorReport({
    required String errorMessage,
    Object? error,
    StackTrace? stackTrace,
    String? additionalInfo,
    required PackageInfo packageInfo,
    required Map<String, dynamic> systemInfo,
    required String logs,
  }) {
    final buffer = StringBuffer();
    
    buffer.writeln('=== RAPPORT D\'ERREUR SKILLEX ===');
    buffer.writeln('Date: ${DateTime.now().toIso8601String()}');
    buffer.writeln('\n=== INFORMATIONS APPLICATION ===');
    buffer.writeln('Version: ${packageInfo.version}');
    buffer.writeln('Build: ${packageInfo.buildNumber}');
    buffer.writeln('Package: ${packageInfo.packageName}');
    
    buffer.writeln('\n=== ERREUR ===');
    buffer.writeln('Message: $errorMessage');
    if (error != null) buffer.writeln('Erreur: $error');
    if (stackTrace != null) buffer.writeln('Stack trace:\n$stackTrace');
    if (additionalInfo != null) buffer.writeln('Informations supplémentaires:\n$additionalInfo');
    
    buffer.writeln('\n=== SYSTÈME ===');
    buffer.writeln('OS: ${systemInfo['platform']} ${systemInfo['version']}');
    buffer.writeln('Locale: ${systemInfo['locale']}');
    buffer.writeln('Processeurs: ${systemInfo['numberOfProcessors']}');
    buffer.writeln('Hostname: ${systemInfo['localHostname']}');
    
    buffer.writeln('\n=== MÉMOIRE ===');
    buffer.writeln(systemInfo['memory']['raw']);
    
    buffer.writeln('\n=== DISQUE ===');
    buffer.writeln('Chemin: ${systemInfo['diskSpace']['path']}');
    buffer.writeln('Taille totale: ${systemInfo['diskSpace']['total']} bytes');
    
    buffer.writeln('\n=== LOGS ===');
    buffer.writeln(logs);
    
    return buffer.toString();
  }

  Future<void> _saveReportLocally(String report) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final reportsDir = Directory('${directory.path}/error_reports');
      if (!await reportsDir.exists()) {
        await reportsDir.create(recursive: true);
      }
      
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final reportFile = File('${reportsDir.path}/error_report_$timestamp.txt');
      await reportFile.writeAsString(report);
      
      await DebugLogger.instance.logInfo(
        'Rapport sauvegardé localement: ${reportFile.path}',
        tag: 'ErrorReporter',
      );
    } catch (e) {
      await DebugLogger.instance.logError(
        'Échec de la sauvegarde locale du rapport',
        tag: 'ErrorReporter',
        error: e,
      );
    }
  }

  Future<void> _sendReportByEmail(String report) async {
    final subject = Uri.encodeComponent('Rapport d\'erreur Skillex - ${DateTime.now().toIso8601String()}');
    final body = Uri.encodeComponent(report);
    
    // Essayer d'abord d'envoyer au support
    final supportMailtoUrl = 'mailto:$_supportEmail?subject=$subject&body=$body';
    if (await canLaunchUrl(Uri.parse(supportMailtoUrl))) {
      await launchUrl(Uri.parse(supportMailtoUrl));
      return;
    }
    
    // Si l'envoi au support échoue, essayer l'email de rapport d'erreur
    final errorReportMailtoUrl = 'mailto:$_errorReportEmail?subject=$subject&body=$body';
    if (await canLaunchUrl(Uri.parse(errorReportMailtoUrl))) {
      await launchUrl(Uri.parse(errorReportMailtoUrl));
    } else {
      throw Exception('Impossible d\'ouvrir le client mail');
    }
  }
} 