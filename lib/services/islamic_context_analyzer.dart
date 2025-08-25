import '../config/personality_config.dart';

/// Service to intelligently detect when Islamic expressions would be most appropriate
/// based on message content and emotional context
class IslamicContextAnalyzer {
  /// Keywords that indicate different emotional contexts
  static const Map<String, List<String>> _contextKeywords = {
    'gratitude': [
      'thank', 'grateful', 'blessed', 'appreciate', 'happy', 'joy', 'wonderful',
      'amazing', 'good news', 'success', 'achieved', 'accomplished', 'relief',
      'thankful', 'praise', 'celebration', 'excited', 'thrilled'
    ],
    'difficulty': [
      'hard', 'difficult', 'struggle', 'problem', 'stress', 'worried', 'anxiety',
      'depression', 'sad', 'upset', 'frustrated', 'angry', 'pain', 'hurt',
      'suffering', 'tough', 'challenging', 'overwhelming', 'burden', 'heavy',
      'crisis', 'emergency', 'disaster', 'tragedy', 'loss', 'grief', 'mourning'
    ],
    'hope': [
      'hope', 'wish', 'want', 'dream', 'future', 'goal', 'aspire', 'desire',
      'plan', 'ambition', 'vision', 'looking forward', 'optimistic', 'positive',
      'better', 'improve', 'change', 'grow', 'progress', 'opportunity'
    ],
    'uncertainty': [
      'don\'t know', 'confused', 'unsure', 'lost', 'doubt', 'uncertain',
      'unclear', 'puzzled', 'bewildered', 'perplexed', 'questioning',
      'wondering', 'maybe', 'perhaps', 'not sure', 'hesitant', 'indecisive',
      'torn', 'conflicted', 'dilemma', 'crossroads'
    ]
  };

  /// Additional context patterns for more nuanced detection
  static final Map<String, List<RegExp>> _contextPatterns = {
    'gratitude': [
      RegExp(r'\b(alhamdulillah|praise be|thank god|blessed)\b', caseSensitive: false),
      RegExp(r'\b(so grateful|really appreciate|cannot thank)\b', caseSensitive: false),
    ],
    'difficulty': [
      RegExp(r'\b(going through|dealing with|struggling with)\b', caseSensitive: false),
      RegExp(r'\b(feel like|feels like).*(giving up|cannot handle|too much)\b', caseSensitive: false),
    ],
    'hope': [
      RegExp(r'\b(inshallah|god willing|hopefully)\b', caseSensitive: false),
      RegExp(r'\b(looking forward|cannot wait|excited about)\b', caseSensitive: false),
    ],
    'uncertainty': [
      RegExp(r'\b(what should i|how do i|not sure if)\b', caseSensitive: false),
      RegExp(r'\b(do not understand|makes no sense|confused about)\b', caseSensitive: false),
    ]
  };

  /// Detect the primary emotional context of a message
  /// Returns the context type or null if no clear context is detected
  static String? detectContext(String message) {
    if (message.trim().isEmpty) return null;
    
    String lowerMessage = message.toLowerCase();
    Map<String, int> contextScores = {};

    // Initialize scores
    for (String context in _contextKeywords.keys) {
      contextScores[context] = 0;
    }

    // Score based on keywords
    for (String context in _contextKeywords.keys) {
      for (String keyword in _contextKeywords[context]!) {
        if (lowerMessage.contains(keyword)) {
          contextScores[context] = contextScores[context]! + 1;
        }
      }
    }

    // Score based on patterns (weighted higher)
    for (String context in _contextPatterns.keys) {
      for (RegExp pattern in _contextPatterns[context]!) {
        if (pattern.hasMatch(lowerMessage)) {
          contextScores[context] = contextScores[context]! + 2;
        }
      }
    }

    // Find the highest scoring context
    String? bestContext;
    int highestScore = 0;
    
    contextScores.forEach((context, score) {
      if (score > highestScore) {
        highestScore = score;
        bestContext = context;
      }
    });

    // Only return context if score is meaningful (at least 1)
    return highestScore > 0 ? bestContext : null;
  }

  /// Get appropriate Islamic expressions for a detected context
  static List<String> getAppropriateExpressions(String context) {
    final expressions = PersonalityLanguageConfig.getContextualIslamicExpressions();
    return expressions[context] ?? [];
  }

  /// Get a random appropriate expression for a context
  static String? getRandomExpression(String context) {
    final expressions = getAppropriateExpressions(context);
    if (expressions.isEmpty) return null;
    
    // Simple pseudo-random selection based on context hash
    final index = context.hashCode.abs() % expressions.length;
    return expressions[index];
  }

  /// Check if message contains existing Islamic expressions
  /// This helps avoid over-saturating responses with Islamic terms
  static bool containsIslamicExpressions(String message) {
    final islamicTerms = [
      'insha\'allah', 'inshallah', 'mashallah', 'subhanallah', 'alhamdulillah',
      'barakallahu', 'wallahi', 'akhi', 'ukhti', 'habibti', 'sabr', 'tawakkul',
      'hikmah', 'dua', 'allah', 'bismillah'
    ];
    
    String lowerMessage = message.toLowerCase();
    return islamicTerms.any((term) => lowerMessage.contains(term));
  }

  /// Analyze message and provide comprehensive context information
  static IslamicContextAnalysis analyzeMessage(String message) {
    final context = detectContext(message);
    final expressions = context != null ? getAppropriateExpressions(context) : <String>[];
    final hasExistingIslamic = containsIslamicExpressions(message);
    
    return IslamicContextAnalysis(
      detectedContext: context,
      appropriateExpressions: expressions,
      hasExistingIslamicContent: hasExistingIslamic,
      recommendedExpression: context != null ? getRandomExpression(context) : null,
    );
  }
}

/// Data class to hold the results of Islamic context analysis
class IslamicContextAnalysis {
  final String? detectedContext;
  final List<String> appropriateExpressions;
  final bool hasExistingIslamicContent;
  final String? recommendedExpression;

  const IslamicContextAnalysis({
    this.detectedContext,
    required this.appropriateExpressions,
    required this.hasExistingIslamicContent,
    this.recommendedExpression,
  });

  /// Whether Islamic expressions would be contextually appropriate
  bool get shouldIncludeIslamic => detectedContext != null && !hasExistingIslamicContent;
  
  /// Whether this is a high-priority context that should override frequency limits
  bool get isHighPriorityContext => detectedContext == 'difficulty' || detectedContext == 'gratitude';
}
