abstract class PreferencesEvent {}

class LoadPreferencesEvent extends PreferencesEvent {}

class ToggleDailyDigestEvent extends PreferencesEvent {
  final bool value;
  ToggleDailyDigestEvent(this.value);
}

class ToggleChannelEvent extends PreferencesEvent {
  final String notificationType;
  final String channel; // 'inapp', 'email', 'sms', 'whatsapp', 'push'
  final bool value;
  ToggleChannelEvent({required this.notificationType, required this.channel, required this.value});
}
