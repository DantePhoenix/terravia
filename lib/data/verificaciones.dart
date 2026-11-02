import 'dart:convert';

import 'package:geolocator/geolocator.dart';

/// Velocidad máxima razonable entre dos verificaciones (km/h).
/// Cubre carro y bus; un avión comercial en Antioquia no aplica.
const double velocidadMaximaKmH = 150;

/// Antigüedad máxima permitida de la lectura GPS.
const Duration edadMaximaLectura = Duration(minutes: 2);

/// Una verificación por GPS: dónde y cuándo ocurrió.
class Verificacion {
  const Verificacion({
    required this.municipio,
    required this.lat,
    required this.lon,
    required this.fecha,
  });

  final String municipio;
  final double lat;
  final double lon;
  final DateTime fecha;

  Map<String, dynamic> toJson() => {
        'municipio': municipio,
        'lat': lat,
        'lon': lon,
        'fecha': fecha.toIso8601String(),
      };

  factory Verificacion.fromJson(Map<String, dynamic> json) => Verificacion(
        municipio: json['municipio'] as String,
        lat: (json['lat'] as num).toDouble(),
        lon: (json['lon'] as num).toDouble(),
        fecha: DateTime.parse(json['fecha'] as String),
      );

  static String codificar(Iterable<Verificacion> lista) =>
      jsonEncode(lista.map((v) => v.toJson()).toList());

  /// Devuelve una lista vacía si el texto está dañado o no existe.
  static List<Verificacion> decodificar(String? texto) {
    if (texto == null || texto.isEmpty) return [];

    try {
      final datos = jsonDecode(texto) as List<dynamic>;
      return datos
          .map((e) => Verificacion.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}

/// Revisa que la lectura de GPS sea confiable.
/// Devuelve un mensaje de error, o null si todo está bien.
String? validarLectura(Position posicion, {DateTime? ahora}) {
  final ahoraReal = ahora ?? DateTime.now();

  // Capa 1: ubicación simulada (solo Android la reporta).
  if (posicion.isMocked) {
    return 'Se detectó una ubicación simulada. No se puede verificar.';
  }

  // Capa 3: lectura vieja o con fecha en el futuro.
  final edad = ahoraReal.difference(posicion.timestamp).abs();
  if (edad > edadMaximaLectura) {
    return 'La lectura de ubicación no es reciente. Intenta nuevamente.';
  }

  return null;
}

/// Capa 2: compara con la verificación más reciente y rechaza saltos
/// imposibles. Devuelve un mensaje de error, o null si es coherente.
String? validarCoherencia(
  Position posicion,
  Verificacion? ultima, {
  DateTime? ahora,
}) {
  if (ultima == null) return null;

  final ahoraReal = ahora ?? DateTime.now();
  final segundos = ahoraReal.difference(ultima.fecha).inSeconds;

  // Si el reloj del teléfono fue movido hacia atrás, no se puede juzgar.
  if (segundos <= 0) {
    return 'La hora del dispositivo no es coherente con tus verificaciones.';
  }

  final km = Geolocator.distanceBetween(
        ultima.lat,
        ultima.lon,
        posicion.latitude,
        posicion.longitude,
      ) /
      1000;

  final kmH = km / (segundos / 3600);

  // Tolerancia: distancias cortas no cuentan (ruido del GPS).
  if (km > 5 && kmH > velocidadMaximaKmH) {
    return 'Esta verificación no es coherente con la anterior '
        '(${ultima.municipio}, a ${km.round()} km hace poco).';
  }

  return null;
}
