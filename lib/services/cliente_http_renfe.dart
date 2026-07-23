import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart' as io_client;

class ClienteHttpRenfe {
  static final Random _random = Random();

  // Conector nativo de Android forzando la aprobación del apretón de manos digital con Renfe
  static io_client.IOClient _crearConectorDirectoSsl() {
    final HttpClient conectorNativo = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        if (host.contains('renfe.com')) {
          return true;
        }
        return false;
      };
    return io_client.IOClient(conectorNativo);
  }

  // Set estricto y limpio exigido por la API de producción de ://renfe.com
  static Map<String, String> _generarCabecerasOficiales() {
    return {
      // CORRECCIÓN DIRECTA REQUISITO 400: Eliminamos cookies falsas y cabeceras de origen web.
      // Dejamos únicamente el User-Agent limpio y el tipo de contenido puro que exige su pasarela.
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept': 'application/json',
      'Cache-Control': 'no-cache',
    };
  }

  // Realiza la petición GET directa de dispositivo a servidor con factor de fluctuación humana (Jitter)
  static Future<http.Response> get(String urlBase) async {
    final int milisegundosAleatorios = _random.nextInt(1500) + 500;
    await Future.delayed(Duration(milliseconds: milisegundosAleatorios));

    // Atacamos el archivo .json limpio sin parámetros adicionales que confundan al servidor estático
    final io_client.IOClient clienteDirecto = _crearConectorDirectoSsl();

    try {
      final http.Response response = await clienteDirecto.get(
        Uri.parse(urlBase),
        headers: _generarCabecerasOficiales(),
      ).timeout(const Duration(seconds: 15));

      return response;
    } finally {
      clienteDirecto.close();
    }
  }
}
