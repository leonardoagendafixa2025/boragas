#!/bin/bash
# ==============================================================================
# Script de Build Automatizado do BoraGás para a Vercel (Flutter Web)
# ==============================================================================

set -e

echo "🚀 Iniciando ambiente de compilação do BoraGás na Vercel..."

# 1. Verifica se o Flutter SDK já está instalado ou clona o canal estável
if [ ! -d "flutter" ]; then
  echo "📦 Clonando Flutter SDK estável..."
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable flutter
fi

# 2. Adiciona o Flutter ao PATH de execução
export PATH="$PATH:`pwd`/flutter/bin"

echo "🔍 Versão do Flutter:"
flutter --version

# 3. Habilita suporte a Web
flutter config --enable-web

# 4. Baixa dependências do projeto
echo "📥 Instalando dependências..."
flutter pub get

# 5. Compila Flutter Web com CanvasKit / Wasm e injeção de credenciais Supabase
echo "⚙️ Compilando Flutter Web em modo release..."
flutter build web --release \
  --no-tree-shake-icons \
  --dart-define=SUPABASE_URL="${SUPABASE_URL}" \
  --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY}"

# 6. Garante que os arquivos APK de download estejam presentes no build estático final
echo "📦 Copiando instalador APK para o diretório público de distribuição..."
mkdir -p build/web/downloads
if [ -f "web/downloads/BoraGas-release.apk" ]; then
  cp web/downloads/BoraGas-release.apk build/web/downloads/BoraGas-release.apk
fi
if [ -f "web/BoraGas-release.apk" ]; then
  cp web/BoraGas-release.apk build/web/BoraGas-release.apk
fi
if [ -f "web/OneSignalSDKWorker.js" ]; then
  cp web/OneSignalSDKWorker.js build/web/OneSignalSDKWorker.js
fi

echo "✅ Compilação concluída com sucesso! Saída gerada em build/web"
