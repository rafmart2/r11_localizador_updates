# 🚆 R11 Localizador

Aplicación móvil para consultar en tiempo real la circulación de trenes de las líneas **R11 y RG1**, mostrando su posición sobre una representación gráfica de la línea ferroviaria.

La aplicación obtiene la información de circulación y permite consultar tanto la situación actual de los trenes como sus horarios y detalles de cada servicio.

## 📱 Cómo usar la aplicación

### 1. Pantalla principal

Al abrir la aplicación se muestra la representación de la línea ferroviaria.

En ella aparecen:

- Las estaciones de la línea.
- Los trenes que están circulando.
- La posición aproximada de cada tren.
- La dirección de circulación.
- El número del tren.
- El retraso, cuando existe.

La posición de los trenes se calcula utilizando sus **coordenadas GPS**, proyectándolas sobre la representación de la línea.

### 2. Consultar un tren

Para consultar la información de un tren:

1. Localiza el tren en la representación de la línea.
2. Pulsa sobre él.
3. Se abrirá la ventana de detalle.

Desde el detalle se puede consultar la información disponible del servicio y su recorrido.

### 3. Consultar los horarios

Desde el menú de la aplicación se puede acceder a la información de horarios.

Los horarios están organizados por:

- **Laborables**
- **Fines de semana y festivos**

Las estaciones aparecen asociadas a sus correspondientes horarios y los servicios mantienen el orden de circulación.

### 4. Información de incidencias

En la parte superior de la pantalla se muestra el estado de la línea.

Si existe una incidencia, se puede pulsar sobre el indicador para consultar sus detalles.

Cuando no existe ninguna incidencia activa, la aplicación informa de que la línea está funcionando con normalidad.

### 5. Estado de la conexión

La aplicación dispone de un indicador del estado de la conexión con los servicios de datos.

Permite saber si la información se está actualizando correctamente o si existe algún problema de comunicación.

## ⚙️ Funcionalidades

### 🚆 Localización de trenes en tiempo real

La aplicación muestra los trenes activos de las líneas:

- **R11**
- **RG1**

Los trenes de otras líneas son ignorados.

La posición visual se calcula a partir de las coordenadas GPS recibidas.

### 📍 Posicionamiento mediante GPS

La ubicación del tren no depende exclusivamente de la estación que figure como anterior o siguiente.

El sistema:

1. Obtiene la posición GPS del tren.
2. Busca el tramo ferroviario más próximo.
3. Proyecta el tren sobre dicho tramo.
4. Calcula su posición relativa dentro de la línea.
5. Representa el tren en la posición correspondiente.

Esto permite mostrar correctamente trenes que se encuentran entre estaciones.

### 🧭 Dirección de circulación

Cada tren dispone de una indicación visual de dirección mediante una flecha.

Actualmente se distinguen los dos sentidos principales:

- Barcelona → Figueres / Portbou / Cerbère.
- Portbou / Figueres → Barcelona.

### ⏱️ Retrasos

Cuando un tren circula con retraso, se muestra junto al número del tren:

`15734 +44 min`

Si el tren circula en hora, no se muestra ningún retraso.

### 📡 Estado GPS

Cuando un tren no dispone de cobertura GPS, la aplicación puede indicar:

`15734 Sin GPS`

De esta forma se diferencia la ausencia de posición GPS de un tren que simplemente circula con normalidad.

### 🗺️ Representación gráfica de la línea

La aplicación muestra una representación vertical de la línea ferroviaria.

Incluye:

- Estaciones.
- Eje ferroviario.
- Trenes.
- Dirección de circulación.
- Información de cada tren.

La representación se adapta automáticamente al espacio disponible en pantalla.

### 🕐 Horarios comerciales

Los horarios procedentes de la información comercial de la línea están integrados en la aplicación.

Se han normalizado los identificadores de las estaciones para que los horarios puedan relacionarse correctamente con las estaciones utilizadas por la aplicación.

Los horarios se pueden consultar diferenciando entre:

- **Laborables**
- **Fines de semana y festivos**

### 🚉 Recorrido del tren

Al seleccionar un tren se puede consultar su recorrido y las estaciones asociadas al servicio.

La información del origen y destino procede de los datos del servicio almacenados en el sistema.

### 🚨 Incidencias

La aplicación dispone de un sistema de información de incidencias.

Permite:

- Detectar si existe una incidencia activa.
- Mostrar un aviso en la pantalla principal.
- Abrir el detalle de la incidencia.
- Informar cuando la línea funciona con normalidad.

### 🔄 Actualización automática

La información de circulación se actualiza automáticamente.

