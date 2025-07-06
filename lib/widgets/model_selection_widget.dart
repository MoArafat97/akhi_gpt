import 'package:flutter/material.dart';
import '../services/model_management_service.dart';
import '../services/user_api_key_service.dart';

class ModelSelectionWidget extends StatefulWidget {
  const ModelSelectionWidget({super.key});

  @override
  State<ModelSelectionWidget> createState() => _ModelSelectionWidgetState();
}

class _ModelSelectionWidgetState extends State<ModelSelectionWidget> {
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
    _loadInitialData();
    _searchController.addListener(_filterModels);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    try {
      final models = await _modelService.fetchAvailableModels(forceRefresh: forceRefresh);
      
      if (mounted) {
        setState(() {
          _availableModels = models;
          _error = null;
        });
        _filterModels();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
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
    try {
      await _modelService.setSelectedModel(modelId);
      
      if (mounted) {
        setState(() {
          _selectedModelId = modelId;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Model selected: ${_getModelName(modelId)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select model: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              model.id,
              style: const TextStyle(
                color: Colors.white70,
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
                        color: Colors.white,
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
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                if (!model.isFree)
                  Text(
                    model.formattedPricing,
                    style: const TextStyle(
                      color: Colors.white70,
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(
                Icons.key_off,
                size: 48,
                color: Colors.white54,
              ),
              const SizedBox(height: 16),
              const Text(
                'API Key Required',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please set your OpenRouter API key first to view and select models.',
                style: TextStyle(
                  color: Colors.white70,
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
                const Icon(Icons.psychology, color: Colors.white),
                const SizedBox(width: 8),
                const Text(
                  'Model Selection',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
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
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
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
                  style: TextStyle(color: Colors.white70),
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
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search models...',
                        hintStyle: const TextStyle(color: Colors.white54),
                        prefixIcon: const Icon(Icons.search, color: Colors.white54),
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
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Models List
              Text(
                '${_filteredModels.length} models available',
                style: const TextStyle(
                  color: Colors.white70,
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
