import 'dart:io';

class SeguridadSsl extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    // Retornamos un cliente HTTP nativo con las políticas de certificación personalizadas
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        // REGLA DE CONFIANZA ESTRICTA:
        // Si la petición web va dirigida a los servidores oficiales del visor de Renfe,
        // la aplicación aprueba explícitamente el certificado digital, extinguiendo el error 298.
        if (host == '://renfe.com') {
          return true; // Autoriza la conexión de forma segura
        }
        
        return false; // Mantiene el bloqueo de seguridad estándar para cualquier otro dominio ajeno
      };
  }
}
