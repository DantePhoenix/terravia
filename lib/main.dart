import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/municipios.dart';
import 'data/ubicaciones.dart';
import 'data/verificaciones.dart';
import 'insignias_page.dart';

const _kVisitados = 'visitados';
const _kVerificadosGps = 'verificados_gps';
const _kRegistro = 'registro_verificaciones';

const _meses = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

/// Ejemplo: "1 nov 2026, 22:12".
String _formatoFecha(DateTime f) {
  final hora = f.hour.toString().padLeft(2, '0');
  final min = f.minute.toString().padLeft(2, '0');
  return '${f.day} ${_meses[f.month - 1]} ${f.year}, $hora:$min';
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  runApp(const MunicipiosApp());
}

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

  // Municipios marcados como visitados.
  final Set<String> _visitados = {};

  // Municipios cuya visita fue verificada por GPS.
  final Set<String> _verificadosGps = {};

  // Fecha y coordenadas de la última verificación de cada municipio.
  final Map<String, Verificacion> _registro = {};

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

  // Cargar los datos guardados.
  Future<void> _cargar() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _prefs = prefs;

      _visitados.addAll(prefs.getStringList(_kVisitados) ?? []);

      _verificadosGps.addAll(prefs.getStringList(_kVerificadosGps) ?? []);

      for (final v in Verificacion.decodificar(prefs.getString(_kRegistro))) {
        _registro[v.municipio] = v;
      }
    });
  }

  // Guardar los tres estados en el dispositivo.
  Future<void> _guardar() async {
    await _prefs?.setStringList(_kVisitados, _visitados.toList());

    await _prefs?.setStringList(_kVerificadosGps, _verificadosGps.toList());

    await _prefs?.setString(
      _kRegistro,
      Verificacion.codificar(_registro.values),
    );
  }

  // Verificación más reciente de todas, o null si no hay ninguna.
  Verificacion? get _ultimaVerificacion {
    Verificacion? ultima;

    for (final v in _registro.values) {
      if (ultima == null || v.fecha.isAfter(ultima.fecha)) {
        ultima = v;
      }
    }

    return ultima;
  }

  // Marcar o desmarcar manualmente un municipio.
  Future<void> _alternar(String municipio, bool valor) async {
    setState(() {
      if (valor) {
        _visitados.add(municipio);
      } else {
        _visitados.remove(municipio);

        // Al desmarcarlo, también se elimina su verificación GPS.
        _verificadosGps.remove(municipio);
        _registro.remove(municipio);
      }
    });

    await _guardar();
  }

  // Verificar que el usuario se encuentre en el municipio.
  Future<void> _verificarPorGps(String municipio) async {
    if (!puntosMunicipios.containsKey(municipio)) {
      _mostrarMensaje(
        'Todavía no tenemos ubicación GPS configurada para $municipio.',
      );
      return;
    }

    // Comprobar que el servicio de ubicación esté activo.
    final servicioActivo = await Geolocator.isLocationServiceEnabled();

    if (!servicioActivo) {
      _mostrarMensaje('Activa la ubicación GPS de tu dispositivo.');
      return;
    }

    // Comprobar permisos de ubicación.
    var permiso = await Geolocator.checkPermission();

    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }

    if (permiso == LocationPermission.denied ||
        permiso == LocationPermission.deniedForever) {
      _mostrarMensaje(
        'Necesitamos permiso de ubicación para verificar la visita.',
      );
      return;
    }

    try {
      // Obtener la ubicación actual.
      final posicion = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );

      // Rechazar ubicaciones simuladas o lecturas viejas.
      final errorLectura = validarLectura(posicion);

      if (errorLectura != null) {
        _mostrarMensaje(errorLectura);
        return;
      }

      // Comparar con los puntos y radios del municipio.
      final evaluacion = evaluarUbicacion(
        municipio,
        posicion.latitude,
        posicion.longitude,
      );

      // Rechazar si está fuera del radio permitido.
      if (evaluacion == null || !evaluacion.dentro) {
        final km = ((evaluacion?.distanciaMetros ?? 0) / 1000).toStringAsFixed(
          1,
        );

        _mostrarMensaje(
          'Estás a $km km aproximadamente de $municipio. '
          'Debes estar dentro del área permitida para verificar la visita.',
        );
        return;
      }

      // Rechazar saltos imposibles respecto a la verificación anterior.
      final errorCoherencia = validarCoherencia(posicion, _ultimaVerificacion);

      if (errorCoherencia != null) {
        _mostrarMensaje(errorCoherencia);
        return;
      }

      if (!mounted) return;

      // Guardar qué insignias estaban completas antes de esta verificación.
      final regionesCompletadasAntes = subregiones.keys
          .where((region) => insigniaGpsGanada(region, _verificadosGps))
          .toSet();

      // Todos los municipios definidos en la aplicación.
      final todosLosMunicipios = subregiones.values
          .expand((lista) => lista)
          .toSet();

      // Comprobar si Antioquia ya estaba completa.
      final antioquiaCompletaAntes =
          todosLosMunicipios.isNotEmpty &&
          todosLosMunicipios.every(_verificadosGps.contains);

      // Registrar la visita como completada y verificada.
      setState(() {
        _visitados.add(municipio);
        _verificadosGps.add(municipio);
        _registro[municipio] = Verificacion(
          municipio: municipio,
          lat: posicion.latitude,
          lon: posicion.longitude,
          fecha: DateTime.now(),
        );
      });

      // Guardar los estados.
      await _guardar();

      _mostrarMensaje('¡Visita de $municipio verificada por GPS!');

      // Mostrar insignia regional solo si acaba de completarse.
      for (final e in subregiones.entries) {
        if (!e.value.contains(municipio)) continue;

        final completadaAhora = insigniaGpsGanada(e.key, _verificadosGps);

        if (!regionesCompletadasAntes.contains(e.key) &&
            completadaAhora &&
            mounted) {
          await mostrarInsignia(context, e.key);
          break;
        }
      }

      // Mostrar la insignia final solo al completar todos los municipios.
      final antioquiaCompletaAhora =
          todosLosMunicipios.isNotEmpty &&
          todosLosMunicipios.every(_verificadosGps.contains);

      if (!antioquiaCompletaAntes && antioquiaCompletaAhora && mounted) {
        await mostrarInsigniaFinal(context);
      }
    } catch (e) {
      _mostrarMensaje(
        'No fue posible obtener tu ubicación. Intenta nuevamente.',
      );
    }
  }

  // Mostrar mensajes al usuario.
  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
  }

  // Aplicar filtros de búsqueda y estado.
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
          verificadosGps: _verificadosGps,
          registro: _registro,
          filtro: _filtro,
          expandido: hayBusqueda,
          onChanged: _alternar,
          onVerifyGps: _verificarPorGps,
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
            InsigniasPage(verificadosGps: _verificadosGps),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _pestana,
        onDestinationSelected: (i) {
          setState(() => _pestana = i);
        },
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

  // Encabezado con progreso general.
  Widget _encabezado(ColorScheme cs) {
    final n = _visitados.length;
    final progreso = _total == 0 ? 0.0 : n / _total;

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

  // Buscador de municipios.
  Widget _buscador() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SearchBar(
        hintText: 'Buscar municipio',
        leading: const Icon(Icons.search),
        elevation: const WidgetStatePropertyAll(0),
        onChanged: (v) {
          setState(() => _busqueda = v.trim());
        },
      ),
    );
  }

  // Filtros Todos, Visitados y Pendientes.
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
        onSelectionChanged: (s) {
          setState(() => _filtro = s.first);
        },
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
    required this.verificadosGps,
    required this.registro,
    required this.filtro,
    required this.expandido,
    required this.onChanged,
    required this.onVerifyGps,
  });

  final String nombre;
  final List<String> todos;
  final List<String> visibles;
  final Set<String> visitados;
  final Set<String> verificadosGps;
  final Map<String, Verificacion> registro;
  final Filtro filtro;
  final bool expandido;

  // Texto de estado de un municipio visitado.
  String _estado(String m) {
    if (!verificadosGps.contains(m)) return 'Marcada manualmente';

    final v = registro[m];

    return v == null
        ? 'Verificada por GPS'
        : 'Verificada por GPS · ${_formatoFecha(v.fecha)}';
  }

  final Future<void> Function(String, bool) onChanged;
  final Future<void> Function(String) onVerifyGps;

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
                      value: todos.isEmpty ? 0 : n / todos.length,
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
              if (filtro == Filtro.todos)
                CheckboxListTile(
                  value: visitados.contains(m),
                  onChanged: (v) {
                    onChanged(m, v ?? false);
                  },
                  title: Text(m),
                  subtitle: visitados.contains(m) ? Text(_estado(m)) : null,
                  secondary: verificadosGps.contains(m)
                      ? const Icon(Icons.gps_fixed, color: Colors.green)
                      : IconButton(
                          tooltip: 'Verificar visita por GPS',
                          icon: const Icon(Icons.gps_not_fixed),
                          onPressed: () {
                            onVerifyGps(m);
                          },
                        ),
                  controlAffinity: ListTileControlAffinity.trailing,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                )
              else
                ListTile(
                  title: Text(m),
                  subtitle: Text(
                    filtro == Filtro.visitados
                        ? _estado(m)
                        : 'Pendiente de visitar',
                  ),
                  leading: Icon(
                    filtro == Filtro.visitados
                        ? verificadosGps.contains(m)
                              ? Icons.gps_fixed
                              : Icons.check_circle_outline
                        : Icons.radio_button_unchecked,
                    color: filtro == Filtro.visitados
                        ? cs.primary
                        : cs.onSurfaceVariant,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                ),
          ],
        ),
      ),
    );
  }
}
