import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:open_file_plus/open_file_plus.dart'; 
import 'package:path_provider/path_provider.dart';

class ActualizacionService {
  // Enlace directo al archivo JSON raw que tienes en tu cuenta de GitHub
  static const String _urlJsonVersion = 'https://githubusercontent.com';

  /// Comprueba si hay una actualización disponible en GitHub
  static Future<void> comprobarActualizacion(BuildContext context) async {
    try {
      final PackageInfo infoLocal = await PackageInfo.fromPlatform();
      final int buildLocal = int.tryParse(infoLocal.buildNumber) ?? 1;

      final respuestaHttp = await http.get(Uri.parse(_urlJsonVersion)).timeout(
        const Duration(seconds: 5),
      );

      if (respuestaHttp.statusCode == 200) {
        final Map<String, dynamic> jsonRemoto = json.decode(respuestaHttp.body);
        final int buildRemoto = jsonRemoto['build_number'] ?? 1;
        final String versionNuevaNombre = jsonRemoto['version'] ?? '0.0.0';
        final String urlDescargaApk = jsonRemoto['url'] ?? '';

        if (buildRemoto > buildLocal && urlDescargaApk.isNotEmpty) {
          if (!context.mounted) return;
          _mostrarVentanaEmergenciaActualizacion(context, versionNuevaNombre, urlDescargaApk);
        }
      }
    } catch (e) {
      debugPrint('Error silencioso en el motor de autoactualización: ${e.toString()}');
    }
  }

  static void _mostrarVentanaEmergenciaActualizacion(BuildContext context, String nuevaVersion, String urlApk) {
    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (context) {
        double progresoDescarga = 0.0;
        bool descargando = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                'Actualización Disponible (v$nuevaVersion)',
                style: const TextStyle(color: Colors.orangeAccent, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    descargando 
                        ? 'Descargando el instalador optimizado desde GitHub... Por favor, no cierres la aplicación.' 
                        : 'Se ha detectado una versión del localizador más reciente con mejoras en el motor de paradas en tiempo real de Girona.',
                    style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                  ),
                  if (descargando) ...[
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: progresoDescarga,
                      backgroundColor: Colors.white12,
                      color: Colors.orangeAccent,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Progreso: ${(progresoDescarga * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(color: Colors.white30, fontSize: 11, fontFamily: 'monospace'),
                    ),
                  ]
                ],
              ),
              actions: [
                if (!descargando) ...[
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Luego', style: TextStyle(color: Colors.white30)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
                    onPressed: () async {
                      setDialogState(() {
                        descargando = true;
                      });

                      try {
                        // 1. Buscamos la ruta interna de descargas seguras del teléfono
                        final Directory carpetaDescargas = await getTemporaryDirectory();
                        final String rutaDestinoApk = '${carpetaDescargas.path}/r11_localizador_v$nuevaVersion.apk';

                        // 2. Descarga progresiva de alto rendimiento con Dio (0% a 100%)
                        final Dio dio = Dio();
                        await dio.download(
                          urlApk,
                          rutaDestinoApk,
                          onReceiveProgress: (recibido, total) {
                            if (total != -1) {
                              setDialogState(() {
                                progresoDescarga = recibido / total;
                              });
                            }
                          },
                        );

                        // 3. Ejecución e instalación nativa del APK descargado
                        if (context.mounted) {
                          Navigator.pop(context); 
                        }
                        await OpenFile.open(rutaDestinoApk);
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      }
                    },
                    child: const Text('Actualizar Ya', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ]
              ],
            );
          },
        );
      },
    );
  }
}
