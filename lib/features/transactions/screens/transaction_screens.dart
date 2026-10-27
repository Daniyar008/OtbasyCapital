import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../app/app_store.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/result_screen.dart';
import '../models/money_entry.dart';
import '../models/entry_query.dart';
import '../widgets/entry_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _all = false;
  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final all = store.visibleEntries;
    final entries = _all ? all : all.take(3).toList();
    return AppPage(
      title: 'Операциялар тарихы',
      tab: 1,
      children: [
        AppButton(
          'Операцияны іздеу',
          kind: ButtonKind.secondary,
          onPressed: () => context.push('/search'),
        ),
        Row(
          children: [
            IconButton(
              tooltip: 'Алдыңғы ай',
              onPressed: () => store.setPeriod(
                DateTime(store.period.year, store.period.month - 1),
              ),
              icon: const AppIcon('back'),
            ),
            Expanded(
              child: Text(
                monthLabel(store.period),
                textAlign: TextAlign.center,
                style: AppTheme.label,
              ),
            ),
            IconButton(
              tooltip: 'Келесі ай',
              onPressed: () => store.setPeriod(
                DateTime(store.period.year, store.period.month + 1),
              ),
              icon: const AppIcon('arrow'),
            ),
          ],
        ),
        if (entries.isEmpty)
          const EmptyState(
            'Операциялар жоқ',
            'Осы айға жазба қосыңыз немесе басқа айды таңдаңыз.',
            icon: 'history',
          ),
        for (var i = 0; i < entries.length; i++) ...[
          if (i == 0 ||
              dateLabel(entries[i].date) != dateLabel(entries[i - 1].date))
            Text(
              dateLabel(entries[i].date),
              style: AppTheme.label.copyWith(color: AppColors.muted),
            ),
          EntryCard(entry: entries[i]),
        ],
        if (!_all && all.length > 3)
          AppButton(
            'Қалған ${all.length - 3} операцияны көрсету',
            kind: ButtonKind.quiet,
            onPressed: () => setState(() => _all = true),
          ),
        AppButton(
          'Таңдаулылар',
          kind: ButtonKind.secondary,
          onPressed: () => context.push('/favorites'),
        ),
        AppButton(
          '+ Операция қосу',
          onPressed: () => context.push('/entry/new'),
        ),
      ],
    );
  }
}

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context), entry = AppScope.of(context).entry(id);
    if (entry == null) {
      return AppPage(
        title: 'Операция табылмады',
        back: '/history',
        children: [
          AppButton('Тарихқа оралу', onPressed: () => context.go('/history')),
        ],
      );
    }
    return AppPage(
      title: 'Операция туралы',
      back: '/history',
      tab: 1,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppIcon(entry.icon),
              const SizedBox(height: 12),
              Text(
                '${entry.income ? '+' : '-'}${money(entry.amount)}',
                style: AppTheme.amount.copyWith(
                  color: entry.income ? AppColors.green : AppColors.red,
                ),
              ),
              const SizedBox(height: 8),
              Text(entry.category, style: AppTheme.label),
            ],
          ),
        ),
        AppCard(
          title: dateLabel(entry.date),
          icon: 'history',
          subtitle: '${entry.owner} • ${entry.shared ? 'Ортақ' : 'Жеке'}',
        ),
        AppCard(
          title: entry.title,
          subtitle: entry.note.isEmpty ? 'Ескертпе жоқ' : entry.note,
          icon: 'wallet',
        ),
        AppButton('Өзгерту', onPressed: () => context.push('/entry/$id/edit')),
        AppButton(
          entry.favorite ? 'Таңдаулылардан алып тастау' : 'Таңдаулыларға қосу',
          kind: ButtonKind.secondary,
          onPressed: () async {
            await store.toggleFavorite(id);
            if (context.mounted) {
              showMessage(
                context,
                entry.favorite
                    ? 'Таңдаулылардан алынды.'
                    : 'Таңдаулыларға қосылды.',
              );
            }
          },
        ),
        AppButton(
          'Операцияны жою',
          kind: ButtonKind.quiet,
          onPressed: () async {
            final approved = await confirmAction(
              context,
              title: 'Операцияны жою',
              message:
                  '${entry.title} · ${money(entry.amount)}. Бұл жазба жойылады.',
            );
            if (!approved || !context.mounted) return;
            await store.deleteEntry(id);
            if (context.mounted) {
              context.go(
                '/result',
                extra: ResultData(
                  title: 'Операция жойылды',
                  message: 'Жаңарған қалдық',
                  amount: money(store.balance),
                  secondaryDestination: '/history',
                  secondaryButton: 'Тарихқа өту',
                ),
              );
            }
          },
        ),
      ],
    );
  }
}

