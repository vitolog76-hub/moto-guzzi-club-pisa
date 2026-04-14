#!/bin/bash

echo "🚀 Avvio del deploy su GitHub Pages..."

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 1. Pulizia e build
echo -e "${BLUE}📦 Build dell'app...${NC}"
flutter clean
flutter pub get
flutter build web --release --base-href /moto-guzzi-club-pisa/

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Errore durante la build!${NC}"
    exit 1
fi

# 2. Copia dei file
echo -e "${BLUE}📁 Copia dei file nella cartella docs...${NC}"
rm -rf docs/*
cp -r build/web/* docs/
cp docs/index.html docs/404.html

# 3. Commit e push
echo -e "${BLUE}💾 Commit su GitHub...${NC}"
git add docs/
git commit -m "Deploy automatico - $(date '+%Y-%m-%d %H:%M:%S')"

echo -e "${BLUE}📤 Push su GitHub...${NC}"
git push

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Errore durante il push! Provo con --set-upstream...${NC}"
    git push --set-upstream origin main
fi

echo -e "${GREEN}✅ Deploy completato!${NC}"
echo -e "${GREEN}🌐 App online su: https://vitolog76-hub.github.io/moto-guzzi-club-pisa/${NC}"
