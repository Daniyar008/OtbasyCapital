import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_scope.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/auth_errors.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/result_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Отбасы капиталы',
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 110),
        decoration: BoxDecoration(
          color: AppColors.green,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const AppIcon('home'),
            ),
            const SizedBox(height: 22),
            const Text('Отбасы\nкапиталы', style: AppTheme.amount),
            const SizedBox(height: 22),
            Text(
              'Отбасы бюджеті бір жерде',
              style: AppTheme.body.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
      AppButton('Бастау', onPressed: () => context.go('/login')),
      AppButton(
        'Қолданбамен танысу',
        kind: ButtonKind.secondary,
        onPressed: () => context.push('/onboarding/1'),
      ),
    ],
  );
}

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key, required this.step});
  final int step;
  @override
  Widget build(BuildContext context) => AppPage(
    title: step == 1 ? 'Кіріс пен шығыс' : 'Ортақ мақсат',
    back: step == 1 ? '/' : '/onboarding/1',
    children: [
      if (step == 1)
        const BalanceCard(
          label: 'Жалпы қалдық',
          amount: '225 000 ₸',
          caption: '350 000 ₸ кіріс · 125 000 ₸ шығыс',
        )
      else
        const BalanceCard(
          label: 'Отбасылық демалыс',
          amount: '150 000 ₸',
          caption: '500 000 ₸ мақсат · 30%',
        ),
      Text(
        step == 1 ? 'Кіріс пен шығысты бақылаңыз' : 'Мақсатқа бірге жетіңіз',
        style: AppTheme.title,
      ),
      Text(
        step == 1
            ? 'Күнделікті операцияларды енгізіп, отбасы бюджетінің өзгерісін көріңіз.'
            : 'Ортақ бюджет жүргізіп, жеке жазбаларыңыздың құпиялығын сақтаңыз.',
        style: AppTheme.body.copyWith(color: AppColors.muted),
      ),
      Text(step == 1 ? '01 / 02' : '02 / 02', style: AppTheme.caption),
      AppButton(
        step == 1 ? 'Келесі' : 'Аккаунт ашу',
        onPressed: () =>
            context.push(step == 1 ? '/onboarding/2' : '/register'),
      ),
      AppButton(
        step == 1 ? 'Өткізу' : 'Кіру',
        kind: ButtonKind.secondary,
        onPressed: () => context.go('/login'),
      ),
    ],
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController(text: 'daniyar@example.com');
  final _password = TextEditingController(text: 'Demo2026');
  bool _hidden = true, _busy = false, _initialized = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized && AppScope.of(context).cloudEnabled) {
      _email.clear();
      _password.clear();
    }
    _initialized = true;
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await AppScope.of(context).login(_email.text, _password.text);
      if (mounted) context.go('/home');
    } catch (error) {
      if (mounted) showMessage(context, authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Қайта қош келдіңіз!',
    formKey: _form,
    children: [
      Text(
        'Отбасыңыздың қаржысын бірге басқарыңыз.',
        style: AppTheme.body.copyWith(color: AppColors.muted),
      ),
      AppField(
        'Email',
        controller: _email,
        validator: Validators.email,
        keyboardType: TextInputType.emailAddress,
        inputKey: const ValueKey('email'),
      ),
      AppField(
        'Құпиясөз',
        controller: _password,
        validator: Validators.password,
        obscure: _hidden,
        inputKey: const ValueKey('password'),
        suffix: IconButton(
          tooltip: _hidden ? 'Құпиясөзді көрсету' : 'Құпиясөзді жасыру',
          onPressed: () => setState(() => _hidden = !_hidden),
          icon: Icon(
            _hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          ),
        ),
      ),
      AppButton('Кіру', busy: _busy, onPressed: _login),
      AppButton(
        'Құпиясөзді ұмыттыңыз ба?',
        kind: ButtonKind.quiet,
        onPressed: () => context.push('/reset-password'),
      ),
      AppButton(
        'Жаңа аккаунт ашу',
        kind: ButtonKind.secondary,
        onPressed: () => context.push('/register'),
      ),
      Text(
        AppScope.of(context).cloudEnabled
            ? 'Тіркелген email мен құпиясөзіңізді енгізіңіз.'
            : 'Оқу режимі. Email мен құпиясөз серверде тексерілмейді. '
                  'Мысал: daniyar@example.com / Demo2026.',
        style: AppTheme.caption,
      ),
    ],
  );
}

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});
  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _repeat = TextEditingController();
  bool _busy = false;

  Future<void> _register() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final ready = await AppScope.of(context)
          .register(_email.text, _password.text, _name.text);
      if (!mounted) return;
      if (ready) {
        context.go('/family-setup');
      } else {
        context.go(
          '/result',
          extra: const ResultData(
            title: 'Email мекенжайын растаңыз',
            message:
                'Тіркелу сұрауы қабылданды. Email-ге келген сілтемені ашып, '
                'осы қосымшаға оралыңыз және құпиясөзіңізбен кіріңіз.',
            destination: '/login',
            button: 'Кіруге өту',
          ),
        );
      }
    } catch (error) {
      if (mounted) showMessage(context, authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _email, _password, _repeat]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Аккаунт ашу',
    back: '/login',
    formKey: _form,
    children: [
      AppField(
        'Атыңыз',
        controller: _name,
        validator: Validators.required,
        hint: 'Атыңызды енгізіңіз',
        inputKey: const ValueKey('register-name'),
      ),
      AppField(
        'Email',
        controller: _email,
        validator: Validators.email,
        keyboardType: TextInputType.emailAddress,
        hint: 'name@example.com',
        inputKey: const ValueKey('register-email'),
      ),
      AppField(
        'Құпиясөз',
        controller: _password,
        validator: Validators.newPassword,
        obscure: true,
        inputKey: const ValueKey('register-password'),
      ),
      AppField(
        'Құпиясөзді қайталаңыз',
        controller: _repeat,
        obscure: true,
        inputKey: const ValueKey('register-repeat'),
        validator: (value) => value != _password.text || value!.isEmpty
            ? 'Құпиясөздер сәйкес келмейді.'
            : null,
      ),
      const Text(
        'Кемінде 8 таңба, бір сан және бір бас әріп.',
        style: AppTheme.caption,
      ),
      AppButton('Тіркелу', busy: _busy, onPressed: _register),
      Text(
        AppScope.of(context).cloudEnabled
            ? 'Аккаунт Supabase жүйесінде тіркеледі. Email-ді растау қажет болуы мүмкін.'
            : 'Оқу нұсқасында тіркелу интерфейсі көрсетіледі. '
                  'Нақты серверлік аккаунт құрылмайды.',
        style: AppTheme.caption,
      ),
    ],
  );
}

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});
  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Құпиясөзді қалпына келтіру',
    back: '/login',
    formKey: _form,
    children: [
      const Text('Тіркелген email мекенжайыңызды енгізіңіз.'),
      AppField(
        'Email',
        controller: _email,
        validator: Validators.email,
        hint: 'name@example.com',
        keyboardType: TextInputType.emailAddress,
      ),
      AppButton(
        'Сілтеме жіберу',
        onPressed: () {
          if (!_form.currentState!.validate()) return;
          context.push(
            '/result',
            extra: const ResultData(
              title: 'Email тексерілді',
              message:
                  'Email пішімі дұрыс. Бұл оқу нұсқасында '
                  'қалпына келтіру хаты жіберілмейді.',
              destination: '/login',
              button: 'Кіруге оралу',
            ),
          );
        },
      ),
    ],
  );
}

