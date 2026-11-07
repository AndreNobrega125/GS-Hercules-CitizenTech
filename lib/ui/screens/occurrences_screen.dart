import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app/router.dart';
import '../../core/validators.dart';
import '../../data/models/occurrence.dart';
import '../../state/territory_provider.dart';
import '../../state/user_data_provider.dart';
import '../widgets/empty_state.dart';

/// Lista das ocorrências registradas neste aparelho, com formulário de novo registro.
class OccurrencesScreen extends StatelessWidget {
  const OccurrencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = context.watch<UserDataProvider>().occurrences;
    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    return Scaffold(
      appBar: AppBar(title: const Text('Ocorrências')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Registrar'),
        onPressed: () => context.pushNamed(Routes.occurrenceNew),
      ),
      body: items.isEmpty
          ? const EmptyState(
              icon: Icons.edit_note,
              message: 'Nenhuma ocorrência registrada. Toque em Registrar.',
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final o = items[i];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.report_problem_outlined),
                    title: Text('${o.type.label} · ${o.territoryName}'),
                    subtitle: Text(
                      '${o.neighborhood == null ? '' : 'Bairro: ${o.neighborhood}\n'}'
                      '${o.description}\n${fmt.format(o.createdAt)}',
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      tooltip: 'Apagar ocorrência',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => context
                          .read<UserDataProvider>()
                          .removeOccurrence(o.id),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class OccurrenceFormScreen extends StatefulWidget {
  const OccurrenceFormScreen({super.key});

  @override
  State<OccurrenceFormScreen> createState() => _OccurrenceFormScreenState();
}

class _OccurrenceFormScreenState extends State<OccurrenceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _neighborhood = TextEditingController();
  OccurrenceType? _type;

  @override
  void dispose() {
    _description.dispose();
    _neighborhood.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await context.read<UserDataProvider>().addOccurrence(
          type: _type!,
          description: _description.text,
          neighborhood: _neighborhood.text,
          territory: context.read<TerritoryProvider>().territory,
        );
    messenger.showSnackBar(
      const SnackBar(content: Text('Ocorrência salva neste aparelho.')),
    );
    router.pop();
  }

  @override
  Widget build(BuildContext context) {
    final city = context.watch<TerritoryProvider>().territory;
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar ocorrência')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Município: ${city.label}'),
            const SizedBox(height: 4),
            const Text(
              'Registro anônimo: não guardamos nome, contato nem localização exata.',
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<OccurrenceType>(
              isExpanded: true,
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'Tipo de ocorrência',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final t in OccurrenceType.values)
                  DropdownMenuItem(value: t, child: Text(t.label)),
              ],
              onChanged: (v) => setState(() => _type = v),
              validator: (v) => v == null ? 'Escolha o tipo.' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _neighborhood,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Bairro (opcional)',
                border: OutlineInputBorder(),
              ),
              validator: Validators.neighborhood,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _description,
              maxLines: 4,
              maxLength: 280,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              validator: Validators.description,
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('Salvar ocorrência'),
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
