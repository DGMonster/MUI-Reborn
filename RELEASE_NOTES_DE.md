# MUI Reborn 1.0.3 – 06.11.2026

## Änderungen
- Eigene Spieler- und Ziel-Timerleisten in WoW Forever wieder nutzbar, mit Blizzards nativer Aurenanzeige. Automatischer Start anhand des vorhandenen Profils; kein zusätzlicher AuraTimers-Download erforderlich.
- Zielwechsel aktualisieren die Timerleisten; kein Ziel oder totes Ziel blendet die Zielgruppe aus, soweit der Client den Einheitenzustand freigibt.
- Forever-Spielerzauberleiste im MUI-Stil, an das SUF-Porträt angelegt. Blizzard steuert weiterhin Zauberdauer und Ereignisse.
- Ebenen der Einheitenpanels korrigiert: SUF-Porträts und Lebensleisten erscheinen vor den Panels.
- Fehlende Spezialisierung beim Levelaufstieg abgefangen, insbesondere vor der Talentfreischaltung.
- Forever-Realm-Platzhalter aus der AFK-Anzeige entfernt; interne Charakter-/Realm-Schlüssel bleiben erhalten.
- Auren- und Zauberleisten-Kompatibilitätshinweise lokalisiert.
- Bestätigte Raid-Manager-Korrektur für den Forever-Bearbeitungsmodus beibehalten.
- Forever-Inventar: Kombinierte Blizzard-Taschen werden ohne Überschreiben von Show und ohne Umhängen ausgeblendet. Dies ist eine noch zu bestätigende Bankkauf-Korrektur.
- Versionsnummer und öffentliche Updatekennung aller vier TOCs auf 1.0.3 gesetzt.

## Installation
WoW schließen und den vollständigen Ordner MUI-Reborn im passenden Interface/AddOns-Verzeichnis ersetzen. SavedVariables behalten; kein erneutes Setup nötig. Bartender4 und die passende SUF-Ausgabe separat installieren: Redux für Retail/Forever, Original für Era/TBC/MoP. Optionale Addons werden nicht mitgeliefert.

## TimerBars in Forever
Aktivierte Spieler-/Zielfelder starten automatisch. /muitimers zeigt sie an, /muitimers off blendet sie bis zum nächsten UI-Neustart aus. Nach Einstellungs- oder Profiländerungen /reload verwenden. Filterlisten werden noch nicht unterstützt; entsprechende Felder werden mit Hinweis übersprungen. Buffs und Debuffs haben getrennte Maximalzahlen und Sortierung. Nicht alle alten Darstellungsoptionen sind umgesetzt. Andere Einheiten sind noch nicht angebunden. Die alten eigenen Aurenframes bleiben unter Forever deaktiviert. Die neue Zauberleistenanpassung betrifft die Spielerleiste; kein vollständiger Ersatz aller alten Zauberleisten.

## Prüfstand und offene Punkte
Vom Nutzer bestätigt: Timerleisten mit Countdown und Ablauf im Kampf, korrekte Zielwechsel, verbesserte Panel-/Zauberleistendarstellung. Nach Inventar-Reaktivierung funktioniert normales Banköffnen; der ursprüngliche Kauf des ersten Bankfachs konnte nach der letzten Änderung nicht erneut getestet werden, weil das Fach bereits gekauft war. Dieser Fix gilt ausdrücklich nicht als bestätigt.

Automatischer TimerBars-Start ist neu in diesem Release und benötigt noch Nutzerprüfung nach /reload. Era-Trackingmenü und MoP-Dungeonbrowser bleiben offene Prüfungen. Kein vollständiger Test aller fünf Clients. Statische Paket-/Ladeverweisprüfungen sind keine WoW-Laufzeittests. Kein Lua-Compiler oder Luacheck in der Arbeitsumgebung verfügbar.
