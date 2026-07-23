class Tren {
  final String id;
  final String tipo;
  final String idEstacionAnterior;
  final String idEstacionSiguiente;
  final double porcentajeTramo;
  final int retrasoMinutos;
  final double latitud;
  final double longitud;
  final int direccionId; // 0 = Hacia Cerbère (Norte), 1 = Hacia Barcelona (Sur)
  
  final String origen;
  final String destino;
  final String estadoTexto;
  final DateTime ultimaActualizacion; 

  Tren({
    required this.id,
    required this.tipo,
    required this.idEstacionAnterior,
    required this.idEstacionSiguiente,
    required this.porcentajeTramo,
    required this.retrasoMinutos,
    required this.latitud,
    required this.longitud,
    required this.direccionId,
    this.origen = 'Desconocido',
    this.destino = 'Desconocido',
    this.estadoTexto = 'En marcha',
    required this.ultimaActualizacion,
  });

  factory Tren.fromJson(Map<String, dynamic> jsonEntity) {
    final Map<String, dynamic> vehicleNode = jsonEntity['vehicle'] ?? {};
    final Map<String, dynamic> tripNode = vehicleNode['trip'] ?? {};
    final Map<String, dynamic> positionNode = vehicleNode['position'] ?? {};
    final Map<String, dynamic> vehicleDescriptor = vehicleNode['vehicle'] ?? {};

    final String routeId = (tripNode['route_id'] ?? '').toString().trim();
    final String tripId = (tripNode['trip_id'] ?? jsonEntity['id'] ?? '00000').toString().trim();
    
    String identificadorFinal = tripId;
    if (tripId.startsWith('30') || tripId.startsWith('34')) {
      identificadorFinal = 'R11_$tripId';
    } else if (routeId == '13') {
      identificadorFinal = 'R11_$tripId';
    } else if (routeId == '36') {
      identificadorFinal = 'RG1_$tripId';
    }

    final String labelTexto = (vehicleDescriptor['label'] ?? 'REGIONAL').toString().toUpperCase();
    final String tipoTren = labelTexto.contains('-') ? labelTexto.split('-').first : 'MD R11';

    final double lat = double.tryParse(positionNode['latitude']?.toString() ?? '0.0') ?? 0.0;
    final double lon = double.tryParse(positionNode['longitude']?.toString() ?? '0.0') ?? 0.0;
    
    final String soloNumeros = tripId.replaceAll(RegExp(r'[^0-9]'), '');
    int dirId = 0;
    if (soloNumeros.isNotEmpty) {
      final int? numTren = int.tryParse(soloNumeros);
      if (numTren != null && numTren % 2 == 0) {
        dirId = 1;
      }
    }

    final String estadoMarcha = (vehicleNode['current_status'] ?? 'IN_TRANSIT_TO').toString();
    final double progresoCalculado = estadoMarcha == 'STOPPED_AT' ? 0.0 : 0.5;

    return Tren(
      id: identificadorFinal,
      tipo: tipoTren,
      idEstacionAnterior: 'AUTO_START', 
      idEstacionSiguiente: 'AUTO_END', 
      porcentajeTramo: progresoCalculado,
      retrasoMinutos: 0,
      latitud: lat,
      longitud: lon,
      direccionId: dirId,
      ultimaActualizacion: DateTime.now(),
    );
  }

  Tren copiarConDatosComerciales({
    required String origen,
    required String destino,
    required int retraso,
    required String estado,
    required String anteriorId,
    required String siguienteId,
    DateTime? nuevaHoraActualizacion,
  }) {
    return Tren(
      id: id,
      tipo: tipo,
      idEstacionAnterior: anteriorId,
      idEstacionSiguiente: siguienteId,
      porcentajeTramo: porcentajeTramo,
      retrasoMinutos: retraso,
      latitud: latitud,
      longitud: longitud,
      direccionId: direccionId,
      origen: origen,
      destino: destino,
      estadoTexto: estado,
      ultimaActualizacion: nuevaHoraActualizacion ?? ultimaActualizacion,
    );
  }
}
