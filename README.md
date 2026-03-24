# Klausurtimer

Ein professioneller Timer für Schulen – damit mehrere Kurse gleichzeitig im Blick bleiben.

---

## Was macht diese App?

Stell dir vor: In eurer Aula schreiben heute vier Kurse gleichzeitig eine Klausur. Der Mathe-Leistungskurs hat 90 Minuten, Deutsch hat 135 Minuten, und zwei Schüler im Englisch-Kurs haben Nachteilsausgleich und dürfen 30 Minuten länger schreiben.

Genau das kann diese App. Du richtest jeden Kurs einzeln ein, startest alle Timer auf einmal – und bekommst automatisch eine Benachrichtigung, wenn ein Kurs fertig ist, mit einer individuellen Nachricht für die Schülerinnen und Schüler.

**Funktionen:**
- Beliebig viele Kurse gleichzeitig
- Nachteilsausgleich (NTA) als Zusatzzeit pro Kurs einstellbar
- Individuelle Abschlussnachricht je Kurs
- Timer einzeln oder alle auf einmal starten, pausieren, zurücksetzen
- Funktioniert auf Android und iOS
- Vollständig auf Material Design 3 (aktuelles Google Design) aufgebaut

---

## Für Einsteiger: Was ist Flutter?

Flutter ist ein kostenloses Programm von Google, mit dem man Apps für Android, iOS, Windows und mehr gleichzeitig bauen kann – alles aus einer einzigen Code-Basis. Du schreibst den Code einmal, und die App läuft überall.

Die Programmiersprache dahinter heißt **Dart** – sie sieht ähnlich aus wie Java oder JavaScript und ist relativ leicht zu lernen.

---

## Installation Schritt für Schritt

### Schritt 1: Flutter installieren

1. Gehe zu [flutter.dev](https://flutter.dev) und klicke auf **Get started**
2. Wähle dein Betriebssystem (Windows, macOS oder Linux)
3. Folge der Anleitung auf der Website – das dauert etwa 15–30 Minuten

**Kurz gesagt:** Du lädst Flutter herunter, entpackst es und fügst es zu deinem „PATH" hinzu (das ist eine Liste von Programmen, die dein Computer immer findet). Die Flutter-Anleitung erklärt das Schritt für Schritt.

### Schritt 2: Prüfen, ob alles funktioniert

Öffne ein Terminal (unter Windows: **Eingabeaufforderung** oder **PowerShell**, unter macOS: **Terminal**) und tippe:

```
flutter doctor
```

Dieses Kommando zeigt dir, was noch fehlt. Grüne Häkchen bedeuten: alles in Ordnung.

> Für reine Android-Entwicklung reicht es, wenn Android Studio installiert ist. Für iOS brauchst du einen Mac mit Xcode.

### Schritt 3: Ein neues Flutter-Projekt anlegen

Navigiere im Terminal zu dem Ordner, in dem du das Projekt ablegen möchtest, z.B.:

```
cd Desktop
```

Dann erstelle ein neues Projekt:

```
flutter create klausurtimer
```

Das dauert einen Moment. Danach gibt es einen neuen Ordner namens `klausurtimer`.

### Schritt 4: Den Code dieser App einbauen

Kopiere den Inhalt des `lib/`-Ordners aus diesem Projekt in den `lib/`-Ordner deines neu erstellten Projekts. (Den alten Inhalt – meist nur `main.dart` – kannst du dabei ersetzen.)

Ersetze außerdem die `pubspec.yaml`-Datei mit der aus diesem Projekt.

### Schritt 5: Abhängigkeiten herunterladen

Im Terminal, im Ordner deines Projekts:

```
flutter pub get
```

Das lädt alle nötigen Pakete (wie `provider` und `uuid`) herunter. 

### Schritt 6: App starten

Schließe dein Handy per USB an oder starte einen Emulator. Dann:

```
flutter run
```

Die App sollte nun auf deinem Gerät oder Emulator erscheinen! 🎉

---

## Projektstruktur erklärt

```
lib/
├── main.dart               → Einstiegspunkt der App
├── app.dart                → Haupt-App-Widget mit Theme
├── theme/
│   └── app_theme.dart      → Farben, Schriften, Button-Stile
├── models/
│   └── exam_session.dart   → Datenmodell: was ist ein Kurs?
├── providers/
│   └── exam_provider.dart  → Die Logik: Timer starten, pausieren, etc.
├── screens/
│   └── home_screen.dart    → Der Hauptbildschirm
├── widgets/
│   ├── exam_card.dart      → Die Timer-Karte für jeden Kurs
│   ├── add_exam_sheet.dart → Formular zum Hinzufügen eines Kurses
│   └── completion_dialog.dart → Dialog, der erscheint wenn die Zeit abläuft
└── utils/
    └── time_formatter.dart → Hilfsfunktionen zur Zeitformatierung
```

**Warum so viele Dateien?** In echten Projekten teilt man den Code auf viele kleine Dateien auf. So bleibt alles übersichtlich. Wenn du einen Bug in der Timer-Logik suchst, weißt du sofort: der steckt in `exam_provider.dart`. Wenn das Design des Formulars falsch ist, schaust du in `add_exam_sheet.dart`.

---

## Wie die App funktioniert (kurz erklärt)

Die App nutzt das `provider`-Paket für sogenanntes **State Management** – das bedeutet: der `ExamProvider` hält alle Daten (welche Kurse gibt es, wie viel Zeit ist noch übrig) und informiert die Benutzeroberfläche automatisch, wenn sich etwas ändert.

Ein Timer (`dart:async → Timer.periodic`) läuft einmal pro Sekunde und aktualisiert alle laufenden Countdown-Timer. Wenn ein Timer auf null läuft, wird der Kurs als fertig markiert und der Dialog wird angezeigt.

---

## Häufige Probleme

**`flutter: command not found`**
→ Flutter wurde nicht zum PATH hinzugefügt. Folge der Flutter-Anleitung nochmal bei Schritt 3.

**`No devices found`**
→ Kein Gerät verbunden und kein Emulator gestartet. Öffne Android Studio → Virtual Device Manager und starte einen Emulator.

**Fehler beim `flutter pub get`**
→ Prüfe deine Internetverbindung. Manchmal hilft `flutter clean` und dann nochmal `flutter pub get`.

---

## Weiterentwicklung

Du möchtest die App anpassen? Hier sind gute Einstiegspunkte:

- **Farben ändern:** In `lib/theme/app_theme.dart` die `_seed`-Farbe anpassen
- **Standard-Abschlussnachricht ändern:** In `lib/widgets/add_exam_sheet.dart` die Variable `_defaultMessage` bearbeiten
- **Neue Felder zum Formular hinzufügen:** In `lib/widgets/add_exam_sheet.dart` und `lib/models/exam_session.dart`

---

## Anforderungen

- Flutter SDK 3.2.0 oder neuer
- Android SDK 21+ (Android 5.0) oder iOS 12+
- Für die Entwicklung: Android Studio oder VS Code mit Flutter-Plugin

---

*Gebaut mit Flutter & Material Design 3 · Für die Grace Hopper Gesamtschule Teltow*
