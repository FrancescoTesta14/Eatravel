#!/bin/bash
# =====================================================================
#  Crea da terminale la base Airtable "App Cibi" con la tabella "Cibi",
#  inserisce 3 cibi di esempio e scrive token + Base ID nel codice Swift.
#  Uso: dalla cartella AirtableCibi ->   bash crea_base.sh
# =====================================================================
cd "$(dirname "$0")"

echo ""
echo "=== Creazione database Airtable — App Cibi ==="
echo ""
read -r -p "Incolla il Personal Access Token (inizia con pat...): " TOKEN
read -r -p "Incolla il Workspace ID (inizia con wsp...): " WORKSPACE_ID
TOKEN=$(echo "$TOKEN" | tr -d '[:space:]')
WORKSPACE_ID=$(echo "$WORKSPACE_ID" | tr -d '[:space:]')

if [[ "$TOKEN" != pat* ]]; then echo "❌ Il token deve iniziare con 'pat'."; exit 1; fi
if [[ "$WORKSPACE_ID" != wsp* ]]; then echo "❌ Il Workspace ID deve iniziare con 'wsp'."; exit 1; fi

TMP=$(mktemp -d)

chiama() {  # $1 = metodo, $2 = url, $3 = file JSON
  HTTP=$(curl -s -o "$TMP/risposta.json" -w "%{http_code}" -X "$1" "$2" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    --data @"$3")
  if [ "$HTTP" -lt 200 ] || [ "$HTTP" -ge 300 ]; then
    echo "❌ Errore $HTTP da Airtable:"
    cat "$TMP/risposta.json"; echo ""
    rm -rf "$TMP"; exit 1
  fi
}

# ---------- Tabella "Cibi" ----------
cat > "$TMP/tabella.json" << 'JSON'
{
  "name": "Cibi",
  "description": "Cibi dell'app. I valori nutrizionali sono riferiti a 100 g di prodotto.",
  "fields": [
    { "name": "Nome", "type": "singleLineText", "description": "Nome del cibo" },
    { "name": "Foto", "type": "multipleAttachments", "description": "Immagine del cibo" },
    { "name": "Categoria", "type": "singleSelect", "options": { "choices": [
      { "name": "Primo" }, { "name": "Secondo" }, { "name": "Contorno" },
      { "name": "Piatto unico" }, { "name": "Colazione" }, { "name": "Dolce" },
      { "name": "Frutta" }, { "name": "Snack" }, { "name": "Bevanda" }, { "name": "Altro" }
    ] } },
    { "name": "Descrizione", "type": "multilineText" },
    { "name": "Ingredienti", "type": "multilineText", "description": "Un ingrediente per riga" },
    { "name": "Allergeni", "type": "multipleSelects", "options": { "choices": [
      { "name": "Glutine" }, { "name": "Crostacei" }, { "name": "Uova" }, { "name": "Pesce" },
      { "name": "Arachidi" }, { "name": "Soia" }, { "name": "Latte" }, { "name": "Frutta a guscio" },
      { "name": "Sedano" }, { "name": "Senape" }, { "name": "Sesamo" }, { "name": "Solfiti" },
      { "name": "Lupini" }, { "name": "Molluschi" }
    ] } },
    { "name": "Porzione (g)", "type": "number", "options": { "precision": 0 }, "description": "Peso di una porzione in grammi" },
    { "name": "Calorie (kcal)", "type": "number", "options": { "precision": 1 }, "description": "Per 100 g" },
    { "name": "Proteine (g)", "type": "number", "options": { "precision": 1 }, "description": "Per 100 g" },
    { "name": "Carboidrati (g)", "type": "number", "options": { "precision": 1 }, "description": "Per 100 g" },
    { "name": "Zuccheri (g)", "type": "number", "options": { "precision": 1 }, "description": "Per 100 g (di cui zuccheri)" },
    { "name": "Grassi (g)", "type": "number", "options": { "precision": 1 }, "description": "Per 100 g" },
    { "name": "Grassi saturi (g)", "type": "number", "options": { "precision": 1 }, "description": "Per 100 g (di cui saturi)" },
    { "name": "Fibre (g)", "type": "number", "options": { "precision": 1 }, "description": "Per 100 g" },
    { "name": "Sale (g)", "type": "number", "options": { "precision": 2 }, "description": "Per 100 g" }
  ]
}
JSON

