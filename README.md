# 🎵 Melox – Premium Flutter Music Player

Melox is a **premium dark minimal music player for Android** built with Flutter.
Featuring a stunning UI, synced lyrics, native equalizer, and full theme customization.

## ✨ Features

### 🎨 Personalization
- 6 vibrant color themes — Lime, Purple, Green, Orange, Yellow, Pink
- Persisted theme selection across app restarts
- Plus Jakarta Sans font throughout

### 🎵 Library
- Auto-scan local MP3 library from device storage
- Search songs by title, artist or album
- Sort by Title, Artist, Album or Date Added
- Favorites — mark and filter favorite songs
- Delete songs from device

### ▶️ Playback
- Full playback controls — Play, Pause, Next, Previous
- Shuffle and repeat modes (Off / All / One)
- Seek with animated wave progress bar
- Volume control
- Swipe album art to skip tracks
- Background audio with lock screen notification
- Queue management — view and jump to any song

### 🎤 Lyrics
- Auto-fetched synced lyrics via LrcLib API
- Line-by-line highlighting in sync with playback
- Tap any line to seek to that timestamp
- Smart title/artist cleaning for better matching
- Fallback to plain lyrics when synced unavailable

### 🎛️ Equalizer
- Native Android AudioEffect equalizer via MethodChannel
- 5-band EQ — 60Hz, 230Hz, 910Hz, 4kHz, 14kHz
- Built-in presets — Flat, Bass Boost, Vocal, Rock, Electronic, Jazz
- Save and delete custom presets

### 📋 Playlists
- Create, rename and delete playlists
- Add songs via long press
- Swipe to remove songs from playlist
- Play all songs in a playlist

### ✨ UI & Animations
- Cinematic splash screen with orbital rings and waveform
- Premium Now Playing with rotating album art and ambient glow
- Wave-style static progress bar
- Animated lyric lines with scale + glow on activation
- Smooth screen transitions throughout
- Mini player above navigation bar

## 🚀 Tech Stack

| Layer | Technology |
|---|---|
| UI | Flutter + Material 3 |
| State | Riverpod 3 (Notifier) |
| Audio | just_audio + audio_service |
| Library scan | on_audio_query |
| Storage | Hive CE |
| Fonts | Google Fonts (Plus Jakarta Sans) |
| Lyrics | LrcLib API (http) |
| Equalizer | Native Android AudioEffect (MethodChannel) |
| Permissions | permission_handler |

## 📱 Platform Support

| Platform | Status |
|---|---|
| Android | ✅ Supported (API 23+) |
| iOS | 🚧 Not tested |

## 📦 Installation

1. Clone the repository
```bash
git clone https://github.com/utk4rsh92/melox.git
```

2. Navigate to the project directory
```bash
cd melox
```

3. Install dependencies
```bash
flutter pub get
```

4. Run code generation (Hive adapters)
```bash
dart run build_runner build --delete-conflicting-outputs
```

5. Run the app
```bash
flutter run
```

## 📁 Project Structure
```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── theme/app_theme.dart        # 6 color themes
│   └── services/
│       ├── equalizer_service.dart  # EQ MethodChannel
│       └── media_store_service.dart
├── domain/
│   ├── entities/                   # Song, Playlist, EQPreset, LyricLine
│   └── repositories/               # Abstract interfaces
├── data/repositories/              # Hive + OnAudioQuery implementations
├── application/providers/          # Riverpod Notifiers
└── presentation/
    ├── screens/
    │   ├── splash/
    │   ├── home/
    │   ├── library/
    │   ├── now_playing/
    │   ├── playlists/
    │   ├── equalizer/
    │   └── lyrics/
    └── widgets/
        ├── mini_player.dart
        ├── song_tile.dart
        ├── album_art.dart
        └── theme_picker.dart
```

## 🎯 About

Melox was built to demonstrate how Flutter can be used to create a **production-grade local music player** with premium UI, smooth animations, and native Android integration.

## 🤝 Contributions

Contributions, suggestions, and improvements are welcome. Feel free to open an issue or submit a pull request.

## 📄 License

This project is open-source and available under the MIT License.
