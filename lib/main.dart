import 'dart:io';
import 'package:flutter/material.dart';

import 'services/seguridad_ssl.dart';
import 'ui/pantalla_linea_ajustada.dart'; // Importación de nuestra nueva pantalla separada

void main() {
  // Inicialización obligatoria y asignación de la política de seguridad criptográfica SSL
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = SeguridadSsl();
  
  runApp(const MiVisorRenfeApp());
}

class MiVisorRenfeApp extends StatelessWidget {
  const MiVisorRenfeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Visor R11 Tiempo Real',
      debugShowCheckedModeBanner: false, // Quitamos la cinta roja de 'debug' de la pantalla
      theme: ThemeData.dark(),
      home: const PantallaLineaAjustada(), // Llamada limpia al módulo de interfaz externo
    );
  }
}
