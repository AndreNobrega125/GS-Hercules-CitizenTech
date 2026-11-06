import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/auth_repository.dart';
import '../../state/auth_provider.dart';
import '../../state/territory_provider.dart';

/// Login simulado com dois perfis de demonstração.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hidden = true;
  bool _busy = false;
  String? _error;

  static final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final territory = context.read<TerritoryProvider>();
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await auth.login(_email.text, _password.text);
    if (!mounted) return;
    if (ok) {
      // O roteador leva ao app; aqui só carregamos os dados do perfil.
      await territory.useUser(auth.user!);
    } else {
      setState(() {
        _busy = false;
        _error = 'E-mail ou senha incorretos.';
      });
    }
  }

  void _fill(DemoAccount a) {
    _email.text = a.profile.email;
    _password.text = a.password;
    setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Entrar')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Semantics(
                  header: true,
                  child: Text('Radar do Território', style: text.headlineMedium),
                ),
                const SizedBox(height: 8),
                Text(
                  'Entre para ver seus municípios e manter seus dados neste aparelho.',
                  style: text.bodyLarge,
                ),
                const SizedBox(height: 24),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.isEmpty) return 'Informe o e-mail.';
                          if (!_emailRe.hasMatch(value)) {
                            return 'E-mail inválido. Exemplo: nome@dominio.com';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _password,
                        obscureText: _hidden,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            tooltip: _hidden ? 'Mostrar senha' : 'Ocultar senha',
                            icon: Icon(
                              _hidden ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () => setState(() => _hidden = !_hidden),
                          ),
                        ),
                        validator: (v) {
                          final value = v ?? '';
                          if (value.isEmpty) return 'Informe a senha.';
                          if (value.length < 6) {
                            return 'A senha tem pelo menos 6 caracteres.';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Semantics(
                    liveRegion: true,
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: Theme.of(context).colorScheme.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: const Text('Entrar'),
                ),
                const SizedBox(height: 28),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Contas de demonstração', style: text.titleMedium),
                        const SizedBox(height: 4),
                        const Text(
                          'Login simulado, só neste aparelho. Não é segurança real: '
                          'serve para mostrar perfis diferentes. Toque para preencher.',
                        ),
                        const SizedBox(height: 8),
                        for (final a in AuthRepository.accounts)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.account_circle),
                            title: Text(a.profile.name),
                            subtitle: Text(a.profile.role),
                            onTap: () => _fill(a),
                          ),
                      ],
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
