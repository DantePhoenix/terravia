import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/municipios.dart';
import 'insignias_page.dart';

const _kVisitados = 'visitados';

void main() => runApp(const MunicipiosApp());

class MunicipiosApp extends StatelessWidget {
  const MunicipiosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Municipios de Antioquia',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2E7D32),
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2E7D32),
        brightness: Brightness.dark,
      ),
      home: const HomePage(),
    );
  }
}

enum Filtro { todos, visitados, pendientes }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  SharedPreferences? _prefs;
  final Set<String> _visitados = {};
  String _busqueda = '';
  Filtro _filtro = Filtro.todos;
  int _pestana = 0;

  int get _total =>
      subregiones.values.fold(0, (suma, lista) => suma + lista.length);

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _prefs = prefs;
      _visitados.addAll(prefs.getStringList(_kVisitados) ?? []);
    });
  }

  Future<void> _alternar(String municipio, bool valor) async {
    setState(() {
      valor ? _visitados.add(municipio) : _visitados.remove(municipio);
    });
    await _prefs?.setStringList(_kVisitados, _visitados.toList());

    // Si con este municipio se completó una subregión, se avisa de la insignia.
    if (valor && mounted) {
      for (final e in subregiones.entries) {
        if (e.value.contains(municipio) && insigniaGanada(e.key, _visitados)) {
          mostrarInsignia(context, e.key);
          break;
        }
      }
    }
  }

  bool _pasaFiltro(String m) {
    if (_busqueda.isNotEmpty &&
        !_sinTildes(m).contains(_sinTildes(_busqueda))) {
      return false;
    }
    switch (_filtro) {
      case Filtro.visitados:
        return _visitados.contains(m);
      case Filtro.pendientes:
        return !_visitados.contains(m);
      case Filtro.todos:
        return true;
    }
  }

  String _sinTildes(String s) => s
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ü', 'u');

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_prefs == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final hayBusqueda = _busqueda.isNotEmpty;
    final secciones = <Widget>[];
    for (final e in subregiones.entries) {
      final visibles = e.value.where(_pasaFiltro).toList();
      if (visibles.isEmpty) continue;
      secciones.add(
        _SubregionCard(
          key: ValueKey('${e.key}-$hayBusqueda'),
          nombre: e.key,
          todos: e.value,
          visibles: visibles,
          visitados: _visitados,
          filtro: _filtro,
          expandido: hayBusqueda,
          onChanged: _alternar,
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _pestana,
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _encabezado(cs)),
                SliverToBoxAdapter(child: _buscador()),
                SliverToBoxAdapter(child: _filtros()),
                if (secciones.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text('Sin resultados')),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(secciones),
                    ),
                  ),
              ],
            ),
            InsigniasPage(visitados: _visitados),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _pestana,
        onDestinationSelected: (i) => setState(() => _pestana = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Lista',
          ),
          NavigationDestination(
            icon: Icon(Icons.workspace_premium_outlined),
            selectedIcon: Icon(Icons.workspace_premium),
            label: 'Insignias',
          ),
        ],
      ),
    );
  }

  Widget _encabezado(ColorScheme cs) {
    final n = _visitados.length;
    final progreso = n / _total;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            height: 84,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: progreso,
                    strokeWidth: 9,
                    strokeCap: StrokeCap.round,
                    backgroundColor: cs.onPrimaryContainer.withValues(
                      alpha: 0.15,
                    ),
                  ),
                ),
                Text(
                  '${(progreso * 100).round()}%',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: cs.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Antioquia',
                  style: TextStyle(
                    fontSize: 14,
                    color: cs.onPrimaryContainer.withValues(alpha: 0.8),
                  ),
                ),
                Text(
                  '$n de $_total',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: cs.onPrimaryContainer,
                  ),
                ),
                Text(
                  'municipios visitados',
                  style: TextStyle(color: cs.onPrimaryContainer),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buscador() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SearchBar(
        hintText: 'Buscar municipio',
        leading: const Icon(Icons.search),
        elevation: const WidgetStatePropertyAll(0),
        onChanged: (v) => setState(() => _busqueda = v.trim()),
      ),
    );
  }

  Widget _filtros() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SegmentedButton<Filtro>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(value: Filtro.todos, label: Text('Todos')),
          ButtonSegment(value: Filtro.visitados, label: Text('Visitados')),
          ButtonSegment(value: Filtro.pendientes, label: Text('Pendientes')),
        ],
        selected: {_filtro},
        onSelectionChanged: (s) => setState(() => _filtro = s.first),
      ),
    );
  }
}

class _SubregionCard extends StatelessWidget {
  const _SubregionCard({
    super.key,
    required this.nombre,
    required this.todos,
    required this.visibles,
    required this.visitados,
    required this.filtro,
    required this.expandido,
    required this.onChanged,
  });

  final String nombre;
  final List<String> todos;
  final List<String> visibles;
  final Set<String> visitados;
  final Filtro filtro;
  final bool expandido;
  final Future<void> Function(String, bool) onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final nVisitados = todos.where(visitados.contains).length;
    final n = filtro == Filtro.pendientes
        ? todos.length - nVisitados
        : nVisitados;
    final completa = nVisitados == todos.length;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(top: 12),
      color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: expandido,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          title: Text(
            nombre,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: n / todos.length,
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text('$n/${todos.length}'),
              ],
            ),
          ),
          leading: Icon(
            completa ? Icons.verified : Icons.location_on_outlined,
            color: completa ? cs.primary : cs.onSurfaceVariant,
          ),
          children: [
            for (final m in visibles)
              CheckboxListTile(
                value: visitados.contains(m),
                onChanged: (v) => onChanged(m, v ?? false),
                title: Text(m),
                controlAffinity: ListTileControlAffinity.trailing,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
          ],
        ),
      ),
    );
  }
}
