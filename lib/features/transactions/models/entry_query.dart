import 'money_entry.dart';

enum EntrySort { newest, oldest, amountHigh, amountLow, title }

/// Query the already loaded local records. No HTTP or remote service is used.
class EntryQuery {
  const EntryQuery({
    this.text = '',
    this.category,
    this.income,
    this.sort = EntrySort.newest,
  });
  final String text;
  final String? category;
  final bool? income;
  final EntrySort sort;

  List<MoneyEntry> apply(Iterable<MoneyEntry> source) {
    final term = text.trim().toLowerCase();
    final result = source
        .where(
          (e) =>
              (category == null || e.category == category) &&
              (income == null || e.income == income) &&
              '${e.title} ${e.category} ${e.owner} ${e.note}'
                  .toLowerCase()
                  .contains(term),
        )
        .toList();
    result.sort((a, b) {
      final comparison = switch (sort) {
        EntrySort.newest => b.date.compareTo(a.date),
        EntrySort.oldest => a.date.compareTo(b.date),
        EntrySort.amountHigh => b.amount.compareTo(a.amount),
        EntrySort.amountLow => a.amount.compareTo(b.amount),
        EntrySort.title => a.title.toLowerCase().compareTo(
          b.title.toLowerCase(),
        ),
      };
      return comparison != 0 ? comparison : a.id.compareTo(b.id);
    });
    return result;
  }
}
