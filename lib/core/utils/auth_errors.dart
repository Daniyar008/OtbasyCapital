import 'package:supabase_flutter/supabase_flutter.dart';

String authErrorMessage(Object error) {
  if (error is AuthException) {
    return switch (error.code) {
      'invalid_credentials' => 'Email немесе құпиясөз қате.',
      'email_not_confirmed' => 'Алдымен email мекенжайын растаңыз.',
      'user_already_exists' => 'Бұл email тіркелген. Кіруді қолданыңыз.',
      'over_email_send_rate_limit' || 'over_request_rate_limit' =>
        'Сұрау тым көп. Біраз уақыттан кейін қайталаңыз.',
      'email_address_invalid' => 'Жарамды email мекенжайын енгізіңіз.',
      'weak_password' => 'Күштірек құпиясөз таңдаңыз.',
      _ => 'Аккаунт сұрауы орындалмады. Email мен құпиясөзді тексеріңіз.',
    };
  }
  return 'Серверге қосылу мүмкін болмады. Интернетті тексеріп, қайталаңыз.';
}
