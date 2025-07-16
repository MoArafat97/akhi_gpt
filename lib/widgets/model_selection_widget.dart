import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/model_management_service.dart';
import '../services/user_api_key_service.dart';

class ModelSelectionWidget extends StatefulWidget {
  const ModelSelectionWidget({super.key});

  @override
  State<ModelSelectionWidget> createState() => _ModelSelectionWidgetState();
}

// Global key to access ModelSelectionWidget from other widgets
final GlobalKey<_ModelSelectionWidgetState> modelSelectionWidgetKey = GlobalKey<_ModelSelectionWidgetState>();

class _ModelSelectionWidgetState extends State<ModelSelectionWidget> with WidgetsBindingObserver {
  final _modelService = ModelManagementService.instance;
  final _apiKeyService = UserApiKeyService.instance;

  List<OpenRouterModel> _availableModels = [];
  List<OpenRouterModel> _filteredModels = [];
  String _selectedModelId = '';
  bool _isLoading = false;
  bool _hasApiKey = false;
  String? _error;

  final _searchController = TextEditingController();
  bool _showFreeOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadInitialData();
    _searchController.addListener(_filterModels);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh when app comes back to foreground in case API key was changed
    if (state == AppLifecycleState.resumed) {
      _checkApiKeyAndRefresh();
    }
  }

  /// Check if API key status has changed and refresh accordingly
  Future<void> _checkApiKeyAndRefresh() async {
    final hasApiKey = await _apiKeyService.hasApiKey();

    if (hasApiKey != _hasApiKey) {
      // API key status changed, refresh the widget
      await _loadInitialData();
    } else if (hasApiKey && _availableModels.isEmpty && _error == null) {
      // Has API key but no models loaded, try to load them
      await _loadModels();
    }
  }

  /// Public method to refresh the widget (can be called from parent widgets)
  Future<void> refresh() async {
    await _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    try {
      // Check if user has API key
      _hasApiKey = await _apiKeyService.hasApiKey();

      if (_hasApiKey) {
        // Load selected model
        _selectedModelId = await _modelService.getSelectedModel();

        // Load available models
        await _loadModels();
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load model data: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadModels({bool forceRefresh = false}) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      if (forceRefresh) _error = null; // Clear error on manual refresh
    });

    try {
      final models = await _modelService.fetchAvailableModels(forceRefresh: forceRefresh);

      if (mounted) {
        setState(() {
          _availableModels = models;
          _error = null;
          _isLoading = false;
        });
        _filterModels();

        // Show success message if this was a manual refresh
        if (forceRefresh && models.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Loaded ${models.length} models successfully'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _formatErrorMessage(e.toString());
          _isLoading = false;
        });

        // Show error snackbar for manual refresh attempts
        if (forceRefresh) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load models: ${_formatErrorMessage(e.toString())}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () => _loadModels(forceRefresh: true),
              ),
            ),
          );
        }
      }
    }
  }

  /// Format error messages to be more user-friendly
  String _formatErrorMessage(String error) {
    if (error.contains('No API key available')) {
      return 'Please set your OpenRouter API key first';
    } else if (error.contains('Invalid API key')) {
      return 'Invalid API key. Please check your OpenRouter API key';
    } else if (error.contains('Network error') || error.contains('Connection timeout')) {
      return 'Network error. Please check your internet connection';
    } else if (error.contains('Rate limit')) {
      return 'Rate limit exceeded. Please try again in a few minutes';
    } else {
      return error.replaceAll('Exception: ', '');
    }
  }

  void _filterModels() {
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      _filteredModels = _availableModels.where((model) {
        final matchesSearch = query.isEmpty ||
            model.name.toLowerCase().contains(query) ||
            model.id.toLowerCase().contains(query) ||
            model.description.toLowerCase().contains(query);
        
        final matchesFreeFilter = !_showFreeOnly || model.isFree;
        
        return matchesSearch && matchesFreeFilter;
      }).toList();
    });
  }

  Future<void> _selectModel(String modelId) async {
    if (!mounted) return;

    // Show loading state
    setState(() {
      _isLoading = true;
    });

    try {
      // First, validate that the model is accessible with the current API key
      final isValid = await _validateModelAccess(modelId);

      if (!isValid) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Model "${_getModelName(modelId)}" is not accessible with your current API key'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      // Model is valid, save the selection
      await _modelService.setSelectedModel(modelId);

      if (mounted) {
        setState(() {
          _selectedModelId = modelId;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Model selected: ${_getModelName(modelId)}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select model: ${_formatErrorMessage(e.toString())}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// Validate that a model is accessible with the current API key
  Future<bool> _validateModelAccess(String modelId) async {
    try {
      final apiKey = await _apiKeyService.getApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        return false;
      }

      // Make a minimal test request to validate model access
      final dio = Dio(BaseOptions(
        baseUrl: 'https://openrouter.ai/api/v1',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
      ));

      final response = await dio.post(
        '/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'HTTP-Referer': 'https://akhi-gpt.app',
            'X-Title': 'Akhi GPT',
          },
        ),
        data: {
          'model': modelId,
          'messages': [
            {'role': 'user', 'content': 'test'}
          ],
          'max_tokens': 1,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      // If it's a rate limit error, consider the model valid
      if (e is DioException && e.response?.statusCode == 429) {
        return true;
      }
      return false;
    }
  }

  String _getModelName(String modelId) {
    final model = _availableModels.firstWhere(
      (m) => m.id == modelId,
      orElse: () => OpenRouterModel(
        id: modelId,
        name: modelId,
        description: '',
        contextLength: 0,
        architecture: ModelArchitecture(
          inputModalities: [],
          outputModalities: [],
          tokenizer: '',
        ),
        pricing: ModelPricing(
          prompt: '0',
          completion: '0',
          request: '0',
          image: '0',
        ),
        supportedParameters: [],
      ),
    );
    return model.name;
  }

  Widget _buildModelTile(OpenRouterModel model) {
    final isSelected = model.id == _selectedModelId;
    
    return Card(
      color: isSelected 
          ? Colors.green.withValues(alpha: 0.2)
          : Colors.white.withValues(alpha: 0.1),
      child: ListTile(
        title: Text(
          model.name,
          style: TextStyle(
            color: const Color(0xFF424242),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              model.id,
              style: const TextStyle(
                color: Color(0xFF666666),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (model.isFree) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'FREE',
                      style: TextStyle(
                        color: const Color(0xFF424242),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  '${(model.contextLength / 1000).toStringAsFixed(0)}K context',
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                if (!model.isFree)
                  Text(
                    model.formattedPricing,
                    style: const TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: Colors.green)
            : null,
        onTap: () => _selectModel(model.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasApiKey) {
      return Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.black.withValues(alpha: 0.3), // Dark background for better contrast
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Colors.orange.withValues(alpha: 0.5), // Orange border to indicate action needed
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.key_off,
                  size: 32,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Model Selection',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF424242),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'API Key Required',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Please set your OpenRouter API key above to view and select from available AI models.',
                style: TextStyle(
                  color: Color(0xFF424242),
                  fontSize: 14,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.psychology, color: Color(0xFF424242)),
                const SizedBox(width: 8),
                const Text(
                  'Model Selection',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF424242),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Color(0xFF424242)),
                  onPressed: _isLoading ? null : () => _loadModels(forceRefresh: true),
                  tooltip: 'Refresh models',
                ),
              ],
            ),
            
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: _isLoading ? null : () => _loadModels(forceRefresh: true),
                          icon: const Icon(Icons.refresh, size: 16, color: Colors.red),
                          label: const Text(
                            'Retry',
                            style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            
            if (_isLoading) ...[
              const SizedBox(height: 20),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Loading available models...',
                  style: TextStyle(color: Color(0xFF666666)),
                ),
              ),
            ] else if (_availableModels.isNotEmpty) ...[
              const SizedBox(height: 16),
              
              // Search and Filter
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Color(0xFF424242)),
                      decoration: InputDecoration(
                        hintText: 'Search models...',
                        hintStyle: const TextStyle(color: Color(0xFF666666)),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF666666)),
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
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilterChip(
                    label: const Text('Free only'),
                    selected: _showFreeOnly,
                    onSelected: (selected) {
                      setState(() {
                        _showFreeOnly = selected;
                      });
                      _filterModels();
                    },
                    selectedColor: Colors.green.withValues(alpha: 0.3),
                    labelStyle: const TextStyle(color: Color(0xFF424242)),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Models List
              Text(
                '${_filteredModels.length} models available',
                style: const TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 14,
                ),
              ),
              
              const SizedBox(height: 8),
              
              SizedBox(
                height: 300,
                child: ListView.builder(
                  itemCount: _filteredModels.length,
                  itemBuilder: (context, index) {
                    return _buildModelTile(_filteredModels[index]);
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
