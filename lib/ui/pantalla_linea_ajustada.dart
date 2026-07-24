import 'dart:async';
import 'package:flutter/material.dart';

import '../models/estacion_model.dart';
import '../models/tren_model.dart';
import '../models/incidencia_model.dart';
import '../services/linea_service.dart';
import '../services/tren_service.dart';
import '../services/geometria_ferroviaria.dart'; 
import '../services/sincronizador_flota_service.dart';
import '../services/actualizacion_service.dart';
import 'linea_painter.dart';
import 'trenes_painter.dart';
import 'diagnostico_red_widget.dart';
import 'tren_detalle_modal.dart';
import 'incidencias_cintillo_widget.dart';
import 'incidencias_detalle_modal.dart';

class PantallaLineaAjustada extends StatefulWidget {
  const PantallaLineaAjustada({super.key});

  @override
  State<PantallaLineaAjustada> createState() => _PantallaLineaAjustadaState();
}

class _PantallaLineaAjustadaState extends State<PantallaLineaAjustada> with WidgetsBindingObserver {
  final LineaService _lineaService = LineaService();
  final SincronizadorFlotaService _sincronizadorService = SincronizadorFlotaService();
  
  late Future<List<Estacion>> _futureEstaciones;
  List<Estacion> _listaEstacionesEstatica = [];
  
  bool _estadoRedExitoso = true;
  String _mensajeErrorRedDetallado = "Sin errores de enlace reportados.";
  
  Timer? _relojSincronizacionMaestro;
  
  Set<String> _idsEstacionesR11 = {};
  List<Tren> _trenesActivos = [];
  
  Incidencia? _incidenciaActivaObjeto;
  bool _hayIncidenciaReal = false;

  final double _longitudTotalKm = 168.7;
  static const double _colchonVertical = 20.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _futureEstaciones = _lineaService.cargarEstaciones().then((estaciones) {
      _listaEstacionesEstatica = estaciones;
      _idsEstacionesR11 = estaciones.map((e) => e.id).toSet();
      
      // Disparador de autoactualización
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ActualizacionService.comprobarActualizacion(context);
      });

      // Descarga inicial
      _dispararConsultaRedSincronizada();
      
      // Bucle de refresco cada 25 segundos
      _relojSincronizacionMaestro = Timer.periodic(const Duration(seconds: 25), (_) {
        _dispararConsultaRedSincronizada();
      });
      
      return estaciones;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _relojSincronizacionMaestro?.cancel();
    super.dispose();
  }

  /// Observa los cambios de ciclo de vida de la app
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App volvió a foreground - sincroniza inmediatamente
      _dispararConsultaRedSincronizada();
    }
  }

  /// Función que invoca al orquestador externo y actualiza el estado visual
  Future<void> _dispararConsultaRedSincronizada() async {
    if (_idsEstacionesR11.isEmpty) {
      return;
    }

    final respuestaUnificada = await _sincronizadorService.ejecutarSincronizacionCombinada(_idsEstacionesR11);

    if (mounted) {
      setState(() {
        _estadoRedExitoso = respuestaUnificada.esExitoso;
        _mensajeErrorRedDetallado = respuestaUnificada.estadoConexion;
        _trenesActivos = respuestaUnificada.trenes;

        final Incidencia? aviso = respuestaUnificada.incidencia;
        if (aviso != null) {
          _incidenciaActivaObjeto = aviso;
          _hayIncidenciaReal = aviso.id != 'OK-RENFE-SINC';
        } else {
          _incidenciaActivaObjeto = null;
          _hayIncidenciaReal = false;
        }
      });
    }
  }

  void _detectarYMostrarTren(TapDownDetails detalles, double alturaTotalCanvas) {
    final Offset posicionToque = detalles.localPosition;
    if (posicionToque.dx < 160.0) {
      return; 
    }

    final Map<String, Estacion> mapaEstaciones = {
      for (var est in _listaEstacionesEstatica) est.id: est
    };

    final double alturaUtilConColchon = alturaTotalCanvas - (_colchonVertical * 2);
    final double escalaAjustada = alturaUtilConColchon / _longitudTotalKm;

    final geometria = GeometriaFerroviaria();

    for (var tren in _trenesActivos) {
      double kilometroReal = geometria.calcularKilometroLineal(tren, mapaEstaciones);

      if (kilometroReal >= 0) {
        double trenYTeorico = (alturaTotalCanvas - _colchonVertical) - (kilometroReal * escalaAjustada);

        if ((posicionToque.dy - trenYTeorico).abs() <= 18.0) {
          final String tripKey = tren.id.contains('-') ? tren.id.split('-').last : tren.id;
          
          // Recuperamos el mapa de actualizaciones comerciales
          Map<String, dynamic>? nodoComercialAdifReal;
          if (TrenService.mapaTripUpdatesUltimoCiclo.containsKey(tripKey)) {
            nodoComercialAdifReal = TrenService.mapaTripUpdatesUltimoCiclo[tripKey];
          }

          // Abrimos el modal
          TrenDetalleModal.mostrar(
            context: context,
            tren: tren,
            estacionAnterior: mapaEstaciones[tren.idEstacionAnterior],
            estacionSiguiente: mapaEstaciones[tren.idEstacionSiguiente],
            listaEstacionesGlobal: _listaEstacionesEstatica, 
            entidadComercialNode: nodoComercialAdifReal,
          );
          break; 
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Línea R11 - Visor Real'),
      ),
      body: FutureBuilder<List<Estacion>>(
        future: _futureEstaciones,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay datos disponibles.'));
          }

          final estaciones = snapshot.data!;

          return Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double alturaUtil = constraints.maxHeight - (_colchonVertical * 2);
                    final double escalaSincronizada = alturaUtil / _longitudTotalKm;

                    return Stack(
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTapDown: (detalles) => _detectarYMostrarTren(detalles, constraints.maxHeight),
                          child: Stack(
                            children: [
                              CustomPaint(
                                size: Size(constraints.maxWidth, constraints.maxHeight),
                                painter: LineaPainter(
                                  estaciones: estaciones,
                                  escalaPxPorKm: escalaSincronizada,
                                ),
                              ),
                              CustomPaint(
                                size: Size(constraints.maxWidth, constraints.maxHeight),
                                painter: TrenesPainter(
                                  estaciones: estaciones,
                                  trenes: _trenesActivos,
                                  escalaPxPorKm: escalaSincronizada,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        Positioned(
                          top: 12,
                          right: 16,
                          child: DiagnosticoRedWidget(
                            esExitoso: _estadoRedExitoso,
                            mensajeError: _mensajeErrorRedDetallado,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              
              IncidenciasCintilloWidget(
                hayIncidenciaReal: _hayIncidenciaReal,
                incidenciaTexto: _incidenciaActivaObjeto != null 
                    ? (_hayIncidenciaReal ? "Incidencias" : "Línea R11 operando con normalidad")
                    : "Comprobando alertas...",
                alPulsarBarra: () {
                  if (_incidenciaActivaObjeto != null) {
                    IncidenciasDetalleModal.mostrar(
                      context: context,
                      incidencia: _incidenciaActivaObjeto!,
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