class EntryFormScreen extends StatefulWidget {
  const EntryFormScreen({super.key, this.entry});
  final MoneyEntry? entry;
  @override
  State<EntryFormScreen> createState() => _EntryFormScreenState();
}

class _EntryFormScreenState extends State<EntryFormScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title, _amount, _note;
  late DateTime _date;
  late String _category;
  late bool _income, _shared;
  bool _busy = false, _initialized = false;
  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _title = TextEditingController(text: e?.title ?? '');
    _amount = TextEditingController(text: e?.amount.toString() ?? '');
    _note = TextEditingController(text: e?.note ?? '');
    _date = e?.date ?? DateTime.now();
    _category = e?.category ?? 'Азық-түлік';
    _income = e?.income ?? false;
    _shared = e?.shared ?? true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized && widget.entry == null) {
      _shared = AppScope.of(context).sharedView;
    }
    _initialized = true;
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final store = AppScope.of(context);
    await store.saveEntry(
      MoneyEntry(
        id: widget.entry?.id ?? store.newId(),
        title: _title.text.trim(),
        amount: int.parse(_amount.text.replaceAll(' ', '')),
        income: _income,
        category: _income ? 'Кіріс' : _category,
        date: _date,
        owner: widget.entry?.owner ?? store.name,
        shared: _shared,
        note: _note.text.trim(),
        favorite: widget.entry?.favorite ?? false,
      ),
    );
    if (!mounted) return;
    context.go(
      '/result',
      extra: ResultData(
        title: widget.entry == null ? 'Операция сақталды' : 'Өзгеріс сақталды',
        amount: money(store.balance),
        message: 'Кіріс ${money(store.income)} · Шығыс ${money(store.expense)}',
        secondaryDestination: '/home',
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: widget.entry == null ? 'Жаңа операция' : 'Операцияны өзгерту',
    back: widget.entry == null ? '/home' : '/entry/${widget.entry!.id}',
    formKey: _form,
    children: [
      Row(
        children: [
          Expanded(
            child: AppButton(
              'Шығыс',
              kind: !_income ? ButtonKind.secondary : ButtonKind.quiet,
              onPressed: () => setState(() {
                _income = false;
                if (_category == 'Кіріс') _category = 'Азық-түлік';
              }),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AppButton(
              'Кіріс',
              kind: _income ? ButtonKind.secondary : ButtonKind.quiet,
              onPressed: () => setState(() => _income = true),
            ),
          ),
        ],
      ),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.green,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Сома', style: AppTheme.body.copyWith(color: Colors.white)),
            TextFormField(
              key: const ValueKey('entry-amount'),
              controller: _amount,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: AppTheme.amount,
              validator: Validators.amount,
              decoration: InputDecoration(
                filled: false,
                hintText: '0',
                suffixText: '₸',
                suffixStyle: AppTheme.amount,
                hintStyle: AppTheme.amount,
                contentPadding: const EdgeInsets.only(top: 8),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorStyle: AppTheme.caption.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
      AppField(
        'Атауы',
        controller: _title,
        validator: Validators.required,
        hint: 'Мысалы, Magnum',
        inputKey: const ValueKey('entry-title'),
      ),
      if (!_income)
        AppSelect(
          'Санат',
          value: _category,
          items: AppStore.categories,
          onChanged: (v) => setState(() => _category = v),
        ),
      DateField(value: _date, onChanged: (v) => setState(() => _date = v)),
      AppSelect(
        'Көрінуі',
        value: _shared ? 'Ортақ' : 'Жеке',
        items: const ['Ортақ', 'Жеке'],
        onChanged: (v) => setState(() => _shared = v == 'Ортақ'),
      ),
      AppField(
        'Ескертпе',
        controller: _note,
        hint: 'Міндетті емес',
        inputKey: const ValueKey('entry-note'),
      ),
      AppButton(
        widget.entry == null ? 'Сақтау' : 'Өзгерісті сақтау',
        key: const ValueKey('save-entry'),
        busy: _busy,
        onPressed: _save,
      ),
      AppButton(
        'Бас тарту',
        kind: ButtonKind.quiet,
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        },
      ),
    ],
  );
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _query = TextEditingController();
  String _category = 'Барлығы', _type = 'Барлығы';
  EntrySort _sort = EntrySort.newest;
  static const _sortLabels = [
    'Күні: жаңадан ескіге',
    'Күні: ескіден жаңаға',
    'Сома: көптен азға',
    'Сома: аздан көпке',
    'Атауы бойынша',
  ];
  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final results = EntryQuery(
      text: _query.text,
      category: _category == 'Барлығы' ? null : _category,
      income: _type == 'Барлығы' ? null : _type == 'Кіріс',
      sort: _sort,
    ).apply(store.visibleEntries);
    return AppPage(
      title: 'Іздеу',
      back: '/history',
      tab: 1,
      children: [
        AppField(
          'Іздеу сұрауы',
          controller: _query,
          hint: 'Атауы, санаты немесе ескертпе',
          inputKey: const ValueKey('search-query'),
          onChanged: (_) => setState(() {}),
        ),
        ExpansionTile(
          key: const ValueKey('search-filters'),
          title: const Text('Сүзгі және сұрыптау'),
          children: [
            AppSelect(
              'Операция түрі',
              value: _type,
              items: const ['Барлығы', 'Кіріс', 'Шығыс'],
              onChanged: (v) => setState(() => _type = v),
            ),
            const SizedBox(height: 16),
            AppSelect(
              'Санат бойынша',
              value: _category,
              items: const ['Барлығы', ...AppStore.categories, 'Кіріс'],
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: 16),
            AppSelect(
              'Сұрыптау',
              value: _sortLabels[_sort.index],
              items: _sortLabels,
              onChanged: (v) => setState(
                () => _sort = EntrySort.values[_sortLabels.indexOf(v)],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
        Text(
          '${monthLabel(store.period)} • ${results.length} нәтиже',
          style: AppTheme.caption,
        ),
        if (results.isEmpty)
          const EmptyState(
            'Ештеңе табылмады',
            'Сұрауды өзгертіңіз немесе іздеуді тазалаңыз.',
          ),
        ...results.map((e) => EntryCard(entry: e)),
        AppButton(
          'Сүзгілерді тазалау',
          kind: ButtonKind.secondary,
          onPressed: () => setState(() {
            _query.clear();
            _category = 'Барлығы';
            _type = 'Барлығы';
            _sort = EntrySort.newest;
          }),
        ),
      ],
    );
  }
}

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final entries = AppScope.of(context).accessibleEntries
        .where((e) => e.favorite)
        .toList();
    return AppPage(
      title: 'Таңдаулылар',
      back: '/profile',
      tab: 1,
      children: [
        const Text('Жиі қарайтын операцияларыңыз.', style: AppTheme.caption),
        if (entries.isEmpty)
          const EmptyState(
            'Таңдаулы операциялар жоқ',
            'Операцияны ашып, «Таңдаулыларға қосу» батырмасын басыңыз.',
            icon: 'star',
          ),
        ...entries.map((e) => EntryCard(entry: e)),
        AppButton(
          'Тарихқа өту',
          kind: ButtonKind.secondary,
          onPressed: () => context.go('/history'),
        ),
      ],
    );
  }
}
