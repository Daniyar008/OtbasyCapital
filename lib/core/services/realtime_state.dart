enum RealtimeState { idle, connecting, connected, offline }

String realtimeLabel(RealtimeState state) => switch (state) {
  RealtimeState.idle => 'Нақты уақыттағы байланыс күтілуде',
  RealtimeState.connecting => 'Нақты уақыттағы байланыс қосылуда',
  RealtimeState.connected => 'Нақты уақыттағы байланыс белсенді',
  RealtimeState.offline => 'Нақты уақыттағы байланыс үзілді',
};
