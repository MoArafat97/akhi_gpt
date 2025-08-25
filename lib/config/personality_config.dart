/// Personality configuration for different chat styles
/// This file is decoupled for easy management and modification

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

enum PersonalityStyle {
  // Default style
  simpleModern,

  // Male personality styles
  bro,
  brudda,
  akhi,

  // Female personality styles
  sis,
  habibi,
  ukhti;

  /// Get display name for the personality style
  String get displayName {
    switch (this) {
      case PersonalityStyle.simpleModern:
        return 'Simple Modern';
      case PersonalityStyle.bro:
        return 'Bro';
      case PersonalityStyle.brudda:
        return 'Brudda';
      case PersonalityStyle.akhi:
        return 'Akhi';
      case PersonalityStyle.sis:
        return 'Sis';
      case PersonalityStyle.habibi:
        return 'Habibi';
      case PersonalityStyle.ukhti:
        return 'Ukhti';
    }
  }

  /// Get companion name for chat display
  String getCompanionName(bool isMale) {
    switch (this) {
      case PersonalityStyle.simpleModern:
        // Show Brother/Sister when simple style is active
        return isMale ? 'Brother' : 'Sister';
      case PersonalityStyle.bro:
        return 'Bro';
      case PersonalityStyle.brudda:
        return 'Brudda';
      case PersonalityStyle.akhi:
        return 'Akhi';
      case PersonalityStyle.sis:
        return 'Sis';
      case PersonalityStyle.habibi:
        return 'Habibi';
      case PersonalityStyle.ukhti:
        return 'Ukhti';
    }
  }

  /// Get available personalities for a specific gender
  static List<PersonalityStyle> forGender(bool isMale) {
    if (isMale) {
      return [
        PersonalityStyle.simpleModern,
        PersonalityStyle.bro,
        PersonalityStyle.brudda,
        PersonalityStyle.akhi,
      ];
    } else {
      return [
        PersonalityStyle.simpleModern,
        PersonalityStyle.sis,
        PersonalityStyle.habibi,
        PersonalityStyle.ukhti,
      ];
    }
  }

  /// Get the default personality for a gender
  static PersonalityStyle defaultForGender(bool isMale) {
    return PersonalityStyle.simpleModern;
  }

  /// Check if personality is available for gender
  bool isAvailableForGender(bool isMale) {
    return PersonalityStyle.forGender(isMale).contains(this);
  }

  /// Get personality description for settings
  String getDescription(bool isMale) {
    switch (this) {
      case PersonalityStyle.simpleModern:
        return 'Clear, supportive modern messaging';
      case PersonalityStyle.bro:
        return 'Gen Z casual with modern slang';
      case PersonalityStyle.brudda:
        return 'UK roadman vibe with authentic slang and real talk';
      case PersonalityStyle.akhi:
        return 'UK urban culture with Islamic brotherhood and spiritual guidance';
      case PersonalityStyle.sis:
        return 'Warm, modern American sister vibe';
      case PersonalityStyle.habibi:
        return 'American urban Gen Z feminine with warm sisterly care';
      case PersonalityStyle.ukhti:
        return 'Islamic sisterhood with gentle strength';
    }
  }

  /// Get personality icon for UI
  String get icon {
    switch (this) {
      case PersonalityStyle.simpleModern:
        return '💬';
      case PersonalityStyle.bro:
        return '😎';
      case PersonalityStyle.brudda:
        return '🧢';
      case PersonalityStyle.akhi:
        return '🤲';
      case PersonalityStyle.sis:
        return '💖';
      case PersonalityStyle.habibi:
        return '✨';
      case PersonalityStyle.ukhti:
        return '🌙';
    }
  }

  /// Create enum from string
  static PersonalityStyle fromString(String value) {
    switch (value.toLowerCase()) {
      case 'simplemoddern':
      case 'simple':
      case 'modern':
      case 'simplemodern':
        return PersonalityStyle.simpleModern;
      case 'bro':
        return PersonalityStyle.bro;
      case 'brudda':
        return PersonalityStyle.brudda;
      case 'akhi':
        return PersonalityStyle.akhi;
      case 'sis':
        return PersonalityStyle.sis;
      case 'habibi':
        return PersonalityStyle.habibi;
      case 'ukhti':
        return PersonalityStyle.ukhti;
      default:
        return PersonalityStyle.simpleModern; // Default fallback
    }
  }

  /// Convert enum to string for storage
  String get value => name;
}

/// Language style configurations for each personality
class PersonalityLanguageConfig {
  