# ---------- Base completa ----------
{
  echo "{ \"name\": \"App Cibi\", \"workspaceId\": \"$WORKSPACE_ID\", \"tables\": ["
  cat "$TMP/tabella.json"
  echo "] }"
} > "$TMP/base.json"

echo "→ Creo la base 'App Cibi' con la tabella Cibi..."
chiama POST "https://api.airtable.com/v0/meta/bases" "$TMP/base.json"
BASE_ID=$(grep -o '"id" *: *"app[A-Za-z0-9]*"' "$TMP/risposta.json" | head -1 | grep -o 'app[A-Za-z0-9]*')
if [ -z "$BASE_ID" ]; then echo "❌ Base creata ma non trovo il Base ID:"; cat "$TMP/risposta.json"; exit 1; fi
echo "✅ Base creata. Base ID: $BASE_ID"

# ---------- Cibi di esempio ----------
cat > "$TMP/esempi.json" << 'JSON'
{
  "typecast": true,
  "records": [
    { "fields": {
      "Nome": "Pizza Margherita",
      "Categoria": "Piatto unico",
      "Descrizione": "Dato di esempio (valori indicativi).",
      "Ingredienti": "Farina di grano tenero\nPassata di pomodoro\nMozzarella\nOlio extravergine d'oliva\nBasilico\nLievito\nSale",
      "Allergeni": ["Glutine", "Latte"],
      "Porzione (g)": 300,
      "Calorie (kcal)": 250, "Proteine (g)": 11, "Carboidrati (g)": 33, "Zuccheri (g)": 3,
      "Grassi (g)": 8, "Grassi saturi (g)": 3.5, "Fibre (g)": 2, "Sale (g)": 1.2
    } },
    { "fields": {
      "Nome": "Spaghetti al pomodoro",
      "Categoria": "Primo",
      "Descrizione": "Dato di esempio (valori indicativi).",
      "Ingredienti": "Spaghetti\nPassata di pomodoro\nOlio extravergine d'oliva\nAglio\nBasilico\nSale",
      "Allergeni": ["Glutine"],
      "Porzione (g)": 320,
      "Calorie (kcal)": 140, "Proteine (g)": 4.5, "Carboidrati (g)": 25, "Zuccheri (g)": 3,
      "Grassi (g)": 2.5, "Grassi saturi (g)": 0.4, "Fibre (g)": 1.8, "Sale (g)": 0.5
    } },
    { "fields": {
      "Nome": "Mela",
      "Categoria": "Frutta",
      "Descrizione": "Dato di esempio (valori indicativi).",
      "Ingredienti": "Mela",
      "Porzione (g)": 180,
      "Calorie (kcal)": 52, "Proteine (g)": 0.3, "Carboidrati (g)": 14, "Zuccheri (g)": 10,
      "Grassi (g)": 0.2, "Grassi saturi (g)": 0, "Fibre (g)": 2.4, "Sale (g)": 0
    } }
  ]
}
JSON

echo "→ Inserisco 3 cibi di esempio..."
chiama POST "https://api.airtable.com/v0/$BASE_ID/Cibi" "$TMP/esempi.json"
echo "✅ Cibi di esempio inseriti."

# ---------- Scrive token e Base ID nel codice Swift ----------
CONFIG="Swift/AirtableConfig.swift"
if [ -f "$CONFIG" ]; then
  sed -i.bak -e "s|INCOLLA_QUI_IL_TOKEN|$TOKEN|" -e "s|INCOLLA_QUI_IL_BASE_ID|$BASE_ID|" "$CONFIG" && rm -f "$CONFIG.bak"
  echo "✅ Token e Base ID scritti in $CONFIG"
else
  echo "⚠️  Non trovo $CONFIG: incolla a mano token e Base ID ($BASE_ID)."
fi

rm -rf "$TMP"
echo ""
echo "🎉 Fatto! Base ID: $BASE_ID"
echo "   Ora puoi mandare all'amico la cartella AirtableCibi (contiene il token: mandala in privato)."
echo ""
