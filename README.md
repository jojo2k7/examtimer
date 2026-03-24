# 📚 Klausurtimer

Ein professioneller Prüfungstimer für Schulen – entwickelt für den Einsatz auf einem iPad, das per Beamer für alle Schülerinnen und Schüler sichtbar gemacht wird.

---

## Was macht diese App?

Stell dir vor: In eurer Aula schreiben heute vier Kurse gleichzeitig eine Klausur. Mathe-LK hat 30 Minuten hilfsmittelfreien Teil und dann 90 Minuten Hauptteil, Deutsch hat 135 Minuten, und zwei Schülerinnen im Englisch-Kurs haben Nachteilsausgleich (NTA) und dürfen 30 Minuten länger schreiben. Ein fünfter Kurs kommt dazu.

Genau das kann diese App. Alle Kurse sind gleichzeitig sichtbar, die Timers laufen parallel, Übergänge zwischen Phasen passieren automatisch – und wenn du die App versehentlich schließt, ist nichts verloren.

### Funktionen im Überblick

**Timer & Phasen**
- Beliebig viele Kurse einrichten und gleichzeitig starten
- Drei Phasen pro Kurs: hilfsmittelfreier Teil → Hauptteil → NTA
- Automatischer Übergang zwischen Phasen ohne manuellen Eingriff
- Während des hilfsmittelfreien Teils: kleine Anzeige der verbleibenden **Gesamtzeit** (also inkl. Hauptteil und NTA)
- Einzelne Timer starten, pausieren oder zurücksetzen

**NTA (Nachteilsausgleich)**
- Pro Kurs aktivierbar, mit frei wählbarer Zusatzzeit in Minuten
- Läuft automatisch nach dem Hauptteil an
- Während des Hauptteils wird die NTA-Zusatzzeit sichtbar als Hinweis angezeigt – die angezeigte Zeit bezieht sich aber immer nur auf die aktuelle Phase
- Eigene Farbe (rot) und eigene Fortschrittsanzeige für die NTA-Phase