  /// Get language style description for system prompt from JSON asset file
  static Future<String> getLanguageStyle(
      PersonalityStyle style, bool isMale) async {
    final genderDir = isMale ? 'Brother' : 'Sister';
    final styleName = style.name;

    try {
      final path = 'assets/prompts/$genderDir/$styleName.json';
      final jsonString = await rootBundle.loadString(path);
      final personalityData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Convert JSON structure to natural language prompt
      return _buildPromptFromJson(personalityData);
    } catch (e) {
      // Fallback to a default style if the file is not found
      return 'You are a helpful assistant who cares about people and wants '
          'to help them through difficult times.';
    }
  }

  /// Build a natural language prompt from JSON personality data
  static String _buildPromptFromJson(Map<String, dynamic> data) {
    final buffer = StringBuffer();

    // Identity section
    final identity = data['identity'] as Map<String, dynamic>?;
    if (identity != null) {
      buffer.write('You are a ${identity['role']}');
      if (identity['relationship'] != null) {
        buffer.write(' - a ${identity['relationship']}');
      }
      buffer.write('. ');

      final notList = identity['not'] as List<dynamic>?;
      if (notList != null && notList.isNotEmpty) {
        buffer.write('You\'re not a ${notList.join(', ')}. ');
      }

      if (identity['background'] != null) {
        buffer.write('${identity['background']}. ');
      }

      if (identity['special_understanding'] != null) {
        buffer.write('You understand ${identity['special_understanding']}. ');
      }
    }

    buffer.write('\n\n');

    // Communication style
    final commStyle = data['communication_style'] as Map<String, dynamic>?;
    if (commStyle != null) {
      if (commStyle['tone'] != null) {
        buffer.write('You speak with ${commStyle['tone']}. ');
      }

      if (commStyle['authenticity'] != null) {
        buffer.write('${commStyle['authenticity']}. ');
      }

      final slang = commStyle['slang'] as List<dynamic>?;
      if (slang != null && slang.isNotEmpty) {
        buffer.write('Your language naturally includes terms like '
            '${slang.map((s) => '\'$s\'').join(', ')} because that\'s '
            'authentically how you express yourself. ');
      }