class FamilySetupScreen extends StatefulWidget {
  const FamilySetupScreen({super.key});
  @override
  State<FamilySetupScreen> createState() => _FamilySetupScreenState();
}

class _FamilySetupScreenState extends State<FamilySetupScreen> {
  final _createForm = GlobalKey<FormState>(),
      _joinForm = GlobalKey<FormState>();
  final _name = TextEditingController(), _code = TextEditingController();
  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Отбасымен бастау',
    back: '/register',
    children: [
      const Align(alignment: Alignment.centerLeft, child: AppIcon('home')),
      const Text('Бюджетті бірге жүргізіңіз', style: AppTheme.title),
      Form(
        key: _createForm,
        child: Column(
          children: [
            AppField(
              'Отбасы атауы',
              controller: _name,
              validator: Validators.required,
            ),
            const SizedBox(height: 20),
            AppButton(
              'Отбасын құру',
              onPressed: () async {
                if (!_createForm.currentState!.validate()) return;
                await AppScope.of(context).setFamily(_name.text);
                if (context.mounted) context.go('/home');
              },
            ),
          ],
        ),
      ),
      if (!AppScope.of(context).cloudEnabled)
        Form(
          key: _joinForm,
          child: Column(
            children: [
              AppField(
                'Шақыру коды',
                controller: _code,
                hint: 'OTB-2026',
                validator: (value) => value?.trim().toUpperCase() == 'OTB-2026'
                    ? null
                    : 'Оқу мысалының коды: OTB-2026',
              ),
              const SizedBox(height: 20),
              AppButton(
                'Отбасына қосылу',
                kind: ButtonKind.secondary,
                onPressed: () async {
                  if (!_joinForm.currentState!.validate()) return;
                  await AppScope.of(context).setFamily('Сұлтангереевтер');
                  if (context.mounted) context.go('/home');
                },
              ),
            ],
          ),
        ),
      Text(
        AppScope.of(context).cloudEnabled
            ? 'Отбасы деректері аккаунтыңызда сақталады. Басқа аккаунттарды шақыру әзірге қосылмаған.'
            : 'Жеке жазба тек оның иесіне қолжетімді. '
                  'Бұл нұсқада отбасы деректері осы құрылғыда сақталады.',
        style: AppTheme.caption,
      ),
    ],
  );
}
