import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/user_api_key_service.dart';
import '../utils/error_handler.dart';
import 'model_selection_widget.dart';

class ApiKeySettingsWidget extends StatefulWidget {
  const ApiKeySettingsWidget({super.key});

  @override
  State<ApiKeySettingsWidget> createState() => _ApiKeySettingsWidgetState();
}

class _ApiKeySettingsWidgetState extends State<ApiKeySettingsWidget> {
  final _apiKeyController = TextEditingController();
  final _userApiKeyService = UserApiKeyService.instance;
  
  bool _isLoading = false;
  bool _isValidating = false;
  bool _obscureText = true;
  ApiKeyStatus _currentStatus = ApiKeyStatus.notSet;
  String? _currentApiKey;

  @override
  void initState() {
    super.initState();
    _loadCurrentApiKey();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentApiKey() async {
    setState(() => _isLoading = true);
    
    try {
      final apiKey = await _userApiKeyService.getApiKey();
      final status = await _userApiKeyService.getApiKeyStatus();
      
      if (mounted) {
        setState(() {
          _currentApiKey = apiKey;
          _currentStatus = status;
          if (apiKey != null) {
            _apiKeyController.text = apiKey;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveApiKey() async {
    final apiKey = _apiKeyController.text.trim();
    
    if (apiKey.isEmpty) {
      await _clearApiKey();
      return;
    }

    if (!_userApiKeyService.isValidApiKeyFormat(apiKey)) {
      ErrorHandler.showErrorSnackBar(
        context,
        'Invalid API key format. OpenRouter keys start with "sk-or-v1-"',
      );
      return;
    }

    setState(() {
      _isValidating = true;
    });

    try {
      // Validate the API key
      final validationResult = await _userApiKeyService.validateApiKey(apiKey);
      
      if (validationResult.isValid) {
        // Save the validated key
        await _userApiKeyService.setApiKey(apiKey);
        
        if (mounted) {
          setState(() {
            _currentApiKey = apiKey;
            _currentStatus = ApiKeyStatus.valid;
            _isValidating = false;
          });
          
          ErrorHandler.showSuccessSnackBar(
            context,
            'API key saved and validated successfully! '
            '${validationResult.availableModels ?? 0} models available.',
          );

          // Notify ModelSelectionWidget to refresh
          _notifyModelSelectionWidget();
        }
      } else {
        if (mounted) {
          setState(() {
            _isValidating = false;
          });

          ErrorHandler.showErrorSnackBar(
            context,
            'Validation failed: ${validationResult.error}',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isValidating = false;
        });

        ErrorHandler.showErrorSnackBar(
          context,
          'Failed to validate API key. Please check your internet connection and try again.',
        );
      }
    }
  }

  Future<void> _clearApiKey() async {
    setState(() => _isLoading = true);
    
    try {
      await _userApiKeyService.clearApiKey();
      
      if (mounted) {
        setState(() {
          _currentApiKey = null;
          _currentStatus = ApiKeyStatus.notSet;
          _apiKeyController.clear();
          _isLoading = false;
        });
        
        ErrorHandler.showWarningSnackBar(
          context,
          'API key cleared',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ErrorHandler.showErrorSnackBar(
          context,
          'Failed to clear API key. Please try again.',
        );
      }
    }
  }

  Future<void> _openOpenRouterDocs() async {
    const url = 'https://openrouter.ai/settings/keys';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  /// Notify ModelSelectionWidget to refresh when API key is validated
  void _notifyModelSelectionWidget() {
    // Use a small delay to ensure the API key is fully saved
    Future.delayed(const Duration(milliseconds: 500), () {
      if (modelSelectionWidgetKey.currentState != null) {
        modelSelectionWidgetKey.currentState!.refresh();
      }
    });
  }

  Future<void> _testConnection() async {
    setState(() {
      _isValidating = true;
    });

    try {
      // Test with current API key if available, otherwise test environment configuration
      String? testKey = _apiKeyController.text.trim();
      if (testKey.isEmpty) {
        testKey = null; // This will use environment configuration
      }

      final validationResult = await _userApiKeyService.validateApiKey(testKey);

      if (mounted) {
        setState(() {
          _isValidating = false;
        });

        if (validationResult.isValid) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Connection successful! ${validationResult.availableModels ?? 0} models available.',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Connection failed: ${validationResult.error}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isValidating = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildStatusIndicator() {
    IconData icon;
    Color color;
    String text;

    switch (_currentStatus) {
      case ApiKeyStatus.notSet:
        icon = Icons.key_off;
        color = Colors.red; // Changed to red for better visibility
        text = 'No API key set';
        break;
      case ApiKeyStatus.needsValidation:
        icon = Icons.warning;
        color = Colors.orange;
        text = 'Needs validation';
        break;
      case ApiKeyStatus.valid:
        icon = Icons.check_circle;
        color = Colors.green;
        text = 'Valid and active';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.black.withValues(alpha: 0.3), // Dark background for white text
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _currentStatus == ApiKeyStatus.valid
              ? Colors.green.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.3),
          width: 2, // Thicker border for better visibility
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.vpn_key, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'OpenRouter API Key',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusIndicator(),
              ],
            ),
            const SizedBox(height: 12),
            
            // API Key Input
            TextField(
              controller: _apiKeyController,
              obscureText: _obscureText,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter your OpenRouter API key (sk-or-v1-...)',
                hintStyle: const TextStyle(color: Colors.white54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white54),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white54),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white),
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility : Icons.visibility_off,
                        color: Colors.white54,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    ),
                    if (_apiKeyController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54),
                        onPressed: () {
                          _apiKeyController.clear();
                          setState(() {});
                        },
                      ),
                  ],
                ),
              ),
              onChanged: (value) {
                // Update UI when text changes
                setState(() {});
              },
            ),

            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isValidating ? null : _saveApiKey,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: _isValidating
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Save & Validate'),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isValidating ? null : _testConnection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Test'),
                ),
                const SizedBox(width: 12),
                if (_currentApiKey != null)
                  ElevatedButton(
                    onPressed: _clearApiKey,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Clear'),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Help Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'How to get your API key:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '1. Visit OpenRouter.ai and create an account\n'
                    '2. Go to Settings → API Keys\n'
                    '3. Create a new API key\n'
                    '4. Copy and paste it here',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _openOpenRouterDocs,
                    icon: const Icon(Icons.open_in_new, color: Colors.white),
                    label: const Text(
                      'Get API Key',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
