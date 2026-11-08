# MUI Reborn 1.0.5 – 08.11.2026

## Änderungen

- Fehlerhafte Profilbehandlung im Installer korrigiert, durch die die Installation auf einem weiteren Charakter Bartender4- und Einheitenrahmen-Einstellungen anderer Charaktere zurücksetzen konnte.
- Bei aktivierter Option für Charakterprofile erhalten MUI, Bartender4 und SUF eigene Profile pro Charakter. Vorhandene Einstellungen werden kopiert, gemeinsame Profile bleiben erhalten.
- Addon-Voreinstellungen werden nur auf die Profile des aktuellen Charakters angewendet. Andere Charaktere und sonstige Addon-Einstellungen bleiben erhalten.
- Fehlenden Übersetzungsschlüssel im Profilmanager korrigiert.
- Standardrahmen der Reagenzientaschenplätze unter WoW Forever dezent in Klassenfarbe dargestellt. Gegenstandsqualität und bestehende Rahmenprioritäten bleiben erhalten.

## Update

WoW schließen, den WTF-Ordner sichern und den vollständigen Ordner `MUI-Reborn` austauschen. Der Installer muss nicht erneut ausgeführt werden. Bereits früher überschriebene Einstellungen können nicht automatisch wiederhergestellt werden.

## Prüfstand

Isolierte Tests mit der vorhandenen AceDB-Bibliothek prüfen Charakterwechsel, Installation auf einem anderen Charakter und getrennte Profile. Der Nutzer bestätigt, dass der Übersetzungsfehler nicht mehr erscheint. Der vollständige Ablauf Lyralei → Rabia mit Installation → Lyralei ist noch im Spiel zu bestätigen. Keine eigenen WoW-Laufzeittests und kein vollständiger Test aller Clients.

Die Verbesserungen aus 1.0.4 sind enthalten; die bisherigen weiteren Prüfgrenzen gelten weiterhin.

---

# MUI Reborn 1.0.4 – 08.11.2026

## Änderungen für WoW Forever

- MUI-Gestaltung des Blizzard-Gruppen-/Raidmanagers wiederhergestellt, einschließlich Pfeilen im geöffneten und geschlossenen Zustand.
- Charakterfenster, Zauberbuch und Gilde/Communitys am gepunkteten Griff in der Titelleiste verschiebbar. Positionen werden gespeichert; bei Kampfbeginn wird ein laufendes Verschieben abgebrochen. Steuerung über die vorhandene Option für Blizzard-Fenster und `/muimove`.
- Zauberbuch-Schaltfläche am MUI-Chat an Blizzards native Micro-Schaltfläche angebunden. Korrigiert den gemeldeten Bearbeitungsmodus-Fehler nach Nutzung dieses Öffnungswegs.
- Bestehende Master-Schrift-Option wirkt auf ausgewählte Überschriften von Charakterfenster und Zauberbuch. Globale Blizzard-Schriftobjekte werden dabei nicht ersetzt.
- Natives Lua-Fehlerfenster im MUI-Stil und zusätzlicher Knopf zum bestehenden MUI-Fehlerbericht. Fehlertext und native Aktionen bleiben erhalten. `/muierrorstyle off` stellt die Originaloptik für diese Sitzung wieder her.
- Ausgerüstete Reagenzientasche in die Standard-Inventaransicht und Kategorien einbezogen. Die Taschenanzeige in der Datenleiste zählt ihre Plätze zusätzlich, ohne doppelte Zählung.
- Talentgruppenanzeige „Primär“ beziehungsweise „Sekundär“ statt der unpassenden Retail-Spezialisierung. Tooltip mit Hinweis auf eine noch gesperrte zweite Gruppe. Umschalten weiterhin im Blizzard-Talentfenster; kein Retail-Beutespezialisierungsmenü in Forever.

## Update und bestehende Einstellungen

WoW schließen und den vollständigen Ordner `MUI-Reborn` im passenden `Interface/AddOns/`-Verzeichnis ersetzen. Gespeicherte Einstellungen behalten. Kein erneuter Installer-Durchlauf und kein Profilreset nötig.

Bartender4 und die zum Client passende SUF-Ausgabe bleiben separate Pflichtaddons. Bestehende Retail-/Classic-Wege und gespeicherte Profilformate wurden für dieses Update nicht umgestellt. 

Blizzards Buff-/Debuff-Symbole bleiben in Forever aktiv. Der verworfene Symbolversuch ist nicht enthalten. Die MUI-Timerleisten sind unabhängig davon optional: `/muitimers off` blendet sie für diese Sitzung aus. Für dauerhaftes Abschalten das Modul oder ein einzelnes Feld in der Konfiguration deaktivieren und `/reload` verwenden. Nach Timerleisten-Einstellungs- oder Profiländerungen weiterhin neu laden; nur Spieler/Ziel, keine Filterlisten und nicht sämtliche alten Darstellungsoptionen unterstützt.

## Bestätigte Nutzertests

Bestätigt wurden die Raidmanager-Gestaltung, Bewegung von Charakterfenster und Zauberbuch einschließlich Kampf-Abbruch, ausgewählte Schriftänderungen, Fehlerbericht-Knopf und Fehlerfenster-Optik, das Verschieben von Gilde/Communitys und die Anzeige „Primär“. Die zuvor behobene Bankproblematik wurde bereits mit einem neuen Charakter erfolgreich vom Nutzer geprüft.

## Prüfgrenzen und offene Punkte

- Beibehalten der neuen Gildenfenster-Position nach `/reload` ist noch nicht ausdrücklich bestätigt.
- Reagenzientaschen-Inhalte, Filter, Gegenstandsbewegung und Taschenwechsel benötigen den Nutzertest. Freie Plätze einer Spezialtasche sind nicht für beliebige Gegenstände verwendbar.
- Anzeige „Sekundär“ und Aktualisierung beim echten Talentgruppenwechsel sind noch nicht im Client geprüft.
- Der gemeldete Verlust einer SUF-Gruppenposition wird weiter untersucht. Dieses Update behauptet keine Korrektur dafür; gefundene Speicherstände enthielten bereits die MUI-Voreinstellung.
- Kein vollständiger Test aller Clients. Era-Trackingmenü und MoP-Dungeonbrowser bleiben offene Prüfungen.

Lua-Syntax der geänderten Quelldateien, isolierte Logiktests sowie Ladeverweise und Paketinhalt wurden geprüft. Diese automatisierten Prüfungen ersetzen keine WoW-Laufzeittests; die oben genannten Bestätigungen stammen aus Nutzertests.