**Abschlussnachrichten**
- Beim Ende des hilfsmittelfreien Teils: individueller Hinweis für die Schüler:innen
- Beim Ende der Klausur: vollständige Abschlussnachricht (z.B. „Bitte legen Sie Ihren Stift ab…")
- Mehrere Nachrichten können in einer Warteschlange stehen und werden nacheinander angezeigt

**Beamer-Optimierung**
- Bis zu 4 Kurse werden gleichzeitig in einem 2×2-Raster angezeigt
- Die Karten passen sich automatisch an die verfügbare Bildschirmgröße an und füllen den Platz optimal aus
- Ab 5 oder mehr Kursen: automatischer Seitenwechsel alle 10 Sekunden mit sanftem Fade-Übergang
- Seitenindikator mit manuell tippbaren Punkten (Dots) – bei Antippen pausiert die automatische Rotation kurz
- Die AppBar bleibt kompakt, damit maximale Fläche für die Karten bleibt

**Persistenz – kein Datenverlust**
- Alle Kurse inkl. Laufzustand werden automatisch gespeichert
- Nach einem App-Absturz oder Neustart werden alle Timer wiederhergestellt
- Laufende Timer berechnen die Zwischenzeit korrekt nach (basierend auf der gespeicherten Startzeit)

---

## Für Einsteiger: Was ist Flutter?

Flutter ist ein kostenloses Framework von Google, mit dem man Apps für Android, iOS, Windows und mehr aus einer einzigen Code-Basis bauen kann. Die Programmiersprache heißt **Dart** – sie ist relativ leicht zu lernen und sieht ähnlich aus wie Java oder JavaScript.

---

## Installation Schritt für Schritt

### Schritt 1: Flutter installieren

1. Gehe auf [flutter.dev](https://flutter.dev) → **Get started**
2. Wähle dein Betriebssystem (Windows, macOS oder Linux)
3. Folge der Anleitung – das dauert etwa 15–30 Minuten

Du lädst Flutter herunter, entpackst es und fügst es zu deinem „PATH" hinzu (eine Liste von Programmen, die dein Computer automatisch findet). Die Flutter-Anleitung erklärt das Schritt für Schritt.

### Schritt 2: Prüfen, ob alles funktioniert

Öffne ein Terminal (Windows: **Eingabeaufforderung** oder **PowerShell**, macOS: **Terminal**) und tippe:

```
flutter doctor
```

Grüne Häkchen bedeuten: alles in Ordnung. Für reine iPad-Entwicklung brauchst du einen Mac mit Xcode.

### Schritt 3: Neues Flutter-Projekt anlegen

Navigiere in den Ordner, in dem das Projekt liegen soll:

```
cd Desktop
```

Dann:

```
flutter create klausurtimer
```

### Schritt 4: Den Code einbauen

Kopiere den gesamten Inhalt des `lib/`-Ordners aus diesem Projekt in den `lib/`-Ordner deines neu erstellten Projekts (alten Inhalt ersetzen). Ersetze außerdem die `pubspec.yaml` mit der aus diesem Projekt.

### Schritt 5: Abhängigkeiten herunterladen

```
flutter pub get
```

Das lädt alle nötigen Pakete herunter (`provider`, `uuid`, `shared_preferences`).

### Schritt 6: App starten

Schließe dein iPad per USB an oder starte einen Simulator. Dann:

```
flutter run
```

---

## Projektstruktur erklärt

```
lib/
├── main.dart                     → Einstiegspunkt der App
├── app.dart                      → Haupt-App-Widget mit Theme-Konfiguration
├── theme/
│   └── app_theme.dart            → Material 3 Farben, Formen und Stile
├── models/
│   └── exam_session.dart         → Datenmodell: Kurs, Phasen, Timer-Logik, JSON-Serialisierung
├── providers/
│   └── exam_provider.dart        → Zustand: Timer starten/pausieren, Phasenwechsel, Persistenz
├── screens/
│   └── home_screen.dart          → Hauptbildschirm mit Beamer-Grid und Carousel
├── widgets/
│   ├── exam_card.dart            → Timer-Karte pro Kurs mit Phasen- und Zeitanzeige
│   ├── add_exam_sheet.dart       → Formular zum Hinzufügen und Bearbeiten eines Kurses
│   └── completion_dialog.dart    → Dialog bei Phasen- und Klausurende
└── utils/
    └── time_formatter.dart       → Hilfsfunktionen zur Zeitformatierung
```

**Warum so viele Dateien?** In echten Projekten teilt man Code auf viele kleine Dateien auf – so bleibt alles übersichtlich und auffindbar. Wenn ein Bug in der Timer-Logik steckt, weißt du sofort: schau in `exam_provider.dart`. Wenn das Grid falsch angezeigt wird: `home_screen.dart`.

---

## Wie die App technisch funktioniert

**State Management mit Provider:** Der `ExamProvider` hält alle Daten (welche Kurse existieren, welche Phase läuft, wie viel Zeit noch übrig ist) und informiert die Oberfläche automatisch bei jeder Änderung.

**Timer:** Ein `Timer.periodic` läuft einmal pro Sekunde. Er prüft bei jedem Tick, ob eine Phase abgelaufen ist, und führt dann automatisch den Phasenwechsel durch oder markiert den Kurs als fertig.

**Persistenz:** Alle Sessions werden bei jeder Änderung als JSON in `SharedPreferences` gespeichert (vergleichbar mit `localStorage` im Web). Beim Start lädt der Provider diese Daten und stellt alle Timer wieder her. Da laufende Timer den Zeitpunkt ihres Starts als `DateTime` speichern, kann die Zwischenzeit nach einem Neustart korrekt nachberechnet werden.

**Beamer-Grid:** Ein `LayoutBuilder` misst den verfügbaren Platz und berechnet das optimale Seitenverhältnis (`childAspectRatio`) für die Karten dynamisch. So füllen 4 Karten immer exakt den Bildschirm aus – egal ob iPad Pro, iPad Mini oder ein anderes Gerät. Bei mehr als 4 Kursen rotiert ein `Timer.periodic` alle 10 Sekunden zur nächsten Seite, animiert mit einem `AnimationController`.

---

## Häufige Probleme

**`flutter: command not found`**
→ Flutter wurde nicht zum PATH hinzugefügt. Wiederhole die Flutter-Installation bei Schritt 3.

**`No devices found`**
→ Kein Gerät verbunden und kein Simulator gestartet. Öffne Xcode → Simulatoren, oder verbinde ein iPad per USB.

**Fehler bei `flutter pub get`**
→ Prüfe deine Internetverbindung. Manchmal hilft `flutter clean` und danach nochmal `flutter pub get`.

**Timer läuft nach Neustart nicht weiter**
→ Das ist normal bei `ExamStatus.paused`. Nur laufende Timer (Status `running`) werden mit korrekter Zwischenzeit fortgesetzt. Pausierte Timer bleiben an dem Punkt stehen, an dem sie pausiert wurden.

---

## Anpassungen

- **Rotationsintervall ändern (Carousel):** In `home_screen.dart` → `_BeamerGridState` → `_rotateDuration`
- **Farbe ändern:** In `lib/theme/app_theme.dart` → `_seed`
- **Standard-Abschlussnachricht:** In `lib/widgets/add_exam_sheet.dart` → `_defaultCompletionMessage`
- **Standard NTA-Nachricht:** In `lib/widgets/add_exam_sheet.dart` → `_defaultToolFreeMessage`

---

## Anforderungen

- Flutter SDK 3.2.0 oder neuer
- iOS 12+ / iPadOS 12+ (für iPad-Einsatz)
- Für die Entwicklung: macOS mit Xcode (für iOS/iPadOS), oder Windows/Linux für Android

---

*Gebaut mit Flutter & Material Design 3 · Für die Grace Hopper Gesamtschule Teltow*