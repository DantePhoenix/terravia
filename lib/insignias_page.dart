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

({IconData icono, Color color}) _estiloDe(String region) =>
    _estilos[region] ?? (icono: Icons.emoji_events, color: const Color(0xFF2E7D32));

/// Una subregión tiene su insignia cuando todos sus municipios están visitados.
bool insigniaGanada(String region, Set<String> visitados) {
  final lista = subregiones[region];
  return lista != null && lista.every(visitados.contains);
}

/// Aviso que sale al completar una subregión.
Future<void> mostrarInsignia(BuildContext context, String region) {
  final estilo = _estiloDe(region);
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      icon: _Medalla(estilo: estilo, ganada: true, tamano: 96),
      title: const Text('¡Insignia ganada!'),
      content: Text(
        'Completaste todos los municipios de $region.',
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

class InsigniasPage extends StatelessWidget {
  const InsigniasPage({super.key, required this.visitados});

  final Set<String> visitados;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final regiones = subregiones.keys.toList();
    final ganadas = regiones.where((r) => insigniaGanada(r, visitados)).length;

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
                  '$ganadas de ${regiones.length} ganadas. '
                  'Visita todos los municipios de una subregión para obtenerla.',
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
            itemCount: regiones.length,
            itemBuilder: (context, i) {
              final region = regiones[i];
              final lista = subregiones[region]!;
              final n = lista.where(visitados.contains).length;
              return _TarjetaInsignia(
                region: region,
                visitados: n,
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
    required this.visitados,
    required this.total,
  });

  final String region;
  final int visitados;
  final int total;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final estilo = _estiloDe(region);
    final ganada = visitados == total;

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
                value: visitados / total,
                minHeight: 6,
                color: ganada ? estilo.color : null,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              ganada ? 'Completada' : '$visitados/$total',
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
