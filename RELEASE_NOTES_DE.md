# MUI Reborn 1.0.1-rc - vollständiger Release-Kandidat

Stand: 22.10.2026. Das ZIP enthält den vollständigen aktuellen MUI-Reborn-Ordner einschließlich aller bisherigen Korrekturen, vier TOCs und fünf vorgesehener Clientvarianten: Retail/Forever gemeinsam, Era, TBC und MoP separat.

## Installation und Abhängigkeiten

WoW beenden. Den Ordner MUI-Reborn nach Interface/AddOns des gewünschten Clients übernehmen und vorhandene Dateien ersetzen. Keine doppelte Ordnerverschachtelung. Anschließend WoW vollständig neu starten. Profile behalten; das Setup muss für ein Update nicht erneut ausgeführt werden.

Bartender4 und zum Client passende Shadowed Unit Frames sind separat erforderlich. Laut Nutzer wurden die älteren Clients mit dem ursprünglichen SUF getestet, nicht Redux. Redux ist keine allgemeine Pflicht für alle Clients; erforderlich ist die Addon-Kennung ShadowedUnitFrames.

MBB, Masque und Bagnon sind optional und nicht enthalten. Für das integrierte MUI-Inventar ist Bagnon nicht erforderlich. Ungewollt gleichzeitig geöffnete Taschenfenster vermeiden, indem nur das gewünschte Inventar aktiviert wird.

## Enthaltene Änderungen

- Clientbezogene Ladefolgen einschließlich LibAddonCompat; zusätzliche Classic-Bibliotheken für Era.
- Unabhängiger Minimap-Anker für geschützte Auren in Era/TBC/MoP.
- Korrekturen für Blizzard-Bearbeitungsmodus, Chat-Menüs und Era-/MoP-Berufszeilen.
- MoP-Dungeonbrowser statt Fähigkeiten, auch bei Anzeige alter Profilbelegungen.
- AddOn-Symbolgröße standardmäßig 0,8; gespeicherte Werte bleiben erhalten.
- Vorherige RC-Korrekturen: Retail-Spezialisierungswechsel, Fehleranzeige-Fallback, Minimap-Skalierung, öffentliche Versionsmeldungen und optionale MBB-Menügestaltung.
- Bagnon-Setup-Import gezielt für 12.1.7 korrigiert; keine automatische Migration bestehender Bagnon-Profile.

## Prüfstand und offene Punkte

Der Nutzer meldete die bisher geprüften Funktionen in Era/TBC sauber und die MoP-Menüs soweit lauffähig. Dies ist keine vollständige Freigabe sämtlicher Funktionen oder Clients.

Offen: Era-Tracking-Menü meldet fehlenden Menüpfad. Ein Ersatzsymbol ohne aktive Aufspür-Fähigkeit wurde noch nicht eingebaut. Die aktive Kräutersuche erscheint, wenn Ausblenden deaktiviert ist. MoP-Dungeonbrowser-Klick wegen Charakterstufe noch nicht geprüft. Vollständige Regressionstests aller Varianten fehlen.

Statische Paketprüfung: TOC/XML-Dateiverweise, XML-Parsebarkeit, Bibliotheksreihenfolge, konsistente Versionen, unveränderte Lua-Prüfsummen und vollständiger ZIP-Dateilisten-/Bytevergleich. Keine Lua-Syntaxprüfung mangels Interpreter, keine eigenen WoW-Laufzeittests.

## Veröffentlichung

Nur lokal vorbereitet; kein Upload, keine Veröffentlichung. Version 1.0.1-rc und X-Public-Version 1.0.0-rc.1 bleiben bestehen. Vor Veröffentlichung den öffentlichen Marker ausdrücklich abstimmen und CurseForge-Spielversionen passend zuordnen. Mehrere Client-TOCs gehören zum Paket.
