import 'package:flutter/material.dart';

import 'data/municipios.dart';

/// Ícono y color de la insignia de cada subregión.
const Map<String, ({IconData icono, Color color})> _estilos = {
  'Valle de Aburrá': (icono: Icons.location_city, color: Color(0xFF1E88E5)),
  'Oriente': (icono: Icons.terrain, color: Color(0xFF43A047)),
  'Norte': (icono: Icons.agriculture, color: Color(0xFFF9A825)),
  'Nordeste': (icono: Icons.forest, color: Color(0xFF00897B)),
  'Magdalena Medio': (icono: Icons.water, color: Color(0xFF039BE5)),
  'Occidente': (icono: Icons.wb_sunny, color: Color(0xFFEF6C00)),
  'Suroeste': (icono: Icons.coffee, color: Color(0xFF6D4C41)),
  'Bajo Cauca': (icono: Icons.diamond, color: Color(0xFF8E24AA)),
  'Urabá': (icono: Icons.beach_access, color: Color(0xFFD81B60)),
};

/// Estilo de la insignia final de Antioquia.
const _estiloFinal = (icono: Icons.workspace_premium, color: Color(0xFFFFB300));

({IconData icono, Color color}) _estiloDe(String region) =>
    _estilos[region] ??
    (icono: Icons.emoji_events, color: const Color(0xFF2E7D32));

/// Una subregión gana su insignia cuando todos sus municipios
/// están verificados por GPS.
bool insigniaGpsGanada(String region, Set<String> verificadosGps) {
  final lista = subregiones[region];
  return lista != null && lista.every(verificadosGps.contains);
}

/// Aviso que aparece al completar una subregión por GPS.
Future<void> mostrarInsignia(BuildContext context, String region) {
  final estilo = _estiloDe(region);

  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      icon: _Medalla(estilo: estilo, ganada: true, tamano: 96),
      title: const Text('¡Insignia ganada!'),
      content: Text(
        'Verificaste por GPS todos los municipios de $region.',
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Genial'),
        ),
      ],
    ),
  );
}

/// Aviso que aparece al verificar por GPS todos los municipios de Antioquia.
Future<void> mostrarInsigniaFinal(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      icon: _Medalla(estilo: _estiloFinal, ganada: true, tamano: 104),
      title: const Text(
        '¡Explorador de Antioquia!',
        textAlign: TextAlign.center,
      ),
      content: const Text(
        'Verificaste por GPS todos los municipios de Antioquia. '
        '¡Has completado el recorrido!',
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('¡Genial!'),
        ),
      ],
    ),
  );
}

class InsigniasPage extends StatelessWidget {
  const InsigniasPage({super.key, required this.verificadosGps});

  final Set<String> verificadosGps;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final regiones = subregiones.keys.toList();

    // Todos los municipios definidos en las subregiones.
    final municipios = subregiones.values.expand((lista) => lista).toSet();

    final totalMunicipios = municipios.length;
    final totalGps = municipios.where(verificadosGps.contains).length;

    final antioquiaCompleta =
        totalMunicipios > 0 && totalGps == totalMunicipios;

    final ganadas = regiones
        .where((r) => insigniaGpsGanada(r, verificadosGps))
        .length;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Insignias',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '$ganadas de ${regiones.length} insignias regionales ganadas.\n'
                  '$totalGps de $totalMunicipios municipios verificados por GPS.',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: 200,
            ),
            itemCount: regiones.length + 1,
            itemBuilder: (context, i) {
              // La última tarjeta es la insignia final de Antioquia.
              if (i == regiones.length) {
                return _TarjetaInsigniaFinal(
                  verificados: totalGps,
                  total: totalMunicipios,
                  ganada: antioquiaCompleta,
                );
              }

              final region = regiones[i];
              final lista = subregiones[region]!;

              final nVerificados = lista.where(verificadosGps.contains).length;

              return _TarjetaInsignia(
                region: region,
                verificados: nVerificados,
                total: lista.length,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TarjetaInsignia extends StatelessWidget {
  const _TarjetaInsignia({
    required this.region,
    required this.verificados,
    required this.total,
  });

  final String region;
  final int verificados;
  final int total;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final estilo = _estiloDe(region);
    final ganada = verificados == total;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: ganada
          ? estilo.color.withValues(alpha: 0.12)
          : cs.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Medalla(estilo: estilo, ganada: ganada, tamano: 76),
            const SizedBox(height: 10),
            Text(
              region,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : verificados / total,
                minHeight: 6,
                color: ganada ? estilo.color : null,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              ganada ? 'Completada por GPS' : '$verificados/$total GPS',
              style: TextStyle(
                fontSize: 13,
                color: ganada ? estilo.color : cs.onSurfaceVariant,
                fontWeight: ganada ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaInsigniaFinal extends StatelessWidget {
  const _TarjetaInsigniaFinal({
    required this.verificados,
    required this.total,
    required this.ganada,
  });

  final int verificados;
  final int total;
  final bool ganada;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: ganada
          ? _estiloFinal.color.withValues(alpha: 0.14)
          : cs.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Medalla(estilo: _estiloFinal, ganada: ganada, tamano: 76),
            const SizedBox(height: 10),
            const Text(
              'Explorador de Antioquia',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : verificados / total,
                minHeight: 6,
                color: ganada ? _estiloFinal.color : null,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              ganada ? '¡Completada por GPS!' : '$verificados/$total GPS',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: ganada ? _estiloFinal.color : cs.onSurfaceVariant,
                fontWeight: ganada ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Medalla extends StatelessWidget {
  const _Medalla({
    required this.estilo,
    required this.ganada,
    required this.tamano,
  });

  final ({IconData icono, Color color}) estilo;
  final bool ganada;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      width: tamano,
      height: tamano,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: tamano,
            height: tamano,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ganada ? estilo.color : cs.surfaceContainerHighest,
              border: Border.all(
                color: ganada
                    ? estilo.color.withValues(alpha: 0.35)
                    : cs.outlineVariant,
                width: 4,
              ),
            ),
            child: Icon(
              estilo.icono,
              size: tamano * 0.45,
              color: ganada
                  ? Colors.white
                  : cs.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.surface,
              ),
              child: Icon(
                ganada ? Icons.verified : Icons.lock_outline,
                size: tamano * 0.26,
                color: ganada ? estilo.color : cs.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
