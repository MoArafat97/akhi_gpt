import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../services/admin_proxy_service.dart';

/// Developer/Admin-only page for proxy diagnostics and backend key management
class AdminPage extends StatefulWidget {
  final Color bgColor;
  const AdminPage({super.key, this.bgColor = const Color(0xFFFCF8F1)});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _admin = AdminProxyService.instance;
  bool _loading = false;
  Map<String, dynamic>? _status;
  final _apiKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    setState(() => _loading = true);
    final status = await _admin.getStatus();
    setState(() {
      _status = status;
      _loading = false;
    });
  }

  Future<void> _setBackendKey() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter an API key to set')),
      );
      return;
    }
    setState(() => _loading = true);
    final ok = await _admin.setBackendApiKey(key);
    setState(() => _loading = false);
    if (!mounted) return;
    if (ok) {
      _apiKeyController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.green, content: Text('Backend key updated')),
      );
      await _refreshStatus();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.red, content: Text('Failed to update backend key')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.bgColor,
      appBar: AppBar(
        title: const Text('Admin Tools', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: widget.bgColor.withValues(alpha: 0.9),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loading ? null : _refreshStatus,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: const Color(0xFFFCF8F1),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Proxy Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4F372D))),
                    const SizedBox(height: 8),
                    if (_loading) const LinearProgressIndicator(),
                    if (_status != null) ...[
                      _kv('Health', _status!['health']?.toString() ?? 'unknown'),
                      _kv('Model', _status!['currentModel']?.toString() ?? 'unknown'),
                      _kv('Rate Limit', _status!['rateLimit']?.toString() ?? 'unknown'),
                      _kv('Requests/min', _status!['rpm']?.toString() ?? 'unknown'),
                      _kv('Uptime', _status!['uptime']?.toString() ?? 'unknown'),
                    ] else const Text('No status yet', style: TextStyle(color: Color(0xFF4F372D))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              color: const Color(0xFFFCF8F1),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Backend API Key Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4F372D))),
                    const SizedBox(height: 8),
                    const Text(
                      'Enter a new OpenRouter API key for the proxy backend. This is protected by PROXY_ADMIN_TOKEN and only available in developer mode.',
                      style: TextStyle(color: Color(0xFF4F372D)),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _apiKeyController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'New OpenRouter API Key',
                        labelStyle: TextStyle(color: Color(0xFF4F372D)),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _loading ? null : _setBackendKey,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9C6644),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.vpn_key),
                      label: Text(_loading ? 'Updating...' : 'Set Backend API Key'),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Note: The API key is stored only on the server. The mobile app never stores or displays it.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF4F372D)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            SizedBox(width: 120, child: Text(k, style: const TextStyle(color: Color(0xFF4F372D), fontWeight: FontWeight.w600))),
            Expanded(child: Text(v, style: const TextStyle(color: Color(0xFF4F372D)))),
          ],
        ),
      );
}

