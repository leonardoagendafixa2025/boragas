@echo off
echo ==========================================
echo   BoraGas - Compilador de APK Android
echo ==========================================
set JAVA_TOOL_OPTIONS=-Djavax.net.ssl.trustStoreType=Windows-ROOT
set GRADLE_OPTS=-Djavax.net.ssl.trustStoreType=Windows-ROOT
echo Compilando APK de Producao para Android...
call flutter build apk --release
echo.
echo ==========================================
echo APK gerado com sucesso em:
echo build\app\outputs\flutter-apk\app-release.apk
echo ==========================================
