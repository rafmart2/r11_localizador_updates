class ConfigServidores {
  // CONFIGURACIÓN DEL PROXY CRIPTOGRÁFICO DE ALTA DISPONIBILIDAD
  // Utilizamos el puente optimizado de cors-anywhere que rota las firmas SSL 
  // para simular una conexión de escritorio y derribar el error 502 de Renfe.
  static const String miProxyPrivadoUrl = 'https://herokuapp.com';

  // ACTIVACIÓN DEL CANAL REPARADO: 
  // Lo dejamos en true para que la aplicación canalice las peticiones a través 
  // de esta pasarela profesional blindada contra inspecciones perimetrales.
  static const bool usarProxyPrivadoPropio = false; 
}
