class ConfigCorredorR11 {
  static const Set<String> idsRutaOficiales = {'13', '36'};
  static const Set<String> etiquetasComerciales = {'R11', 'RG1', 'MD', 'REGIONAL'};

  static const double latitudMinima = 41.35; // Límite sur (Barcelona-Sants)
  static const double latitudMaxima = 42.45; // Límite norte (Frontera Cerbère)

  static bool validarTrenEnCorredor({
    required String id,
    required String tipo,
    required double latitud,
    required double longitud,
  }) {
    final String idLimpiado = id.toUpperCase().trim();
    final String tipoLimpiado = tipo.toUpperCase().trim();

    // Filtro Geográfico estricto: El tren debe estar físicamente circulando por las vías de Girona / Barcelona
    final bool estaEnElCorredorFisico = latitud >= latitudMinima && latitud <= latitudMaxima;
    if (!estaEnElCorredorFisico) return false;

    final bool cumpleIdRuta = idsRutaOficiales.any((idRuta) => 
        idLimpiado == idRuta || idLimpiado.startsWith('${idRuta}_') || idLimpiado.endsWith('_$idRuta'));

    final bool cumpleEtiqueta = etiquetasComerciales.any((etiqueta) => 
        idLimpiado.contains(etiqueta) || tipoLimpiado.contains(etiqueta));

    final String soloNumeros = idLimpiado.replaceAll(RegExp(r'[^0-9]'), '');
    bool cumpleRangoAdif = false;
    if (soloNumeros.length >= 4) {
      final int? numeroTren = int.tryParse(soloNumeros.substring(0, soloNumeros.length > 5 ? 5 : soloNumeros.length));
      if (numeroTren != null) {
        cumpleRangoAdif = (numeroTren >= 30800 && numeroTren <= 30999) || 
                          (numeroTren >= 34000 && numeroTren <= 34999);
      }
    }

    // Si está en la vía de Girona y cumple cualquier patrón de Media Distancia, entra sí o sí
    return cumpleIdRuta || cumpleEtiqueta || cumpleRangoAdif;
  }
}
