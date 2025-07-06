import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/user_api_key_service.dart';
import '../services/model_management_service.dart';
import '../widgets/api_key_settings_widget.dart';
import '../widgets/model_selection_widget.dart';

class OpenRouterSetupPage extends StatefulWidget {
  final bool isInitialSetup;
  
  const OpenRouterSetupPage({
    super.key,
    this.isInitialSetup = false,
  });

  @override
  State<OpenRouterSetupPage> createState() => _OpenRouterSetupPageState();
}

class _OpenRouterSetupPageState extends State<OpenRouterSetupPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _hasValidApiKey = false;

  @override
  void initState() {
    super.initState();
    _checkApiKeyStatus();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkApiKeyStatus() async {
    final status = await UserApiKeyService.instance.getApiKeyStatus();
    setState(() {
      _hasValidApiKey = status == ApiKeyStatus.valid;
      if (_hasValidApiKey) {
        _currentPage = 1; // Skip to model selection if API key is already set
      }
    });
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _finishSetup() {
    if (widget.isInitialSetup) {
      Navigator.of(context).pushReplacementNamed('/');
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7B4F2F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7B4F2F),
        title: const Text(
          'OpenRouter Setup',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: widget.isInitialSetup 
            ? null 
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                for (int i = 0; i < 3; i++) ...[
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: i <= _currentPage 
                            ? Colors.white 
                            : Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  if (i < 2) const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          
          // Page content
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
              },
              children: [
                _buildWelcomePage(),
                _buildApiKeyPage(),
                _buildModelSelectionPage(),
              ],
            ),
          ),
          
          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (_currentPage > 0)
                  TextButton(
                    onPressed: _previousPage,
                    child: const Text(
                      'Back',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _currentPage == 2 
                      ? _finishSetup
                      : (_currentPage == 0 || _hasValidApiKey) 
                          ? _nextPage 
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF7B4F2F),
                  ),
                  child: Text(
                    _currentPage == 2 
                        ? 'Finish' 
                        : 'Next',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.psychology,
            size: 80,
            color: Colors.white,
          ),
          const SizedBox(height: 24),
          const Text(
            'Welcome to Akhi GPT',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'To get started, you\'ll need to set up your own OpenRouter API key. This gives you full control over your AI conversations and costs.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  'Why your own API key?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '• Full control over your data and privacy\n'
                  '• Choose from 400+ AI models\n'
                  '• Pay only for what you use\n'
                  '• No subscription fees or limits',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () async {
                    const url = 'https://openrouter.ai/docs/quickstart';
                    if (await canLaunchUrl(Uri.parse(url))) {
                      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.info_outline, color: Colors.white),
                  label: const Text(
                    'Learn More',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiKeyPage() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Step 1: Set up your API key',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter your OpenRouter API key to connect to the AI models.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ApiKeySettingsWidget(),
          ),
        ],
      ),
    );
  }

  Widget _buildModelSelectionPage() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Step 2: Choose your AI model',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select the AI model you want to use for conversations.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ModelSelectionWidget(),
          ),
        ],
      ),
    );
  }
}
