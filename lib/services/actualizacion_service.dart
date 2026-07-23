import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:ota_update/ota_update.dart';

class ActualizacionService {
  // Enlace directo al archivo JSON raw que subirás a la raíz de tu repositorio de GitHub
  static const String _urlJsonVersion = 'https://githubusercontent.com';

  /// Comprueba si hay una actualización disponible y gestiona la descarga nativa
  static Future<void> comprobarActualizacion(BuildContext context) async {
    try {
      // 1. Leemos los datos de la compilación interna que tiene el móvil instalado hoy
      final PackageInfo infoLocal = await PackageInfo.fromPlatform();
      final int buildLocal = int.tryParse(infoLocal.buildNumber) ?? 1;

      // 2. Consultamos el archivo de control que has subido a tu cuenta de GitHub
      final respuestaHttp = await http.get(Uri.parse(_urlJsonVersion)).timeout(
        const Duration(seconds: 5),
      );

      if (respuestaHttp.statusCode == 200) {
        final Map<String, dynamic> jsonRemoto = json.decode(respuestaHttp.body);
        final int buildRemoto = jsonRemoto['build_number'] ?? 1;
        final String versionNuevaNombre = jsonRemoto['version'] ?? '0.0.0';
        final String urlDescargaApk = jsonRemoto['url'] ?? '';

        // COMPARACIÓN MATEMÁTICA: Si el código de internet es mayor, se activa la alerta
        if (buildRemoto > buildLocal && urlDescargaApk.isNotEmpty) {
          // GUARDIÁN CONTRA ASINCRONÍAS: Si la pantalla se destruyó durante la espera, abortamos
          if (!context.mounted) {
            return;
          }

          // Lanzamos el cuadro de diálogo emergente de forma 100% segura
          _mostrarVentanaEmergenciaActualizacion(context, versionNuevaNombre, urlDescargaApk);
        }
      }
    } catch (e) {
      debugPrint('Error silencioso en el motor de autoactualización de GitHub: ${e.toString()}');
    }
  }

  static void _mostrarVentanaEmergenciaActualizacion(BuildContext context, String nuevaVersion, String urlApk) {
    showDialog(
      context: context,
      barrierDismissible: false, // Obliga al usuario a interactuar para mantener la flota al día
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
                        ? 'Descargando el nuevo instalador de Adif desde GitHub... Por favor, no cierres la aplicación.' 
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
                    onPressed: () {
                      setDialogState(() {
                        descargando = true;
                      });

                      // INVOCACIÓN DEL PAQUETE OTA_UPDATE NATIVO DE ANDROID
                      try {
                        OtaUpdate().execute(urlApk, destinationFilename: 'r11_localizador.apk').listen(
                          (OtaEvent evento) {
                            setDialogState(() {
                              if (evento.status == OtaStatus.DOWNLOADING) {
                                // Convertimos el string de progreso (0 a 100) a un gradiente de 0.0 a 1.0 para la barra
                                progresoDescarga = (double.tryParse(evento.value ?? '0') ?? 0.0) / 100.0;
                              } else if (evento.status == OtaStatus.INSTALLING) {
                                if (context.mounted) {
                                  Navigator.pop(context); // Cerramos el diálogo de forma segura
                                }
                              }
                            });
                          },
                          onError: (error) {
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                        );
                      } catch (e) {
                        Navigator.pop(context);
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