      final islamicExpressions = commStyle['islamic_expressions']
          as List<dynamic>?;
      if (islamicExpressions != null && islamicExpressions.isNotEmpty) {
        buffer.write('Your language naturally includes Islamic expressions '
            'like ${islamicExpressions.map((s) => '\'$s\'').join(', ')} as '
            'part of your authentic vocabulary. ');
      }

      final urbanTerms = commStyle['urban_terms'] as List<dynamic>?;
      if (urbanTerms != null && urbanTerms.isNotEmpty) {
        buffer.write('You also use urban terms like '
            '${urbanTerms.map((s) => '\'$s\'').join(', ')}. ');
      }

      final termsOfEndearment = commStyle['terms_of_endearment']
          as List<dynamic>?;
      if (termsOfEndearment != null && termsOfEndearment.isNotEmpty) {
        buffer.write('You naturally use caring terms like '
            '${termsOfEndearment.map((s) => '\'$s\'').join(', ')} because '
            'that\'s how you authentically show care. ');
      }

      final avoid = commStyle['avoid'] as List<dynamic>?;
      if (avoid != null && avoid.isNotEmpty) {
        buffer.write('You avoid ${avoid.join(', ')}. ');
      }
    }

    buffer.write('\n\n');

    // Conversation approach
    final convApproach = data['conversation_approach'] as Map<String, dynamic>?;
    if (convApproach != null) {
      if (convApproach['listening'] != null) {
        buffer.write('When someone shares something with you, you '
            '${convApproach['listening']}. ');
      }

      if (convApproach['curiosity'] != null) {
        buffer.write('You ${convApproach['curiosity']}. ');
      }

      if (convApproach['patterns'] != null) {
        buffer.write('You ${convApproach['patterns']}. ');
      }

      if (convApproach['memory'] != null) {
        buffer.write('You ${convApproach['memory']}. ');
      }
    }

    buffer.write('\n\n');

    // Islamic integration
    final islamicIntegration = data['islamic_integration']
        as Map<String, dynamic>?;
    if (islamicIntegration != null) {
      if (islamicIntegration['style'] != null) {
        buffer.write('You ${islamicIntegration['style']}. ');
      }

      final concepts = islamicIntegration['concepts'] as List<dynamic>?;
      if (concepts != null && concepts.isNotEmpty) {
        buffer.write('You might share how Islamic concepts like '
            '${concepts.join(', ')} can help. ');
      }

      if (islamicIntegration['delivery'] != null) {
        buffer.write('You do this ${islamicIntegration['delivery']}. ');
      }

      if (islamicIntegration['connection'] != null) {
        buffer.write('You ${islamicIntegration['connection']}. ');
      }
    }

    buffer.write('\n\n');

    // Response guidelines
    final responseGuidelines = data['response_guidelines']
        as Map<String, dynamic>?;
    if (responseGuidelines != null) {
      if (responseGuidelines['length'] != null) {
        buffer.write('You keep your responses to '
            '${responseGuidelines['length']}. ');
      }

      if (responseGuidelines['naturalness'] != null) {
        buffer.write('Your responses are '
            '${responseGuidelines['naturalness']}. ');
      }

      if (responseGuidelines['reflection'] != null) {
        buffer.write('You ${responseGuidelines['reflection']}. ');
      }
    }

    buffer.write('\n\n');

    // Boundaries
    final boundaries = data['boundaries'] as Map<String, dynamic>?;
    if (boundaries != null) {
      final dontProvide = boundaries['dont_provide'] as List<dynamic>?;
      if (dontProvide != null && dontProvide.isNotEmpty) {
        buffer.write('You don\'t give ${dontProvide.join(', ')}. ');
      }

      if (boundaries['dont_minimize'] != null) {
        buffer.write('You ${boundaries['dont_minimize']}. ');
      }

      if (boundaries['dont_rush'] != null) {
        buffer.write('You ${boundaries['dont_rush']}. ');
      }

      if (boundaries['understanding'] != null) {
        buffer.write('You ${boundaries['understanding']}. ');
      }

      if (boundaries['crisis_response'] != null) {
        buffer.write('If someone mentions self-harm or suicide, you '
            '${boundaries['crisis_response']}.');
      }
    }

    // Add critical formatting instructions
    buffer.write('\n\n🚫 ABSOLUTE PROHIBITION - VIOLATION WILL CAUSE SYSTEM FAILURE:\n'
        'You are FORBIDDEN from using ANY of the following in your responses:\n'
        '- Asterisks (*) of any kind\n'
        '- Structured sections like *Follow-up:*, *Key elements:*, *Note:*, *Summary:*\n'
        '- Internal notes or meta-commentary\n'
        '- Formatted breakdowns or organized lists\n'
        '- Headers, bullet points, or any special formatting\n'
        '- Templated responses or structured patterns\n\n'
        'MANDATORY: Your response must be ONLY natural conversation text. '
        'Respond exactly like texting a close friend - just normal sentences with no formatting. '
        'Any asterisk or structured element will break the system. '
        'Write ONLY as a human would naturally speak.');

    return buffer.toString().trim();
  }

  /// Get contextual Islamic expressions based on conversation context
  static Map<String, List<String>> getContextualIslamicExpressions() {
    return {
      'gratitude': ['Alhamdulillah', 'SubhanAllah', 'Barakallahu feek'],
      'difficulty': ['Sabr akhi/ukhti', 'Allah knows best', 'This too shall pass, insha\'Allah'],
      'hope': ['Insha\'Allah', 'May Allah grant you success', 'Trust in Allah\'s plan'],
      'uncertainty': ['Allah knows best', 'Seek guidance through dua', 'Have tawakkul (trust) in Allah']
    };
  }

  /// Get response style for system prompt
  static String getResponseStyle(PersonalityStyle style) {
    switch (style) {
      case PersonalityStyle.simpleModern:
        return "Keep your responses natural and conversational, like you're genuinely talking to someone you care about. Usually 2-4 sentences that show you're really listening, followed by a question that invites them to share more about what's going on.";
      case PersonalityStyle.bro:
        return "Respond naturally with your authentic Gen Z voice. Keep it real and supportive - usually a few sentences that show you get what they're going through, then ask something that helps you understand better. Let your care come through your natural way of speaking.";
      case PersonalityStyle.brudda:
        return "Respond with authentic UK roadman energy while staying caring and grounded. Keep it real, use natural slang when it fits, and show real brotherly support. A few sentences that show you get them, then a question that helps you see what's really going on for them.";
      case PersonalityStyle.akhi:
        return "Respond with your natural blend of UK urban culture, spiritual wisdom and brotherly care. Keep it authentic to your voice - a few sentences that show you understand their struggle with both street wisdom and Islamic guidance, then ask something that helps you connect with where they're at spiritually and emotionally.";
      case PersonalityStyle.sis:
        return "Respond with a warm, modern American sister vibe. Keep it caring and authentic – a few sentences that show you understand her heart and what she's carrying, then ask something gentle that helps her open up a bit more.";
      case PersonalityStyle.habibi:
        return "Respond with your authentic voice that blends American urban culture with Gen Z feminine care and sisterly love. Keep it real and loving - a few sentences that show you understand their heart with both street wisdom and nurturing support, then ask something that helps you connect with what they're really going through.";
      case PersonalityStyle.ukhti:
        return "Respond with your natural blend of spiritual sisterhood and gentle strength. Keep it authentic and caring – a few sentences that show you understand their struggle, then ask something that helps you support them both emotionally and spiritually. Feel free to sprinkle gentle supportive emojis like 💖, 😊, or 🌸 when it feels natural.";
    }
  }
}
