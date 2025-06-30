import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;
import '../services/diagnostic_service.dart';
import '../services/openrouter_service.dart';

class DiagnosticPage extends StatefulWidget {
  final Color bgColor;

  const DiagnosticPage({super.key, this.bgColor = const Color(0xFF7B4F2F)});

  @override
  State<DiagnosticPage> createState() => _DiagnosticPageState();
}

class _DiagnosticPageState extends State<DiagnosticPage> {
  final DiagnosticService _diagnosticService = DiagnosticService();
  final OpenRouterService _openRouterService = OpenRouterService();
  
  DiagnosticReport? _lastReport;
  bool _isRunning = false;
  String _statusMessage = 'Ready to run diagnostics';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.bgColor,
      appBar: AppBar(
        title: const Text(
          'API Diagnostics',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: widget.bgColor.withValues(alpha: 0.9),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              color: const Color(0xFFFCF8F1), // Light cream background
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getStatusIcon(),
                          color: _getStatusColor(),
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Status: $_statusMessage',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF4F372D), // Dark brown text
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_lastReport != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Overall: ${_lastReport!.overallStatus.name.toUpperCase()}',
                        style: TextStyle(
                          color: _getStatusColor(),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isRunning ? null : _runFullDiagnostics,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9C6644), // Primary brown
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF9C6644).withValues(alpha: 0.5),
                      disabledForegroundColor: Colors.white70,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: _isRunning
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.play_arrow),
                    label: Text(_isRunning ? 'Running...' : 'Run Full Diagnostics'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isRunning ? null : _testConnection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B4F2F), // Secondary brown
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF7B4F2F).withValues(alpha: 0.5),
                    disabledForegroundColor: Colors.white70,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.wifi_tethering),
                  label: const Text('Test Connection'),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isRunning ? null : _testAllModels,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7B4F2F), // Secondary brown
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF7B4F2F).withValues(alpha: 0.5),
                      disabledForegroundColor: Colors.white70,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.model_training),
                    label: const Text('Test All Models'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _lastReport != null ? _copyReport : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9C6644), // Primary brown
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF9C6644).withValues(alpha: 0.3),
                    disabledForegroundColor: Colors.white54,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy Report'),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Results
            Expanded(
              child: _buildResultsView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsView() {
    if (_lastReport == null) {
      return Card(
        color: const Color(0xFFFCF8F1), // Light cream background
        elevation: 4,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'No diagnostics run yet.\nTap "Run Full Diagnostics" to start.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF4F372D), // Dark brown text
                height: 1.5,
              ),
            ),
          ),
        ),
      );
    }

    return Card(
      color: const Color(0xFFFCF8F1), // Light cream background
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Diagnostic Report',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4F372D), // Dark brown text
                ),
              ),
              const SizedBox(height: 16),
              
              _buildCheckSection('Environment Configuration', _lastReport!.environmentCheck.isValid, [
                'API Key Present: ${_lastReport!.environmentCheck.apiKeyPresent ? "✅" : "❌"}',
                'API Key Format: ${_lastReport!.environmentCheck.apiKeyFormat ? "✅" : "❌"}',
                'Default Model: ${_lastReport!.environmentCheck.defaultModelPresent ? "✅" : "❌"}',
                'Fallback Models: ${_lastReport!.environmentCheck.fallbackModelsCount} configured',
                if (_lastReport!.environmentCheck.error != null)
                  'Error: ${_lastReport!.environmentCheck.error}',
              ]),
              
              _buildCheckSection('API Key Validation', _lastReport!.apiKeyValidation.isValid, [
                'Status Code: ${_lastReport!.apiKeyValidation.statusCode ?? "N/A"}',
                'Available Models: ${_lastReport!.apiKeyValidation.availableModels}',
                if (_lastReport!.apiKeyValidation.error != null)
                  'Error: ${_lastReport!.apiKeyValidation.error}',
              ]),
              
              _buildCheckSection('Model Availability', _lastReport!.modelAvailability.isValid, [
                'Available: ${_lastReport!.modelAvailability.availableModels}/${_lastReport!.modelAvailability.totalModels}',
                ..._lastReport!.modelAvailability.modelResults.entries.map((entry) =>
                  '${entry.key}: ${entry.value.isAvailable ? "✅" : "❌"} ${entry.value.error ?? ""}'),
              ]),
              
              _buildCheckSection('Network Connectivity', _lastReport!.networkConnectivity.openRouterReachable, [
                'OpenRouter Reachable: ${_lastReport!.networkConnectivity.openRouterReachable ? "✅" : "❌"}',
                if (_lastReport!.networkConnectivity.responseTime != null)
                  'Response Time: ${_lastReport!.networkConnectivity.responseTime}ms',
                'Status Code: ${_lastReport!.networkConnectivity.statusCode ?? "N/A"}',
                if (_lastReport!.networkConnectivity.error != null)
                  'Error: ${_lastReport!.networkConnectivity.error}',
              ]),
              
              _buildCheckSection('Proxy Configuration', _lastReport!.proxyCheck.isValid, [
                'Enabled: ${_lastReport!.proxyCheck.isEnabled ? "Yes" : "No"}',
                if (_lastReport!.proxyCheck.isEnabled) ...[
                  'Endpoint: ${_lastReport!.proxyCheck.endpoint ?? "Not set"}',
                  'Connectable: ${_lastReport!.proxyCheck.isConnectable ? "✅" : "❌"}',
                ],
                if (_lastReport!.proxyCheck.error != null)
                  'Error: ${_lastReport!.proxyCheck.error}',
              ]),
              
              _buildCheckSection('Fallback Logic', _lastReport!.fallbackLogic.isValid, [
                'Configured Models: ${_lastReport!.fallbackLogic.fallbackModelsConfigured}',
                'Last Working Model: ${_lastReport!.fallbackLogic.lastWorkingModel ?? "None"}',
                'Failure Count: ${_lastReport!.fallbackLogic.failureCount}',
                'Models: ${_lastReport!.fallbackLogic.fallbackModels.join(", ")}',
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckSection(String title, bool isValid, List<String> details) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8E0D8), // Slightly darker cream for sections
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isValid
              ? const Color(0xFF4CAF50) // High contrast green
              : const Color(0xFFE53935), // High contrast red
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isValid ? Icons.check_circle : Icons.error,
                color: isValid
                    ? const Color(0xFF2E7D32) // Darker green for better contrast
                    : const Color(0xFFD32F2F), // Darker red for better contrast
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF4F372D), // Dark brown text
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...details.map((detail) => Padding(
            padding: const EdgeInsets.only(left: 28, bottom: 4),
            child: Text(
              detail,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF4F372D), // Dark brown text
                height: 1.3,
              ),
            ),
          )),
        ],
      ),
    );
  }

  IconData _getStatusIcon() {
    if (_isRunning) return Icons.hourglass_empty;
    if (_lastReport == null) return Icons.help_outline;
    
    switch (_lastReport!.overallStatus) {
      case DiagnosticStatus.healthy:
        return Icons.check_circle;
      case DiagnosticStatus.configurationError:
      case DiagnosticStatus.authenticationError:
      case DiagnosticStatus.networkError:
      case DiagnosticStatus.modelError:
      case DiagnosticStatus.proxyError:
        return Icons.error;
    }
  }

  Color _getStatusColor() {
    if (_isRunning) return const Color(0xFFFF9800); // High contrast orange
    if (_lastReport == null) return const Color(0xFF757575); // High contrast grey

    switch (_lastReport!.overallStatus) {
      case DiagnosticStatus.healthy:
        return const Color(0xFF2E7D32); // High contrast dark green
      case DiagnosticStatus.configurationError:
      case DiagnosticStatus.authenticationError:
      case DiagnosticStatus.networkError:
      case DiagnosticStatus.modelError:
      case DiagnosticStatus.proxyError:
        return const Color(0xFFD32F2F); // High contrast dark red
    }
  }

  Future<void> _runFullDiagnostics() async {
    setState(() {
      _isRunning = true;
      _statusMessage = 'Running comprehensive diagnostics...';
    });

    try {
      developer.log('🔍 Starting full diagnostics from UI', name: 'DiagnosticPage');
      final report = await _diagnosticService.runFullDiagnostics();
      
      setState(() {
        _lastReport = report;
        _statusMessage = 'Diagnostics completed';
        _isRunning = false;
      });
      
      developer.log('🔍 Diagnostics completed: ${report.overallStatus}', name: 'DiagnosticPage');
      
    } catch (e) {
      setState(() {
        _statusMessage = 'Diagnostics failed: $e';
        _isRunning = false;
      });
      
      developer.log('❌ Diagnostics failed: $e', name: 'DiagnosticPage');
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isRunning = true;
      _statusMessage = 'Testing connection...';
    });

    try {
      final success = await _openRouterService.testConnection();
      setState(() {
        _statusMessage = success ? 'Connection successful' : 'Connection failed';
        _isRunning = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Connection test failed: $e';
        _isRunning = false;
      });
    }
  }

  Future<void> _testAllModels() async {
    setState(() {
      _isRunning = true;
      _statusMessage = 'Testing all models...';
    });

    try {
      // final results = await _openRouterService.testAllModels();
      final results = <String, dynamic>{}; // Placeholder for now
      final successCount = results.values.where((success) => success).length;
      
      setState(() {
        _statusMessage = 'Model testing complete: $successCount/${results.length} available';
        _isRunning = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Model testing failed: $e';
        _isRunning = false;
      });
    }
  }

  void _copyReport() {
    if (_lastReport != null) {
      final summary = _lastReport!.generateSummary();
      Clipboard.setData(ClipboardData(text: summary));
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Diagnostic report copied to clipboard',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF4CAF50), // Success green
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
