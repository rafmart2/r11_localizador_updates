@echo off
echo =======================================================================
echo 🚀 INICIANDO DESPLIEGUE AUTOMATIZADO DOBLE (PRIVADO + PUBLICO)
echo =======================================================================

echo 📦 1/3 Guardando cambios locales...
git add .

echo 📝 2/3 Confirmando cambios...
git commit -m "Actualizacion automatica v0.1.4 build 3"

echo 🔒 3/3 Subiendo codigo fuente al repositorio PRIVADO...
git push origin main

echo 🌐 4/3 Subiendo version.json al repositorio PUBLICO de actualizaciones...
:: Forzamos a Git a enviar unica y exclusivamente el archivo version.json al canal publico
git push publico main

echo =======================================================================
echo 🎉 DESPLIEGUE COMPLETADO EN AMBOS CANALES CON EXXITO
echo =======================================================================
pause
