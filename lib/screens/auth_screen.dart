import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/account.dart';
import '../state/eon_state.dart';
import '../theme/eon_theme.dart';
import '../widgets/widgets.dart';
import 'main_shell.dart';

/// Local Login / Sign Up. Everything stays on the device (see `Account`).
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();
  final _emailFocus = FocusNode();

  late bool _signUp = !context.eonRead.hasAccount;
  bool _obscure = true;
  bool _seedDemo = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final existing = context.eonRead.account;
    if (existing != null) _email.text = existing.email;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  void _setMode(bool signUp) {
    if (signUp == _signUp) return;
    setState(() {
      _signUp = signUp;
      _error = null;
    });
    _formKey.currentState?.reset();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    final state = context.eonRead;
    final error =
        _signUp
            ? await state.signUp(
              name: _name.text,
              email: _email.text,
              password: _password.text,
              seedDemoProgress: _seedDemo,
            )
            : await state.logIn(email: _email.text, password: _password.text);

    if (!mounted) return;
    if (error != null) {
      unawaited(HapticFeedback.heavyImpact());
      setState(() {
        _busy = false;
        _error = error;
      });
      return;
    }

    unawaited(HapticFeedback.mediumImpact());
    Navigator.of(
      context,
    ).pushAndRemoveUntil(eonRoute<void>(const MainShell()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = context.eon;
    final existing = s.account;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: p.overlayStyle,
      child: Scaffold(
        backgroundColor: p.background,
        body: EonBackground(
          child: SafeArea(
            child: Column(
              children: [
                EonHeader(
                  title: _signUp ? 'Awaken, Hunter' : 'Welcome Back',
                  icon: Icons.shield_moon_rounded,
                  onBack: () => Navigator.of(context).maybePop(),
                  trailing: const ThemeToggleButton(size: 24),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Form(
                      key: _formKey,
                      child: AutofillGroup(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Center(child: CrownIcon(size: 54)),
                            const SizedBox(height: 14),
                            Text(
                              _signUp
                                  ? 'Register to receive your daily quests.'
                                  : 'Your quests are waiting where you left them.',
                              textAlign: TextAlign.center,
                              style: eonText(
                                14.5,
                                color: p.textMuted,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 22),
                            EonTabs(
                              labels: const ['Login', 'Sign Up'],
                              index: _signUp ? 1 : 0,
                              onChanged: (i) => _setMode(i == 1),
                            ),
                            const SizedBox(height: 22),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 260),
                              curve: Curves.easeOutCubic,
                              alignment: Alignment.topCenter,
                              child:
                                  _signUp
                                      ? Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 14,
                                        ),
                                        child: TextFormField(
                                          controller: _name,
                                          textCapitalization:
                                              TextCapitalization.words,
                                          textInputAction: TextInputAction.next,
                                          autofillHints: const [
                                            AutofillHints.nickname,
                                          ],
                                          maxLength: 20,
                                          validator: AccountRules.name,
                                          onFieldSubmitted:
                                              (_) => _emailFocus.requestFocus(),
                                          style: eonText(16, color: p.text),
                                          decoration: const InputDecoration(
                                            labelText: 'Hunter name',
                                            counterText: '',
                                            prefixIcon: Icon(
                                              Icons.person_rounded,
                                            ),
                                          ),
                                        ),
                                      )
                                      : const SizedBox(width: double.infinity),
                            ),
                            TextFormField(
                              controller: _email,
                              focusNode: _emailFocus,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autocorrect: false,
                              autofillHints: const [AutofillHints.email],
                              validator: AccountRules.email,
                              onFieldSubmitted:
                                  (_) => _passwordFocus.requestFocus(),
                              style: eonText(16, color: p.text),
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.alternate_email_rounded),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _password,
                              focusNode: _passwordFocus,
                              obscureText: _obscure,
                              textInputAction: TextInputAction.done,
                              autofillHints: [
                                _signUp
                                    ? AutofillHints.newPassword
                                    : AutofillHints.password,
                              ],
                              validator: AccountRules.password,
                              onFieldSubmitted: (_) => _submit(),
                              style: eonText(16, color: p.text),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_rounded),
                                suffixIcon: IconButton(
                                  tooltip:
                                      _obscure
                                          ? 'Show password'
                                          : 'Hide password',
                                  onPressed:
                                      () =>
                                          setState(() => _obscure = !_obscure),
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_rounded
                                        : Icons.visibility_off_rounded,
                                  ),
                                ),
                              ),
                            ),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 260),
                              curve: Curves.easeOutCubic,
                              alignment: Alignment.topCenter,
                              child:
                                  _signUp
                                      ? Column(
                                        children: [
                                          const SizedBox(height: 16),
                                          GlassCard(
                                            padding: const EdgeInsets.fromLTRB(
                                              14,
                                              6,
                                              8,
                                              6,
                                            ),
                                            child: SwitchListTile(
                                              value: _seedDemo,
                                              onChanged:
                                                  (v) => setState(
                                                    () => _seedDemo = v,
                                                  ),
                                              contentPadding: EdgeInsets.zero,
                                              title: Text(
                                                'Start with demo progress',
                                                style: eonText(
                                                  15,
                                                  weight: FontWeight.w600,
                                                ),
                                              ),
                                              subtitle: Text(
                                                'A 14-day streak and sample stats, '
                                                'so every screen has data.',
                                                style: eonText(
                                                  12.5,
                                                  color: p.textMuted,
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (existing != null) ...[
                                            const SizedBox(height: 12),
                                            _Notice(
                                              icon: Icons.info_outline_rounded,
                                              text:
                                                  'Signing up replaces '
                                                  '${existing.name}, the hunter '
                                                  'saved on this device.',
                                            ),
                                          ],
                                        ],
                                      )
                                      : const SizedBox(width: double.infinity),
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child:
                                  _error == null
                                      ? const SizedBox(height: 22)
                                      : Padding(
                                        key: ValueKey(_error),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        child: _Notice(
                                          icon: Icons.error_outline_rounded,
                                          text: _error!,
                                          error: true,
                                        ),
                                      ),
                            ),
                            GlowButton(
                              label:
                                  _signUp ? 'Begin My Quest' : 'Enter the Gate',
                              leading: const CrownIcon(),
                              loading: _busy,
                              onPressed: _submit,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Your account and progress are stored only on '
                              'this phone.',
                              textAlign: TextAlign.center,
                              style: eonText(12, color: p.textFaint),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text, this.error = false});

  final IconData icon;
  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = error ? Theme.of(context).colorScheme.error : p.highlight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: eonText(13.5, color: p.text, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
