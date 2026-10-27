import 'dart:async';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

enum SyncPhase { idle, loading, success, error }

enum SyncFailure { offline, timeout, access, server, invalidData, unknown }

SyncFailure classifySyncFailure(Object error) {
  if (error is TimeoutException) return SyncFailure.timeout;
  if (error is ClientException || error is AuthRetryableFetchException) {
    return SyncFailure.offline;
  }
  if (error is PostgrestException) {
    return ['401', '403', '42501', 'PGRST301', 'PGRST303'].contains(error.code)
        ? SyncFailure.access
        : SyncFailure.server;
  }
  if (error is AuthException) return SyncFailure.access;
  if (error is FormatException || error is TypeError) {
    return SyncFailure.invalidData;
  }
  return SyncFailure.unknown;
}

String syncFailureMessage(SyncFailure failure) => switch (failure) {
  SyncFailure.offline => 'Желіге қосылу мүмкін болмады. Интернетті тексеріңіз.',
  SyncFailure.timeout =>
    'Сервер уақытында жауап бермеді. Қайта байқап көріңіз.',
  SyncFailure.access =>
    'Бұлттағы деректерге рұқсат жоқ. Аккаунтқа қайта кіріңіз.',
  SyncFailure.server => 'Сервер сұрауды орындай алмады. Кейінірек қайталаңыз.',
  SyncFailure.invalidData => 'Алынған деректерді оқу мүмкін болмады.',
  SyncFailure.unknown => 'Синхрондау аяқталмады. Қайта байқап көріңіз.',
};
