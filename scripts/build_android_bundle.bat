@echo off
echo ==========================================
echo   BoraGas - Compilador de Bundle (Google Play)
echo ==========================================
set JAVA_TOOL_OPTIONS=-Djavax.net.ssl.trustStoreType=Windows-ROOT
set GRADLE_OPTS=-Djavax.net.ssl.trustStoreType=Windows-ROOT
echo Compilando AppBundle (AAB) para Google Play Store...
call flutter build appbundle --release
echo.
echo ==========================================
echo AppBundle AAB gerado com sucesso em:
echo build\app\outputs\bundle\release\app-release.aab
echo ==========================================
