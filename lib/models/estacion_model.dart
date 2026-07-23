class Estacion {
  final String id;
  final String nombre;
  final double pkReal; 
  final double pkAdif; 
  final double latitud;
  final double longitud;

  Estacion({
    required this.id,
    required this.nombre,
    required this.pkReal,
    required this.pkAdif,
    required this.latitud,
    required this.longitud,
  });

  factory Estacion.fromJson(Map<String, dynamic> json) {
    // Usamos double.parse para convertir cualquier entrada (int o double) 
    // en un double puro de forma segura sin hacer castings peligrosos
    return Estacion(
      id: json['id'].toString(),
      nombre: json['nombre'] as String,
      pkReal: double.parse(json['pk_real'].toString()),
      pkAdif: double.parse(json['pk_adif'].toString()),
      latitud: double.parse(json['latitud'].toString()),
      longitud: double.parse(json['longitud'].toString()),
    );
  }
}
