/// Service to control the frequency of Islamic reminders to avoid overwhelming users
/// while maintaining authentic Islamic character in conversations
class IslamicReminderService {
  static const int _reminderFrequency = 5; // Every 5th message
  static int _messageCount = 0;
  
  /// Check if an Islamic reminder should be included in the response
  /// Returns true every 5th message to maintain natural frequency
  static bool shouldIncludeReminder() {
    _messageCount++;
    return _messageCount % _reminderFrequency == 0;
  }
  
  /// Reset the message counter (useful for new chat sessions)
  static void resetCounter() {
    _messageCount = 0;
  }
  
  /// Get current message count (for debugging/testing purposes)
  static int get currentMessageCount => _messageCount;
  
  /// Set custom reminder frequency (for testing or customization)
  static int get reminderFrequency => _reminderFrequency;
  
  /// Force next message to include reminder (for testing purposes)
  static void forceNextReminder() {
    _messageCount = _reminderFrequency - 1;
  }
}
