import 'package:flutter/material.dart';
import '../services/terms_acceptance_service.dart';

class TermsConditionsPage extends StatefulWidget {
  final bool isMandatory;

  const TermsConditionsPage({Key? key, this.isMandatory = false}) : super(key: key);

  @override
  State<TermsConditionsPage> createState() => _TermsConditionsPageState();
}

class _TermsConditionsPageState extends State<TermsConditionsPage> {
  bool _acknowledgedNotTherapy = false;
  bool _acknowledgedProfessionalHelp = false;
  bool _acknowledgedIslamicDisclaimer = false;
  bool _acknowledgedDataUsage = false;
  bool _acknowledgedAgeRequirement = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevent back navigation if this is mandatory acceptance
        if (widget.isMandatory) {
          _showExitConfirmation(context);
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFCF8F1), // Cream background
        appBar: AppBar(
          title: const Text(
            'Terms & Conditions',
            style: TextStyle(
              color: Color(0xFFFCF8F1),
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: const Color(0xFF2C5530),
          elevation: 0,
          iconTheme: const IconThemeData(color: Color(0xFFFCF8F1)),
          automaticallyImplyLeading: !widget.isMandatory, // Hide back button if mandatory
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (widget.isMandatory) _buildMandatoryHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _buildTermsContent(),
                ),
              ),
              if (widget.isMandatory) _buildMandatoryAcceptanceButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMandatoryHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2C5530).withOpacity(0.08),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF2C5530).withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2C5530),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.gavel,
              color: Color(0xFFFCF8F1),
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Terms & Conditions Required',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C5530),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You must accept these terms to use Nafs AI',
            style: TextStyle(
              fontSize: 15,
              color: const Color(0xFF4F372D).withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMandatoryAcceptanceButtons(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        maxHeight: 400, // Prevent overflow on small screens
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFCF8F1),
        border: Border(
          top: BorderSide(
            color: const Color(0xFF2C5530).withOpacity(0.1),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
        children: [
          // Mandatory acknowledgment checkboxes
          _buildAcknowledgmentCheckbox(
            'I understand this app is NOT professional therapy or medical treatment',
            _acknowledgedNotTherapy,
            (value) => setState(() => _acknowledgedNotTherapy = value ?? false),
          ),
          _buildAcknowledgmentCheckbox(
            'I will seek professional help for serious mental health issues',
            _acknowledgedProfessionalHelp,
            (value) => setState(() => _acknowledgedProfessionalHelp = value ?? false),
          ),
          _buildAcknowledgmentCheckbox(
            'I understand this provides Islamic perspective, not religious rulings',
            _acknowledgedIslamicDisclaimer,
            (value) => setState(() => _acknowledgedIslamicDisclaimer = value ?? false),
          ),
          _buildAcknowledgmentCheckbox(
            'I understand how my data is used and stored',
            _acknowledgedDataUsage,
            (value) => setState(() => _acknowledgedDataUsage = value ?? false),
          ),
          _buildAcknowledgmentCheckbox(
            'I confirm I am at least 13 years old',
            _acknowledgedAgeRequirement,
            (value) => setState(() => _acknowledgedAgeRequirement = value ?? false),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _handleDecline(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC3545),
                    foregroundColor: const Color(0xFFFCF8F1),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    shadowColor: const Color(0xFFDC3545).withOpacity(0.3),
                  ),
                  child: const Text(
                    'Decline',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: (_canAccept() && !_isLoading) ? () => _handleAccept(context) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C5530),
                    foregroundColor: const Color(0xFFFCF8F1),
                    disabledBackgroundColor: const Color(0xFF2C5530).withOpacity(0.4),
                    disabledForegroundColor: const Color(0xFFFCF8F1).withOpacity(0.6),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: _canAccept() ? 3 : 0,
                    shadowColor: const Color(0xFF2C5530).withOpacity(0.3),
                  ),
                  child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFCF8F1)),
                        ),
                      )
                    : const Text(
                        'Accept & Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                ),
              ),
            ],
          ),
        ],
        ),
      ),
    );
  }

  bool _canAccept() {
    return _acknowledgedNotTherapy &&
           _acknowledgedProfessionalHelp &&
           _acknowledgedIslamicDisclaimer &&
           _acknowledgedDataUsage &&
           _acknowledgedAgeRequirement;
  }

  Future<void> _handleAccept(BuildContext context) async {
    setState(() => _isLoading = true);

    try {
      await TermsAcceptanceService.acceptTerms();

      if (mounted) {
        // Navigate to main app
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/card_navigation',
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog(context, 'Failed to save acceptance. Please try again.');
      }
    }
  }

  void _handleDecline(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFCF8F1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Terms Required',
            style: TextStyle(
              color: Color(0xFF2C5530),
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: const Text(
            'You must accept the Terms and Conditions to use Nafs AI. '
            'Without acceptance, you cannot access the app\'s features.',
            style: TextStyle(
              color: Color(0xFF4F372D),
              fontSize: 15,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2C5530),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text(
                'Review Again',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _exitApp();
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFDC3545),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text(
                'Exit App',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFCF8F1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Exit App?',
            style: TextStyle(
              color: Color(0xFF2C5530),
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: const Text(
            'You must accept the Terms and Conditions to use Nafs AI. '
            'Do you want to exit the app?',
            style: TextStyle(
              color: Color(0xFF4F372D),
              fontSize: 15,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2C5530),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text(
                'Stay',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _exitApp();
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFDC3545),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text(
                'Exit',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFCF8F1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Error',
            style: TextStyle(
              color: Color(0xFFDC3545),
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: Color(0xFF4F372D),
              fontSize: 15,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2C5530),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text(
                'OK',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  void _exitApp() {
    // Close the app
    Navigator.of(context).pop();
  }

  void _showCompleteTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog.fullscreen(
          backgroundColor: const Color(0xFFFCF8F1),
          child: Scaffold(
            backgroundColor: const Color(0xFFFCF8F1),
            appBar: AppBar(
              title: const Text(
                'Complete Terms & Conditions',
                style: TextStyle(
                  color: Color(0xFFFCF8F1),
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: const Color(0xFF2C5530),
              elevation: 0,
              iconTheme: const IconThemeData(color: Color(0xFFFCF8F1)),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildCompleteTermsContent(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTermsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF2C5530).withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF2C5530).withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Terms and Conditions',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C5530),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Last updated: ${TermsAcceptanceService.getCurrentTermsVersion()}',
                style: TextStyle(
                  fontSize: 13,
                  color: const Color(0xFF4F372D).withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // View Complete Terms Button
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 24),
          child: ElevatedButton.icon(
            onPressed: () => _showCompleteTermsDialog(context),
            icon: const Icon(Icons.article_outlined, size: 20),
            label: const Text(
              'View Complete Terms & Conditions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C5530),
              foregroundColor: const Color(0xFFFCF8F1),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              shadowColor: const Color(0xFF2C5530).withOpacity(0.3),
            ),
          ),
        ),

        const SizedBox(height: 8),

        _buildSection(
          'Acceptance of Terms',
          'By downloading, installing, accessing, or using the Nafs AI mobile application ("App"), you agree to be bound by these Terms and Conditions ("Terms"). These Terms constitute a legally binding agreement between you ("User," "you," or "your") and the developers of Nafs AI ("we," "us," or "our").\n\n'
          'If you do not agree to all the terms and conditions of this agreement, then you may not access the App or use any services. If these Terms are considered an offer, acceptance is expressly limited to these Terms.\n\n'
          'Your access to and use of the App is conditioned on your acceptance of and compliance with these Terms. These Terms apply to all visitors, users, and others who access or use the App.',
        ),

        _buildSection(
          'Description of Service',
          'Nafs AI is an artificial intelligence-powered conversational assistant designed to provide supportive dialogue, guidance, and companionship from an Islamic perspective. The App utilizes advanced AI technology to engage in conversations about mental health, spiritual guidance, daily life challenges, and general support.\n\n'
          'IMPORTANT DISCLAIMERS - This service is NOT and does not provide:\n\n'
          '• Professional therapy, counseling, or medical treatment\n'
          '• Official religious rulings (fatwas) or authoritative Islamic jurisprudence\n'
          '• A substitute for professional mental health care or medical advice\n'
          '• Medical, legal, financial, or professional advice of any kind\n'
          '• Crisis intervention or emergency mental health services\n'
          '• Treatment for serious mental health conditions or psychiatric disorders\n\n'
          'The App is designed for general support, companionship, and educational purposes only. All responses are generated by artificial intelligence and should not be considered as professional advice or authoritative religious guidance.',
        ),

        _buildSection(
          'User Eligibility and Responsibilities',
          'By using this App, you represent and warrant that:\n\n'
          '• You are at least 13 years of age\n'
          '• You have the legal capacity to enter into this agreement\n'
          '• You will use the App in compliance with all applicable laws and regulations\n'
          '• You will not use the App for any unlawful or prohibited purpose\n\n'
          'You agree to:\n\n'
          '• Use the service responsibly, ethically, and in good faith\n'
          '• Seek professional help for serious mental health issues, medical concerns, or crisis situations\n'
          '• Not rely solely on AI-generated responses for important life decisions\n'
          '• Respect the Islamic values and principles underlying the service\n'
          '• Not attempt to circumvent any security measures or access restrictions\n'
          '• Not use the App to harm, harass, or violate the rights of others\n'
          '• Not share inappropriate, offensive, or harmful content\n'
          '• Understand that AI responses are not infallible and may contain errors\n'
          '• Take personal responsibility for your actions and decisions',
        ),

        _buildSection(
          'Data Collection and Privacy',
          'We collect and process certain information to provide and improve our services:\n\n'
          'INFORMATION WE COLLECT:\n'
          '• Chat messages and conversation history for AI processing and service delivery\n'
          '• Device information (device type, operating system, app version)\n'
          '• Usage analytics and app performance data\n'
          '• Technical logs for debugging and service improvement\n'
          '• User preferences and settings\n\n'
          'HOW WE USE YOUR DATA:\n'
          '• To provide AI-powered conversational responses\n'
          '• To improve the quality and accuracy of our AI models\n'
          '• To analyze usage patterns and enhance user experience\n'
          '• To ensure app security and prevent misuse\n'
          '• To provide technical support when needed\n\n'
          'DATA SECURITY:\n'
          'We implement appropriate technical and organizational measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction. However, no method of transmission over the internet or electronic storage is 100% secure.\n\n'
          'DATA RETENTION:\n'
          'We retain your data only as long as necessary to provide our services and comply with legal obligations. You may request deletion of your data by contacting us.\n\n'
          'Your privacy is important to us. For detailed information about our data practices, please review our Privacy Policy.',
        ),

        _buildSection(
          'Islamic Perspective and Religious Disclaimer',
          'IMPORTANT RELIGIOUS DISCLAIMER:\n\n'
          'The Islamic guidance, perspectives, and references provided by this App are based on general Islamic principles and common interpretations. However, you must understand and acknowledge that:\n\n'
          '• This App does NOT provide official religious rulings (fatwas)\n'
          '• Responses are NOT authoritative Islamic jurisprudence\n'
          '• The AI is NOT a qualified Islamic scholar or religious authority\n'
          '• Content should NOT be considered as definitive religious guidance\n\n'
          'SEEKING PROPER RELIGIOUS GUIDANCE:\n'
          'For specific religious questions, matters of Islamic law (fiqh), or authoritative religious rulings, you must consult:\n'
          '• Qualified Islamic scholars\n'
          '• Recognized religious authorities\n'
          '• Established Islamic institutions\n'
          '• Local mosques and Islamic centers\n\n'
          'The App aims to provide general Islamic perspective and support based on widely accepted Islamic values such as compassion, patience, gratitude, and seeking Allah\'s guidance. However, it cannot replace proper religious education or consultation with qualified scholars.\n\n'
          'We respect the diversity of Islamic thought and interpretation across different schools of jurisprudence (madhabs) and cultural contexts.',
        ),

        _buildSection(
          'Mental Health and Medical Disclaimers',
          'CRITICAL MENTAL HEALTH DISCLAIMER:\n\n'
          'This App is NOT a substitute for professional mental health care. You acknowledge and understand that:\n\n'
          '• The App does NOT provide therapy, counseling, or medical treatment\n'
          '• AI responses are NOT professional mental health advice\n'
          '• The App cannot diagnose, treat, or cure any mental health condition\n'
          '• The App is NOT designed for crisis intervention or emergency situations\n\n'
          'WHEN TO SEEK PROFESSIONAL HELP:\n'
          'You must seek immediate professional help if you experience:\n'
          '• Thoughts of self-harm or suicide\n'
          '• Severe depression, anxiety, or other mental health symptoms\n'
          '• Substance abuse or addiction issues\n'
          '• Domestic violence or abuse situations\n'
          '• Any mental health crisis or emergency\n\n'
          'EMERGENCY CONTACTS:\n'
          'In case of mental health emergency, contact:\n'
          '• Emergency services (911 in US, 999 in UK, or local emergency number)\n'
          '• National Suicide Prevention Lifeline\n'
          '• Local crisis intervention services\n'
          '• Your healthcare provider or mental health professional\n\n'
          'The App is designed to provide general support and companionship, but it cannot replace professional mental health care, medical treatment, or crisis intervention services.',
        ),

        _buildSection(
          'Limitation of Liability and Disclaimers',
          'TO THE FULLEST EXTENT PERMITTED BY LAW:\n\n'
          'DISCLAIMER OF WARRANTIES:\n'
          '• The App is provided "AS IS" and "AS AVAILABLE" without warranties of any kind\n'
          '• We make no representations about the accuracy, reliability, or completeness of AI responses\n'
          '• We do not warrant that the App will be uninterrupted, secure, or error-free\n'
          '• We disclaim all warranties, express or implied, including merchantability and fitness for a particular purpose\n\n'
          'LIMITATION OF LIABILITY:\n'
          '• We shall not be liable for any direct, indirect, incidental, special, or consequential damages\n'
          '• This includes damages arising from your use of or inability to use the App\n'
          '• We are not responsible for decisions made based on AI-generated responses\n'
          '• Users assume full responsibility for their actions and decisions\n'
          '• Our total liability shall not exceed the amount paid by you for the App (if any)\n\n'
          'USER RESPONSIBILITY:\n'
          'You acknowledge that:\n'
          '• You use the App at your own risk and discretion\n'
          '• You are solely responsible for your interactions with the AI\n'
          '• You will not hold us liable for any consequences of your use of the App\n'
          '• You understand the limitations of AI technology and its potential for errors\n\n'
          'Some jurisdictions do not allow the exclusion of certain warranties or limitation of liability, so some of the above limitations may not apply to you.',
        ),

        _buildSection(
          'Prohibited Uses and User Conduct',
          'You agree NOT to use the App for any of the following prohibited purposes:\n\n'
          'PROHIBITED ACTIVITIES:\n'
          '• Violating any applicable laws or regulations\n'
          '• Harassing, threatening, or intimidating others\n'
          '• Sharing inappropriate, offensive, or harmful content\n'
          '• Attempting to hack, reverse engineer, or compromise the App\n'
          '• Using the App for commercial purposes without authorization\n'
          '• Impersonating others or providing false information\n'
          '• Distributing malware, viruses, or other harmful code\n'
          '• Attempting to gain unauthorized access to our systems\n'
          '• Using the App to promote illegal activities\n'
          '• Violating the intellectual property rights of others\n\n'
          'CONTENT GUIDELINES:\n'
          'When interacting with the AI, you agree to:\n'
          '• Be respectful and considerate in your communications\n'
          '• Avoid sharing personal information of others without consent\n'
          '• Not attempt to manipulate or "jailbreak" the AI system\n'
          '• Report any technical issues or inappropriate AI responses\n\n'
          'We reserve the right to suspend or terminate access for users who violate these guidelines.',
        ),

        _buildSection(
          'Intellectual Property Rights',
          'OWNERSHIP:\n'
          '• The App, including its design, code, AI models, and content, is owned by us and protected by intellectual property laws\n'
          '• All trademarks, service marks, and logos used in the App are our property or used with permission\n'
          '• You do not acquire any ownership rights in the App or its content\n\n'
          'USER CONTENT:\n'
          '• You retain ownership of the messages and content you submit to the App\n'
          '• By using the App, you grant us a license to process your messages for service delivery\n'
          '• We may use anonymized and aggregated data to improve our services\n'
          '• You represent that you have the right to share any content you submit\n\n'
          'RESTRICTIONS:\n'
          'You may not:\n'
          '• Copy, modify, or distribute the App or its content\n'
          '• Create derivative works based on the App\n'
          '• Use our trademarks or branding without permission\n'
          '• Reverse engineer or attempt to extract source code',
        ),

        _buildSection(
          'Termination and Account Suspension',
          'TERMINATION BY YOU:\n'
          '• You may stop using the App at any time\n'
          '• You may request deletion of your data by contacting us\n'
          '• Uninstalling the App does not automatically delete your data from our servers\n\n'
          'TERMINATION BY US:\n'
          'We reserve the right to:\n'
          '• Suspend or terminate your access to the App at any time\n'
          '• Remove or disable access for violations of these Terms\n'
          '• Discontinue the App or any features with or without notice\n'
          '• Modify or update the App\'s functionality\n\n'
          'EFFECT OF TERMINATION:\n'
          '• Upon termination, your right to use the App ceases immediately\n'
          '• We may retain certain data as required by law or for legitimate business purposes\n'
          '• Provisions regarding liability, disclaimers, and intellectual property survive termination',
        ),

        _buildSection(
          'Updates and Modifications',
          'APP UPDATES:\n'
          '• We may release updates, patches, or new versions of the App\n'
          '• Updates may include new features, bug fixes, or security improvements\n'
          '• Some updates may be required for continued use of the App\n'
          '• We are not obligated to provide updates or maintain backward compatibility\n\n'
          'TERMS MODIFICATIONS:\n'
          '• We reserve the right to modify these Terms at any time\n'
          '• Material changes will be communicated through the App or other appropriate means\n'
          '• Continued use of the App after changes constitutes acceptance of new Terms\n'
          '• If you disagree with changes, you must stop using the App\n\n'
          'SERVICE CHANGES:\n'
          '• We may modify, suspend, or discontinue any aspect of the App\n'
          '• Features may be added, removed, or changed without prior notice\n'
          '• We are not liable for any modifications or discontinuation of services',
        ),

        _buildSection(
          'Governing Law and Dispute Resolution',
          'GOVERNING LAW:\n'
          '• These Terms are governed by the laws of [Jurisdiction to be specified]\n'
          '• Any disputes will be resolved in accordance with applicable law\n'
          '• You agree to submit to the jurisdiction of competent courts\n\n'
          'DISPUTE RESOLUTION:\n'
          '• We encourage resolving disputes through direct communication first\n'
          '• For formal disputes, you agree to binding arbitration where permitted by law\n'
          '• Class action lawsuits are waived to the extent permitted by law\n'
          '• Some jurisdictions may not allow certain limitations, so they may not apply to you\n\n'
          'SEVERABILITY:\n'
          '• If any provision of these Terms is found unenforceable, the remainder remains in effect\n'
          '• Invalid provisions will be modified to the minimum extent necessary to make them valid',
        ),

        _buildSection(
          'Contact Information and Support',
          'If you have questions about these Terms and Conditions, need technical support, or want to report issues:\n\n'
          'CONTACT METHODS:\n'
          '• Email: [Contact email to be specified]\n'
          '• In-app support features (if available)\n'
          '• Official website or support portal\n\n'
          'SUPPORT SCOPE:\n'
          '• Technical issues and bug reports\n'
          '• Questions about app functionality\n'
          '• Privacy and data concerns\n'
          '• Terms and conditions clarifications\n\n'
          'RESPONSE TIME:\n'
          '• We strive to respond to inquiries in a timely manner\n'
          '• Response times may vary based on the nature and complexity of your request\n'
          '• For urgent technical issues, please use the most direct contact method available\n\n'
          'Please note that our support team cannot provide medical advice, religious rulings, or professional counseling services.',
        ),

        _buildSection(
          'Final Provisions',
          'ENTIRE AGREEMENT:\n'
          '• These Terms, together with our Privacy Policy, constitute the entire agreement between you and us\n'
          '• These Terms supersede any prior agreements or understandings\n'
          '• No oral or written statements outside these Terms modify this agreement\n\n'
          'WAIVER:\n'
          '• Our failure to enforce any provision does not constitute a waiver of that provision\n'
          '• Waivers must be in writing to be effective\n'
          '• No waiver of any breach constitutes a waiver of any subsequent breach\n\n'
          'ASSIGNMENT:\n'
          '• You may not assign or transfer your rights under these Terms\n'
          '• We may assign our rights and obligations to any party\n'
          '• These Terms bind and benefit the parties and their successors\n\n'
          'ACKNOWLEDGMENT:\n'
          'By using Nafs AI, you acknowledge that you have read, understood, and agree to be bound by these Terms and Conditions. You also acknowledge that you have read and understood our Privacy Policy.\n\n'
          'These Terms are effective as of the date you first use the App and remain in effect until terminated in accordance with these Terms.',
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildCompleteTermsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF2C5530).withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF2C5530).withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Terms and Conditions',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C5530),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Last updated: ${TermsAcceptanceService.getCurrentTermsVersion()}',
                style: TextStyle(
                  fontSize: 13,
                  color: const Color(0xFF4F372D).withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C5530),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Complete Version',
                  style: TextStyle(
                    color: Color(0xFFFCF8F1),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // All sections with complete content
        _buildCompleteSection(
          'Acceptance of Terms',
          'By downloading, installing, accessing, or using the Nafs AI mobile application ("App"), you agree to be bound by these Terms and Conditions ("Terms"). These Terms constitute a legally binding agreement between you ("User," "you," or "your") and the developers of Nafs AI ("we," "us," or "our").\n\n'
          'If you do not agree to all the terms and conditions of this agreement, then you may not access the App or use any services. If these Terms are considered an offer, acceptance is expressly limited to these Terms.\n\n'
          'Your access to and use of the App is conditioned on your acceptance of and compliance with these Terms. These Terms apply to all visitors, users, and others who access or use the App.',
        ),

        _buildCompleteSection(
          'Description of Service',
          'Nafs AI is an artificial intelligence-powered conversational assistant designed to provide supportive dialogue, guidance, and companionship from an Islamic perspective. The App utilizes advanced AI technology to engage in conversations about mental health, spiritual guidance, daily life challenges, and general support.\n\n'
          'IMPORTANT DISCLAIMERS - This service is NOT and does not provide:\n\n'
          '• Professional therapy, counseling, or medical treatment\n'
          '• Official religious rulings (fatwas) or authoritative Islamic jurisprudence\n'
          '• A substitute for professional mental health care or medical advice\n'
          '• Medical, legal, financial, or professional advice of any kind\n'
          '• Crisis intervention or emergency mental health services\n'
          '• Treatment for serious mental health conditions or psychiatric disorders\n\n'
          'The App is designed for general support, companionship, and educational purposes only. All responses are generated by artificial intelligence and should not be considered as professional advice or authoritative religious guidance.',
        ),

        _buildCompleteSection(
          'User Eligibility and Responsibilities',
          'By using this App, you represent and warrant that:\n\n'
          '• You are at least 13 years of age\n'
          '• You have the legal capacity to enter into this agreement\n'
          '• You will use the App in compliance with all applicable laws and regulations\n'
          '• You will not use the App for any unlawful or prohibited purpose\n\n'
          'You agree to:\n\n'
          '• Use the service responsibly, ethically, and in good faith\n'
          '• Seek professional help for serious mental health issues, medical concerns, or crisis situations\n'
          '• Not rely solely on AI-generated responses for important life decisions\n'
          '• Respect the Islamic values and principles underlying the service\n'
          '• Not attempt to circumvent any security measures or access restrictions\n'
          '• Not use the App to harm, harass, or violate the rights of others\n'
          '• Not share inappropriate, offensive, or harmful content\n'
          '• Understand that AI responses are not infallible and may contain errors\n'
          '• Take personal responsibility for your actions and decisions',
        ),

        _buildCompleteSection(
          'Data Collection and Privacy',
          'We collect and process certain information to provide and improve our services:\n\n'
          'INFORMATION WE COLLECT:\n'
          '• Chat messages and conversation history for AI processing and service delivery\n'
          '• Device information (device type, operating system, app version)\n'
          '• Usage analytics and app performance data\n'
          '• Technical logs for debugging and service improvement\n'
          '• User preferences and settings\n\n'
          'HOW WE USE YOUR DATA:\n'
          '• To provide AI-powered conversational responses\n'
          '• To improve the quality and accuracy of our AI models\n'
          '• To analyze usage patterns and enhance user experience\n'
          '• To ensure app security and prevent misuse\n'
          '• To provide technical support when needed\n\n'
          'DATA SECURITY:\n'
          'We implement appropriate technical and organizational measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction. However, no method of transmission over the internet or electronic storage is 100% secure.\n\n'
          'DATA RETENTION:\n'
          'We retain your data only as long as necessary to provide our services and comply with legal obligations. You may request deletion of your data by contacting us.\n\n'
          'Your privacy is important to us. For detailed information about our data practices, please review our Privacy Policy.',
        ),

        _buildCompleteSection(
          'Islamic Perspective and Religious Disclaimer',
          'IMPORTANT RELIGIOUS DISCLAIMER:\n\n'
          'The Islamic guidance, perspectives, and references provided by this App are based on general Islamic principles and common interpretations. However, you must understand and acknowledge that:\n\n'
          '• This App does NOT provide official religious rulings (fatwas)\n'
          '• Responses are NOT authoritative Islamic jurisprudence\n'
          '• The AI is NOT a qualified Islamic scholar or religious authority\n'
          '• Content should NOT be considered as definitive religious guidance\n\n'
          'SEEKING PROPER RELIGIOUS GUIDANCE:\n'
          'For specific religious questions, matters of Islamic law (fiqh), or authoritative religious rulings, you must consult:\n'
          '• Qualified Islamic scholars\n'
          '• Recognized religious authorities\n'
          '• Established Islamic institutions\n'
          '• Local mosques and Islamic centers\n\n'
          'The App aims to provide general Islamic perspective and support based on widely accepted Islamic values such as compassion, patience, gratitude, and seeking Allah\'s guidance. However, it cannot replace proper religious education or consultation with qualified scholars.\n\n'
          'We respect the diversity of Islamic thought and interpretation across different schools of jurisprudence (madhabs) and cultural contexts.',
        ),

        _buildCompleteSection(
          'Mental Health and Medical Disclaimers',
          'CRITICAL MENTAL HEALTH DISCLAIMER:\n\n'
          'This App is NOT a substitute for professional mental health care. You acknowledge and understand that:\n\n'
          '• The App does NOT provide therapy, counseling, or medical treatment\n'
          '• AI responses are NOT professional mental health advice\n'
          '• The App cannot diagnose, treat, or cure any mental health condition\n'
          '• The App is NOT designed for crisis intervention or emergency situations\n\n'
          'WHEN TO SEEK PROFESSIONAL HELP:\n'
          'You must seek immediate professional help if you experience:\n'
          '• Thoughts of self-harm or suicide\n'
          '• Severe depression, anxiety, or other mental health symptoms\n'
          '• Substance abuse or addiction issues\n'
          '• Domestic violence or abuse situations\n'
          '• Any mental health crisis or emergency\n\n'
          'EMERGENCY CONTACTS:\n'
          'In case of mental health emergency, contact:\n'
          '• Emergency services (911 in US, 999 in UK, or local emergency number)\n'
          '• National Suicide Prevention Lifeline\n'
          '• Local crisis intervention services\n'
          '• Your healthcare provider or mental health professional\n\n'
          'The App is designed to provide general support and companionship, but it cannot replace professional mental health care, medical treatment, or crisis intervention services.',
        ),

        _buildCompleteSection(
          'Limitation of Liability and Disclaimers',
          'TO THE FULLEST EXTENT PERMITTED BY LAW:\n\n'
          'DISCLAIMER OF WARRANTIES:\n'
          '• The App is provided "AS IS" and "AS AVAILABLE" without warranties of any kind\n'
          '• We make no representations about the accuracy, reliability, or completeness of AI responses\n'
          '• We do not warrant that the App will be uninterrupted, secure, or error-free\n'
          '• We disclaim all warranties, express or implied, including merchantability and fitness for a particular purpose\n\n'
          'LIMITATION OF LIABILITY:\n'
          '• We shall not be liable for any direct, indirect, incidental, special, or consequential damages\n'
          '• This includes damages arising from your use of or inability to use the App\n'
          '• We are not responsible for decisions made based on AI-generated responses\n'
          '• Users assume full responsibility for their actions and decisions\n'
          '• Our total liability shall not exceed the amount paid by you for the App (if any)\n\n'
          'USER RESPONSIBILITY:\n'
          'You acknowledge that:\n'
          '• You use the App at your own risk and discretion\n'
          '• You are solely responsible for your interactions with the AI\n'
          '• You will not hold us liable for any consequences of your use of the App\n'
          '• You understand the limitations of AI technology and its potential for errors\n\n'
          'Some jurisdictions do not allow the exclusion of certain warranties or limitation of liability, so some of the above limitations may not apply to you.',
        ),

        _buildCompleteSection(
          'Prohibited Uses and User Conduct',
          'You agree NOT to use the App for any of the following prohibited purposes:\n\n'
          'PROHIBITED ACTIVITIES:\n'
          '• Violating any applicable laws or regulations\n'
          '• Harassing, threatening, or intimidating others\n'
          '• Sharing inappropriate, offensive, or harmful content\n'
          '• Attempting to hack, reverse engineer, or compromise the App\n'
          '• Using the App for commercial purposes without authorization\n'
          '• Impersonating others or providing false information\n'
          '• Distributing malware, viruses, or other harmful code\n'
          '• Attempting to gain unauthorized access to our systems\n'
          '• Using the App to promote illegal activities\n'
          '• Violating the intellectual property rights of others\n\n'
          'CONTENT GUIDELINES:\n'
          'When interacting with the AI, you agree to:\n'
          '• Be respectful and considerate in your communications\n'
          '• Avoid sharing personal information of others without consent\n'
          '• Not attempt to manipulate or "jailbreak" the AI system\n'
          '• Report any technical issues or inappropriate AI responses\n\n'
          'We reserve the right to suspend or terminate access for users who violate these guidelines.',
        ),

        _buildCompleteSection(
          'Intellectual Property Rights',
          'OWNERSHIP:\n'
          '• The App, including its design, code, AI models, and content, is owned by us and protected by intellectual property laws\n'
          '• All trademarks, service marks, and logos used in the App are our property or used with permission\n'
          '• You do not acquire any ownership rights in the App or its content\n\n'
          'USER CONTENT:\n'
          '• You retain ownership of the messages and content you submit to the App\n'
          '• By using the App, you grant us a license to process your messages for service delivery\n'
          '• We may use anonymized and aggregated data to improve our services\n'
          '• You represent that you have the right to share any content you submit\n\n'
          'RESTRICTIONS:\n'
          'You may not:\n'
          '• Copy, modify, or distribute the App or its content\n'
          '• Create derivative works based on the App\n'
          '• Use our trademarks or branding without permission\n'
          '• Reverse engineer or attempt to extract source code',
        ),

        _buildCompleteSection(
          'Termination and Account Suspension',
          'TERMINATION BY YOU:\n'
          '• You may stop using the App at any time\n'
          '• You may request deletion of your data by contacting us\n'
          '• Uninstalling the App does not automatically delete your data from our servers\n\n'
          'TERMINATION BY US:\n'
          'We reserve the right to:\n'
          '• Suspend or terminate your access to the App at any time\n'
          '• Remove or disable access for violations of these Terms\n'
          '• Discontinue the App or any features with or without notice\n'
          '• Modify or update the App\'s functionality\n\n'
          'EFFECT OF TERMINATION:\n'
          '• Upon termination, your right to use the App ceases immediately\n'
          '• We may retain certain data as required by law or for legitimate business purposes\n'
          '• Provisions regarding liability, disclaimers, and intellectual property survive termination',
        ),

        _buildCompleteSection(
          'Updates and Modifications',
          'APP UPDATES:\n'
          '• We may release updates, patches, or new versions of the App\n'
          '• Updates may include new features, bug fixes, or security improvements\n'
          '• Some updates may be required for continued use of the App\n'
          '• We are not obligated to provide updates or maintain backward compatibility\n\n'
          'TERMS MODIFICATIONS:\n'
          '• We reserve the right to modify these Terms at any time\n'
          '• Material changes will be communicated through the App or other appropriate means\n'
          '• Continued use of the App after changes constitutes acceptance of new Terms\n'
          '• If you disagree with changes, you must stop using the App\n\n'
          'SERVICE CHANGES:\n'
          '• We may modify, suspend, or discontinue any aspect of the App\n'
          '• Features may be added, removed, or changed without prior notice\n'
          '• We are not liable for any modifications or discontinuation of services',
        ),

        _buildCompleteSection(
          'Governing Law and Dispute Resolution',
          'GOVERNING LAW:\n'
          '• These Terms are governed by the laws of [Jurisdiction to be specified]\n'
          '• Any disputes will be resolved in accordance with applicable law\n'
          '• You agree to submit to the jurisdiction of competent courts\n\n'
          'DISPUTE RESOLUTION:\n'
          '• We encourage resolving disputes through direct communication first\n'
          '• For formal disputes, you agree to binding arbitration where permitted by law\n'
          '• Class action lawsuits are waived to the extent permitted by law\n'
          '• Some jurisdictions may not allow certain limitations, so they may not apply to you\n\n'
          'SEVERABILITY:\n'
          '• If any provision of these Terms is found unenforceable, the remainder remains in effect\n'
          '• Invalid provisions will be modified to the minimum extent necessary to make them valid',
        ),

        _buildCompleteSection(
          'Contact Information and Support',
          'If you have questions about these Terms and Conditions, need technical support, or want to report issues:\n\n'
          'CONTACT METHODS:\n'
          '• Email: [Contact email to be specified]\n'
          '• In-app support features (if available)\n'
          '• Official website or support portal\n\n'
          'SUPPORT SCOPE:\n'
          '• Technical issues and bug reports\n'
          '• Questions about app functionality\n'
          '• Privacy and data concerns\n'
          '• Terms and conditions clarifications\n\n'
          'RESPONSE TIME:\n'
          '• We strive to respond to inquiries in a timely manner\n'
          '• Response times may vary based on the nature and complexity of your request\n'
          '• For urgent technical issues, please use the most direct contact method available\n\n'
          'Please note that our support team cannot provide medical advice, religious rulings, or professional counseling services.',
        ),

        _buildCompleteSection(
          'Final Provisions',
          'ENTIRE AGREEMENT:\n'
          '• These Terms, together with our Privacy Policy, constitute the entire agreement between you and us\n'
          '• These Terms supersede any prior agreements or understandings\n'
          '• No oral or written statements outside these Terms modify this agreement\n\n'
          'WAIVER:\n'
          '• Our failure to enforce any provision does not constitute a waiver of that provision\n'
          '• Waivers must be in writing to be effective\n'
          '• No waiver of any breach constitutes a waiver of any subsequent breach\n\n'
          'ASSIGNMENT:\n'
          '• You may not assign or transfer your rights under these Terms\n'
          '• We may assign our rights and obligations to any party\n'
          '• These Terms bind and benefit the parties and their successors\n\n'
          'ACKNOWLEDGMENT:\n'
          'By using Nafs AI, you acknowledge that you have read, understood, and agree to be bound by these Terms and Conditions. You also acknowledge that you have read and understood our Privacy Policy.\n\n'
          'These Terms are effective as of the date you first use the App and remain in effect until terminated in accordance with these Terms.',
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildCompleteSection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2C5530).withOpacity(0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C5530),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Color(0xFF4F372D),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2C5530).withOpacity(0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C5530),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Color(0xFF4F372D),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcknowledgmentCheckbox(
    String text,
    bool value,
    ValueChanged<bool?> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: value
          ? const Color(0xFF2C5530).withOpacity(0.05)
          : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
            ? const Color(0xFF2C5530).withOpacity(0.3)
            : const Color(0xFF7B4F2F).withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Transform.scale(
            scale: 1.2,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFF2C5530),
              checkColor: const Color(0xFFFCF8F1),
              side: BorderSide(
                color: const Color(0xFF7B4F2F).withOpacity(0.5),
                width: 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(!value),
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 15,
                    color: const Color(0xFF4F372D),
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
