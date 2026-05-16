# Cloud Eyes

Neue Augen-Bilder fuer das EyePair-System einfach hier reinwerfen.

## Wie ein neues Auge hinzufuegen

1. **PNG erstellen** — am besten **160 x 160 Pixel** (die App resized aber bei Bedarf auch automatisch)
2. **Aussagekraeftigen Dateinamen geben**, z.B. `Drache.png`, `Maus.png`, `Pirat.png`
3. **In diesen Ordner committen + pushen**:
   ```bash
   git add cloud-eyes/Drache.png
   git commit -m "Add Drache eye"
   git push
   ```
4. **In der App**: Tab "Cloud" oeffnen → Refresh (Pull-to-Refresh oben) → neues Auge erscheint mit Vorschau
5. **Upload** Button drueecken → Slot 1-5 waehlen → Upload startet (~10-15s)
6. **Im Eye-Grid** unter "Cloud 1..5" antippen → beide Eye-Module zeigen das neue Auge

## Technisches Format

- Quelle: PNG oder JPG, beliebige Groesse
- Pipeline: App → `image` package decoded + resized auf 160x160 → RGB565 LE → BLE-Upload
- Auf dem ESP gespeichert: `/eyes/0X.bin` in LittleFS (50 KB RGB565 raw)

## Tipps

- Helle/saettigung-starke Augen wirken besser auf dem 0.71" LCD
- Schwarzer Hintergrund spart Energie
- Ovaler/runder Pupillen-Bereich an Display-Zentrum platzieren
