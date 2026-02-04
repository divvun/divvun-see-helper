# Divvun-SEE-helper

Helper-app for SubEthaEdit sine Divvun-modar, designa for å omgå macOS sandbox-restriksjonar.

## Om

SubEthaEdit er ein sandboxa macOS-applikasjon som ikkje kan køyre eksterne binærar direkte. Divvun-SEE-helper.app er ein unsandboxa helper-app som køyrer utanfor sandboxen og gir tilgang til verktøy som `hfst-lookup`, `missing.py` og andre HFST/Giella-verktøy.

## Funksjonalitet

- **Lexc-lexicalise-missing**: Analyserer ord i LexC-filer og gir forslag til manglande lexikon-oppføringar ved å køyre `missing.py` frå giella-core
- **Clipboard-basert kommunikasjon**: Brukar clipboard med base64-koda JSON for sikker dataoverføring mellom sandbox og helper
- **UTF-8-støtte**: Handterer sørsamiske og andre samiske språk med spesialteikn korrekt

## Installasjon

### Enkel installasjon (med Makefile)

```bash
make install
```

Dette kopierer `Divvun-SEE-helper.app` til `~/Applications/`.

### Manuell installasjon

1. Kopier `Divvun-SEE-helper.app` til `~/Applications/`
2. Første gong du køyrer appen må du høgreklikke og velje "Opne" for å godkjenne appen (macOS sikkerheit)

```bash
cp -R Divvun-SEE-helper.app ~/Applications/
```

### For utviklarar: Signering og notarisering

For å distribuere appen utan sikkerheitssperrer frå macOS treng du ein Apple Developer konto.

**1. Konfigurer miljøvariablar:**

Kopier `.env.example` til `.env` og fyll inn verdiane:

```bash
cp .env.example .env
# Rediger .env med dine Apple Developer-detaljar
source .env
```

**2. Signer appen:**

```bash
make sign
# eller direkte: ./sign.sh
```

**3. Notarisér appen:**

```bash
make notarize
# eller direkte: ./notarize.sh
```

Når notariseringa er fullført, kan appen installerast utan sikkerheitssperrer.

## Konfigurasjon

Helper-appen finn automatisk `missing.py` ved å sjekke desse stadene i rekkefølgje:

1. `$GTLANGS/giella-core/scripts/missing.py` (frå JSON-input)
2. `~/.divvun-see-helper-config` (valfri config-fil)
3. `~/langtech/gut/giellalt/giella-core/scripts/missing.py`
4. `~/langtech/giellalt/giella-core/scripts/missing.py`

### Valfri konfigurasjon

Opprett `~/.divvun-see-helper-config` for å spesifisere eigendefinert sti til giella-core og for å slå på logging:

```bash
# Eigendefinert sti til giella-core (valfritt)
export GTCORE=/path/to/giella-core

# Slå på debug-logging (standard er false)
export ENABLE_LOGGING=true
```

## Bruk

Helper-appen blir automatisk starta av SubEthaEdit-modane når du brukar funksjonar som treng eksterne verktøy:

- **LexC-modus**: `⌃⌥⌘M` (Ctrl+Option+Cmd+M) for "Lexicalise missing"

## Debugging

Debug-logging er som standard **avslått** for å unngå unødvendig loggskriving. For å slå på logging, legg til følgjande i `~/.divvun-see-helper-config`:

```bash
export ENABLE_LOGGING=true
```

Når logging er aktivert, vil helper-appen logge all aktivitet til:

```
~/divvun-see-helper-debug.log
```

Sjekk denne fila ved feilsøking.

## Kommunikasjonsprotokoll

Helper-appen kommuniserer via clipboard med JSON-format:

### Input (frå SubEthaEdit):
```json
{
  "operation": "analyze_missing",
  "lang": "sma",
  "gtlangs": "/path/to/lang-sma/..",
  "docname": "filename.lexc",
  "input_words_b64": "<base64-koda ord>"
}
```

### Output (frå helper):
```json
{
  "status": "success",
  "output": "<resultatet frå missing.py>"
}
```

Ved feil:
```json
{
  "status": "error",
  "message": "Feilmelding",
  "details": "Detaljert feilinfo"
}
```

## Systemkrav

- macOS 10.15 eller nyare
- Python 3.9+ (inkludert i Xcode Command Line Tools)
- HFST-verktøy installert (via Homebrew eller manuelt)
- giella-core (for missing.py)

## Arkitektur

```
Divvun-SEE-helper.app/
├── Contents/
│   ├── Info.plist          # App metadata
│   └── MacOS/
│       ├── run-helper      # Wrapper som set UTF-8 locale
│       └── divvun-see-helper  # Hovudskript
```

### Komponenter:

1. **run-helper**: Wrapper-skript som set `LANG=en_US.UTF-8` og `LC_ALL=en_US.UTF-8` før det køyrer hovudskriptet
2. **divvun-see-helper**: Bash-skript som:
   - Les JSON frå clipboard
   - Base64-dekodar input
   - Finn og køyrer missing.py
   - Konstruerer JSON-respons med escaped newlines
   - Skriv resultat tilbake til clipboard

## Lisens

MIT - sjå LICENSE-fila.

## Kontakt

Divvun/Giellatekno
- GitHub: https://github.com/divvun
- Nettside: https://giellalt.github.io