La aplicación realiza periódicamente una nueva sincronización para mantener actualizada la posición y el estado de los trenes.

También se realiza una actualización cuando la aplicación vuelve a estar en primer plano.

### ☁️ Datos y sincronización

La aplicación utiliza servicios de backend para obtener y procesar la información ferroviaria.

Entre los datos utilizados se encuentran:

- Identificación del tren.
- Línea.
- Servicio.
- Posición GPS.
- Estación actual.
- Estación anterior y siguiente.
- Dirección.
- Origen y destino.
- Horario programado.
- Retraso.
- Estado del tren.

## 🧭 Resumen de funcionalidades

| Función | Estado |
|---|---|
| Trenes R11 | ✅ |
| Trenes RG1 | ✅ |
| Posición GPS | ✅ |
| Dirección del tren | ✅ |
| Retrasos | ✅ |
| Indicador Sin GPS | ✅ |
| Consulta de recorrido | ✅ |
| Horarios | ✅ |
| Laborables | ✅ |
| Fines de semana y festivos | ✅ |
| Información de incidencias | ✅ |
| Estado de conexión | ✅ |
| Actualización automática | ✅ |

## 🚆 Objetivo de la aplicación

**R11 Localizador** tiene como objetivo ofrecer una visualización sencilla y rápida del estado de la circulación ferroviaria en las líneas **R11 y RG1**, permitiendo saber dónde se encuentran los trenes, en qué dirección circulan, si acumulan retraso y consultar la información de sus servicios y horarios.

# 🚀 Novedades y mejoras — Versión 0.1.13

Se ha realizado una revisión general de la aplicación para mejorar su **estabilidad, precisión, velocidad de uso y funcionamiento tanto en Web como en Android**.

### 🚆 Mayor precisión en la información de los trenes

* Se ha mejorado el cálculo de los **retrasos y desfases horarios** para ofrecer tiempos más precisos.
* Se ha corregido el comportamiento de los trenes que **cruzan la medianoche**, evitando errores en los horarios.
* Se han ajustado determinados desfases individuales de algunos trenes para evitar que una anomalía afecte al resto de la línea.
* Se ha reforzado la estabilidad del sistema de datos y la seguridad de las operaciones internas.

### 🚨 Nuevo sistema de avisos e incidencias

* La aplicación incorpora ahora **avisos oficiales de Renfe**.
* Se muestran incidencias que afectan a las líneas **R11 y RG1**.
* El sistema analiza los avisos para mostrar únicamente aquellos relevantes para el ámbito de la aplicación.
* Se ha mejorado la gestión de los caracteres especiales para que los nombres y avisos se muestren correctamente, incluyendo **tildes, ñ y ç**.

### 🌐 Mejoras importantes en la versión Web

* Se ha solucionado el acceso a los servicios de información de Renfe desde la versión Web.
* Se ha reforzado la conexión con los servicios externos para garantizar un funcionamiento más estable en producción.
* Las alertas funcionan correctamente tanto en **Web como en Android**.

### 📅 Corrección de horarios y calendarios

* Se ha corregido la duplicación de horarios al consultar los servicios de un tren.
* Se han diferenciado correctamente los horarios de **días laborables** y **sábados, domingos y festivos**.
* Se ha mejorado la sincronización entre los horarios mostrados y la información almacenada.

### 🎯 Mejor selección de trenes

* Se ha mejorado la selección de trenes en el mapa.
* Ahora es posible seleccionar con mayor precisión un tren incluso cuando **varios trenes circulan o se cruzan en posiciones muy próximas**.
* Se han reducido los errores de selección al pulsar sobre el mapa.

### 🖥️ Mejor experiencia en ordenadores

* Se ha optimizado la interfaz para pantallas grandes.
* Los paneles, botones y menús utilizan ahora un diseño más **compacto y cómodo para ordenador**.
* Se ha mejorado la distribución general de los elementos para aprovechar mejor el espacio disponible.

### 🎨 Mejoras visuales y de identidad

* Se ha automatizado la preparación de los elementos gráficos de la aplicación.
* Se han actualizado y optimizado los **iconos, favicon y elementos de marca** para las distintas plataformas.
* Se ha mejorado la adaptación visual entre Android y Web.

### ✅ Resultado

Esta versión supone una mejora general de la aplicación, especialmente en:

**✔️ Precisión de los horarios y retrasos**
**✔️ Información de incidencias en tiempo real**
**✔️ Estabilidad de la conexión**
**✔️ Funcionamiento Web y Android**
**✔️ Selección de trenes en el mapa**
**✔️ Visualización de horarios**
**✔️ Experiencia de uso en ordenador**
**✔️ Imagen y presentación de la aplicación**
