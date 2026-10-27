abstract final class Validators {
  static String? required(String? value) =>
      value == null || value.trim().isEmpty ? 'Бұл өрісті толтырыңыз.' : null;
  static String? email(String? value) {
    if (required(value) != null) return 'Email мекенжайын енгізіңіз.';
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$').hasMatch(value!.trim())
        ? null
        : 'Email дұрыс емес. Мысалы: daniyar@example.com';
  }

  static String? password(String? value) {
    if (value == null || value.trim().isEmpty) return 'Құпиясөзді енгізіңіз.';
    if (value.length < 8) return 'Құпиясөз кемінде 8 таңбадан тұруы керек.';
    return null;
  }

  static String? newPassword(String? value) {
    final error = password(value);
    if (error != null) return error;
    if (!RegExp(r'[A-ZА-ЯӘІҢҒҮҰҚӨҺ]').hasMatch(value!) ||
        !RegExp(r'[0-9]').hasMatch(value)) {
      return 'Кемінде бір бас әріп және бір сан қосыңыз.';
    }
    return null;
  }

  static String? amount(String? value) {
    if (required(value) != null) return 'Соманы енгізіңіз.';
    final number = int.tryParse(value!.replaceAll(' ', ''));
    if (number == null || number <= 0) {
      return 'Нөлден үлкен бүтін сан енгізіңіз.';
    }
    if (number > 1000000000) return 'Сома 1 000 000 000 ₸-ден аспауы керек.';
    return null;
  }
}
