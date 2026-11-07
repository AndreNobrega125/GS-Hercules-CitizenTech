import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/territory.dart';
import '../../data/models/locality.dart';
import '../../state/territory_provider.dart';
import '../../state/user_data_provider.dart';

/// Escolha de estado (UF) e município monitorado.
class TerritoryPickerScreen extends StatefulWidget {
  const TerritoryPickerScreen({super.key});

  @override
  State<TerritoryPickerScreen> createState() => _TerritoryPickerScreenState();
}

class _TerritoryPickerScreenState extends State<TerritoryPickerScreen> {
  List<UfInfo>? _states;
  List<Municipality>? _cities;
  String? _uf;
  String _query = '';
  bool _loadingCities = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _uf = context.read<TerritoryProvider>().territory.uf;
    _loadStates();
  }

  Future<void> _loadStates() async {
    final repo = context.read<TerritoryProvider>().repository;
    try {
      final states = await repo.states();
      if (!mounted) return;
      setState(() {
        _states = states;
        _error = null;
      });
      await _loadCities(_uf!);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Sem conexão e sem lista salva. Tente de novo.');
      }
    }
  }

  Future<void> _loadCities(String uf) async {
    final repo = context.read<TerritoryProvider>().repository;
    setState(() {
      _uf = uf;
      _cities = null;
      _loadingCities = true;
      _query = '';
    });
    try {
      final cities = await repo.municipalities(uf);
      if (!mounted || _uf != uf) return;
      setState(() {
        _cities = cities;
        _loadingCities = false;
        _error = null;
      });
    } catch (_) {
      if (mounted && _uf == uf) {
        setState(() {
          _loadingCities = false;
          _error = 'Não foi possível carregar os municípios.';
        });
      }
    }
  }

  Future<void> _select(Municipality m) async {
    final provider = context.read<TerritoryProvider>();
    final router = GoRouter.of(context);
    // Não exibe cidade do estado errado: usa a UF atualmente escolhida.
    provider.changeTerritory(
      Territory(ibgeCode: m.ibgeCode, name: m.nome, uf: _uf!),
    );
    router.pop();
  }

  @override
  Widget build(BuildContext context) {
    final current = context.watch<TerritoryProvider>().territory;
    final userData = context.watch<UserDataProvider>();
    final q = _query.trim().toLowerCase();
    final filtered = _cities
        ?.where((c) => q.isEmpty || c.nome.toLowerCase().contains(q))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Escolher município')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Monitorando: ${current.label}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (userData.favorites.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Favoritos', style: Theme.of(context).textTheme.labelLarge),
              Wrap(
                spacing: 8,
                children: [
                  for (final f in userData.favorites)
                    ActionChip(
                      avatar: const Icon(Icons.star, size: 18),
                      label: Text(f.label),
                      onPressed: () {
                        context.read<TerritoryProvider>().changeTerritory(f);
                        context.pop();
                      },
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            if (_states != null)
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _uf,
                decoration: const InputDecoration(
                  labelText: 'Estado',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final s in _states!)
                    DropdownMenuItem(
                      value: s.sigla,
                      child: Text('${s.nome} (${s.sigla})'),
                    ),
                ],
                onChanged: (v) {
                  if (v != null && v != _uf) _loadCities(v);
                },
              ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar município',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 8),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_off),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!)),
                    TextButton(
                      onPressed: _states == null
                          ? _loadStates
                          : () => _loadCities(_uf!),
                      child: const Text('Tentar de novo'),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _loadingCities || (_states == null && _error == null)
                  ? const Center(child: CircularProgressIndicator())
                  : filtered == null
                      ? const SizedBox.shrink()
                      : filtered.isEmpty
                          ? const Center(child: Text('Nenhum município encontrado.'))
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (_, i) {
                                final m = filtered[i];
                                final selected = m.ibgeCode == current.ibgeCode;
                                return ListTile(
                                  title: Text(m.nome),
                                  trailing: IconButton(
                                    tooltip: userData.isFavorite(m.ibgeCode)
                                        ? 'Remover ${m.nome} dos favoritos'
                                        : 'Favoritar ${m.nome}',
                                    icon: Icon(
                                      userData.isFavorite(m.ibgeCode)
                                          ? Icons.star
                                          : Icons.star_border,
                                    ),
                                    onPressed: () => userData.toggleFavorite(
                                      Territory(
                                        ibgeCode: m.ibgeCode,
                                        name: m.nome,
                                        uf: _uf!,
                                      ),
                                    ),
                                  ),
                                  selected: selected,
                                  onTap: () => _select(m),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
