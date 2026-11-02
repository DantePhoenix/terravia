import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Un punto de referencia y hasta dónde (en metros) se acepta la verificación.
typedef PuntoVerificacion = ({double lat, double lon, double radio});

/// Pon esto en true SOLO para probar desde un mismo lugar: todos los
/// municipios se comparan contra [puntosPrueba] en vez de sus coordenadas.
/// Debe estar en false en el uso real.
final bool modoPrueba = dotenv.env['MODO_DE_PRUEBA']?.toLowerCase() == 'true';

/// Punto usado cuando [modoPrueba] es true (Parque de Belén, Medellín).
const List<PuntoVerificacion> puntosPrueba = [
  (lat: 6.2330, lon: -75.6050, radio: 2500),
];

/// Puntos de verificación de cada municipio, agrupados por subregión.
/// Un municipio grande puede tener varios puntos: basta con estar dentro
/// del radio de cualquiera de ellos.
/// Las coordenadas son aproximadas (cabecera municipal): si al probar en
/// el sitio el mensaje da una distancia rara, corrige el punto.
const Map<String, List<PuntoVerificacion>> puntosMunicipios = {
  // ── Valle de Aburrá ──
  'Barbosa': [(lat: 6.435743, lon: -75.329229, radio: 2000)],
  'Girardota': [(lat: 6.377655, lon: -75.446178, radio: 2000)],
  'Copacabana': [(lat: 6.346046, lon: -75.5088112, radio: 2000)],
  'Bello': [(lat: 6.334909, lon: -75.558290, radio: 3000)],

  // Medellín es muy extenso: varios puntos de 2,5 km.
  'Medellín': [
    (lat: 6.2518, lon: -75.5636, radio: 2500), // Parque Berrío (centro)
    (lat: 6.2090, lon: -75.5655, radio: 2500), // Parque de El Poblado
    (lat: 6.2455, lon: -75.5918, radio: 2500), // Laureles
    (lat: 6.2330, lon: -75.6050, radio: 2500), // Parque de Belén
    (lat: 6.2750, lon: -75.5900, radio: 2500), // Robledo
  ],

  'Itagüí': [(lat: 6.172408, lon: -75.609481, radio: 3000)],
  'Envigado': [(lat: 6.170117, lon: -75.587506, radio: 3000)],
  'Sabaneta': [(lat: 6.151543, lon: -75.615468, radio: 2000)],
  'La Estrella': [(lat: 6.157609, lon: -75.643454, radio: 2000)],
  'Caldas': [(lat: 6.091854, lon: -75.635691, radio: 2000)],

  // ── Bajo Cauca ──
  'Caucasia': [(lat: 7.982920, lon: -75.198134, radio: 3000)],
  'El Bagre': [(lat: 7.6035, lon: -74.8095, radio: 3000)],
  'Nechí': [(lat: 8.0958, lon: -74.7750, radio: 2500)],
  'Tarazá': [(lat: 7.580457, lon: -75.399814, radio: 2500)],
  'Cáceres': [(lat: 7.582307, lon: -75.347783, radio: 2500)],
  'Zaragoza': [(lat: 7.498607, lon: -74.923795, radio: 2500)],

  // ── Magdalena Medio ──
  'Puerto Berrío': [(lat: 6.489884, lon: -74.402086, radio: 3000)],
  'Puerto Nare': [(lat: 6.187870, lon: -74.581641, radio: 2500)],
  'Puerto Triunfo': [(lat: 5.868883, lon: -74.640839, radio: 2500)],
  'Yondó': [(lat: 7.007386, lon: -73.909338, radio: 2500)],
  'Caracolí': [(lat: 6.410960, lon: -74.756911, radio: 2500)],
  'Maceo': [(lat: 6.550907, lon: -74.787624, radio: 2500)],

  // ── Nordeste ──
  'Amalfi': [(lat: 6.907498, lon: -75.074963, radio: 2500)],
  'Anorí': [(lat: 7.073678, lon: -75.146653, radio: 2500)],
  'Cisneros': [(lat: 6.538441, lon: -75.087788, radio: 2500)],
  'Remedios': [(lat: 7.027989, lon: -74.693652, radio: 2500)],
  'San Roque': [(lat: 6.485097, lon: -75.019535, radio: 2500)],
  'Santo Domingo': [(lat: 6.471178, lon: -75.164413, radio: 2500)],
  'Segovia': [(lat: 7.081720, lon: -74.701152, radio: 3000)],
  'Vegachí': [(lat: 6.771282, lon: -74.799084, radio: 2500)],
  'Yalí': [(lat: 6.675438, lon: -74.842258, radio: 2500)],
  'Yolombó': [(lat: 6.599224, lon: -75.012114, radio: 2500)],

  // ── Norte ──
  'Angostura': [(lat: 6.8847, lon: -75.3364, radio: 2500)],
  'Belmira': [(lat: 6.6072, lon: -75.6672, radio: 2500)],
  'Briceño': [(lat: 7.1136, lon: -75.5522, radio: 2500)],
  'Campamento': [(lat: 6.9786, lon: -75.2917, radio: 2500)],
  'Carolina del Príncipe': [(lat: 6.7236, lon: -75.2853, radio: 2500)],
  'Donmatías': [(lat: 6.4838, lon: -75.3947, radio: 2500)],
  'Entrerríos': [(lat: 6.5669, lon: -75.5206, radio: 2500)],
  'Gómez Plata': [(lat: 6.6842, lon: -75.2203, radio: 2500)],
  'Guadalupe': [(lat: 6.8139, lon: -75.2403, radio: 2500)],
  'Ituango': [(lat: 7.1713, lon: -75.7634, radio: 2500)],
  'San Andrés de Cuerquia': [(lat: 6.9183, lon: -75.6800, radio: 2500)],
  'San José de la Montaña': [(lat: 6.8488, lon: -75.6830, radio: 2500)],
  'San Pedro de los Milagros': [(lat: 6.4608, lon: -75.5578, radio: 2500)],
  'Santa Rosa de Osos': [(lat: 6.6467, lon: -75.4600, radio: 3000)],
  'Toledo': [(lat: 7.0128, lon: -75.6844, radio: 2500)],
  'Valdivia': [(lat: 7.1636, lon: -75.4391, radio: 2500)],
  'Yarumal': [(lat: 6.9644, lon: -75.4189, radio: 3000)],

  // ── Occidente ──
  'Abriaquí': [(lat: 6.6317, lon: -76.0844, radio: 2500)],
  'Anzá': [(lat: 6.3050, lon: -75.8553, radio: 2500)],
  'Armenia': [(lat: 6.1547, lon: -75.7864, radio: 2500)],
  'Buriticá': [(lat: 6.7233, lon: -75.9072, radio: 2500)],
  'Caicedo': [(lat: 6.4044, lon: -75.9833, radio: 2500)],
  'Cañasgordas': [(lat: 6.7500, lon: -76.0267, radio: 2500)],
  'Dabeiba': [(lat: 7.0014, lon: -76.2631, radio: 2500)],
  'Ebéjico': [(lat: 6.3267, lon: -75.7667, radio: 2500)],
  'Frontino': [(lat: 6.7769, lon: -76.1319, radio: 2500)],
  'Giraldo': [(lat: 6.6836, lon: -75.9531, radio: 2500)],
  'Heliconia': [(lat: 6.2086, lon: -75.7344, radio: 2500)],
  'Liborina': [(lat: 6.6789, lon: -75.8153, radio: 2500)],
  'Olaya': [(lat: 6.6258, lon: -75.8111, radio: 2500)],
  'Peque': [(lat: 7.0194, lon: -75.9114, radio: 2500)],
  'Sabanalarga': [(lat: 6.8497, lon: -75.8183, radio: 2500)],
  'San Jerónimo': [(lat: 6.4486, lon: -75.7267, radio: 2500)],
  'Santa Fe de Antioquia': [(lat: 6.5564, lon: -75.8281, radio: 3000)],
  'Sopetrán': [(lat: 6.5000, lon: -75.7447, radio: 2500)],
  'Uramita': [(lat: 6.8981, lon: -76.1722, radio: 2500)],

  // ── Oriente ──
  'Abejorral': [(lat: 5.7894, lon: -75.4294, radio: 2500)],
  'Alejandría': [(lat: 6.3667, lon: -75.0833, radio: 2500)],
  'Argelia': [(lat: 5.7292, lon: -75.1403, radio: 2500)],
  'El Carmen de Viboral': [(lat: 6.0825, lon: -75.3350, radio: 3000)],
  'Cocorná': [(lat: 6.0569, lon: -75.1892, radio: 2500)],
  'Concepción': [(lat: 6.3939, lon: -75.2586, radio: 2500)],
  'El Peñol': [(lat: 6.2186, lon: -75.2400, radio: 2500)],
  'El Retiro': [(lat: 6.0622, lon: -75.5039, radio: 2500)],
  'El Santuario': [(lat: 6.1386, lon: -75.2653, radio: 2500)],
  'Granada': [(lat: 6.1431, lon: -75.1856, radio: 2500)],
  'Guarne': [(lat: 6.2786, lon: -75.4428, radio: 3000)],
  'Guatapé': [(lat: 6.2331, lon: -75.1586, radio: 2500)],
  'La Ceja': [(lat: 6.0319, lon: -75.4286, radio: 3000)],
  'La Unión': [(lat: 5.9744, lon: -75.3606, radio: 2500)],
  'Marinilla': [(lat: 6.1744, lon: -75.3369, radio: 3000)],
  'Nariño': [(lat: 5.6100, lon: -75.1783, radio: 2500)],
  'Rionegro': [(lat: 6.1553, lon: -75.3736, radio: 3000)],
  'San Carlos': [(lat: 6.1869, lon: -74.9958, radio: 2500)],
  'San Francisco': [(lat: 5.9664, lon: -75.0978, radio: 2500)],
  'San Luis': [(lat: 6.0436, lon: -74.9944, radio: 2500)],
  'San Rafael': [(lat: 6.2931, lon: -75.0267, radio: 2500)],
  'San Vicente Ferrer': [(lat: 6.2819, lon: -75.3331, radio: 2500)],
  'Sonsón': [(lat: 5.7119, lon: -75.3086, radio: 3000)],

  // ── Suroeste ──
  'Amagá': [(lat: 6.0386, lon: -75.7022, radio: 2500)],
  'Andes': [(lat: 5.6558, lon: -75.8789, radio: 3000)],
  'Angelópolis': [(lat: 6.1103, lon: -75.7106, radio: 2500)],
  'Betania': [(lat: 5.7439, lon: -75.9761, radio: 2500)],
  'Betulia': [(lat: 6.1128, lon: -75.9822, radio: 2500)],
  'Caramanta': [(lat: 5.5517, lon: -75.6444, radio: 2500)],
  'Ciudad Bolívar': [(lat: 5.8508, lon: -76.0239, radio: 2500)],
  'Concordia': [(lat: 6.0456, lon: -75.9111, radio: 2500)],
  'Fredonia': [(lat: 5.9275, lon: -75.6728, radio: 2500)],
  'Hispania': [(lat: 5.7978, lon: -75.9058, radio: 2500)],
  'Jardín': [(lat: 5.5983, lon: -75.8189, radio: 2500)],
  'Jericó': [(lat: 5.7894, lon: -75.7842, radio: 2500)],
  'La Pintada': [(lat: 5.7444, lon: -75.6075, radio: 2500)],
  'Montebello': [(lat: 5.9461, lon: -75.5222, radio: 2500)],
  'Pueblorrico': [(lat: 5.7917, lon: -75.8419, radio: 2500)],
  'Salgar': [(lat: 5.9639, lon: -75.9767, radio: 2500)],
  'Santa Bárbara': [(lat: 5.8756, lon: -75.5656, radio: 2500)],
  'Támesis': [(lat: 5.6642, lon: -75.7131, radio: 2500)],
  'Tarso': [(lat: 5.8639, lon: -75.8219, radio: 2500)],
  'Titiribí': [(lat: 6.0603, lon: -75.7922, radio: 2500)],
  'Urrao': [(lat: 6.3178, lon: -76.1347, radio: 2500)],
  'Valparaíso': [(lat: 5.6150, lon: -75.6244, radio: 2500)],
  'Venecia': [(lat: 5.9669, lon: -75.7347, radio: 2500)],

  // ── Urabá ──
  'Apartadó': [(lat: 7.8830, lon: -76.6256, radio: 3000)],
  'Arboletes': [(lat: 8.8500, lon: -76.4267, radio: 2500)],
  'Carepa': [(lat: 7.7569, lon: -76.6572, radio: 2500)],
  'Chigorodó': [(lat: 7.6675, lon: -76.6806, radio: 2500)],
  'Murindó': [(lat: 6.9792, lon: -76.8128, radio: 2500)],
  'Mutatá': [(lat: 7.2444, lon: -76.4367, radio: 2500)],
  'Necoclí': [(lat: 8.4289, lon: -76.7889, radio: 2500)],
  'San Juan de Urabá': [(lat: 8.7603, lon: -76.5311, radio: 2500)],
  'San Pedro de Urabá': [(lat: 8.2744, lon: -76.3822, radio: 2500)],
  'Turbo': [(lat: 8.0933, lon: -76.7283, radio: 3000)],
  'Vigía del Fuerte': [(lat: 6.5836, lon: -76.8864, radio: 2500)],
};

/// Compara una posición con los puntos del municipio.
/// Devuelve null si el municipio no tiene puntos configurados.
/// - dentro: está dentro del radio de al menos un punto.
/// - distanciaMetros: distancia al punto más cercano.
({bool dentro, double distanciaMetros})? evaluarUbicacion(
  String municipio,
  double lat,
  double lon,
) {
  final puntos = modoPrueba ? puntosPrueba : puntosMunicipios[municipio];

  if (puntos == null || puntos.isEmpty) return null;

  var dentro = false;
  var masCercana = double.infinity;

  for (final p in puntos) {
    final d = Geolocator.distanceBetween(lat, lon, p.lat, p.lon);

    if (d <= p.radio) dentro = true;
    if (d < masCercana) masCercana = d;
  }

  return (dentro: dentro, distanciaMetros: masCercana);
}
