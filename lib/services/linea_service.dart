import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/estacion_model.dart';

class LineaService {
  // Carga las estaciones asíncronamente simulando la respuesta de red de Adif
  Future<List<Estacion>> cargarEstaciones() async {
    try {
      final String respuesta = await rootBundle.loadString('assets/data/estaciones.json');
      final List<dynamic> datos = json.decode(respuesta);
      
      return datos.map((json) => Estacion.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al cargar la infraestructura ferroviaria: $e');
    }
  }
}
