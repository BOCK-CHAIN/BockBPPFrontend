# SCHOLAR - Library, Papers & Patents Platform

A Flutter application for managing scholarly resources including books, patents, and scholar profiles. Users can browse, search, and contribute to a collaborative library of academic materials.

## Features

- **User Authentication**: Register and login to access your personal account
- **Book Management**: Browse, search, and contribute book entries to the library
- **Patent Tracking**: View and manage patent information with detailed descriptions
- **Scholar Profiles**: Create and view scholar profiles with their contributions
- **Dark/Light Theme**: Toggle between dark and light themes for comfortable viewing
- **PDF Support**: View and share PDF documents
- **Cross-Platform**: Works on Android, iOS, Web, macOS, and Windows

## Project Structure

```
lib/
├── main.dart                 
├── auth/                     
│   ├── login_screen.dart
│   └── register_screen.dart
├── screens/                  
│   ├── dashboard_screen.dart
│   ├── book_detail_screen.dart
│   ├── book_form_screen.dart
│   ├── patent_detail_screen.dart
│   ├── patent_form_screen.dart
│   ├── scholar_detail_screen.dart
│   ├── scholar_form_screen.dart
│   └── library_screen.dart
├── services/               
│   ├── auth_service.dart
│   ├── book_service.dart
│   ├── patent_service.dart
│   └── scholar_service.dart
├── core/                     
│   ├── constants.dart
│   ├── session.dart
│   ├── json_utils.dart
│   └── pdf_utils.dart
└── widgets/                  
    ├── skeleton.dart
    └── share_bottom_sheet.dart
```

## Getting Started

### Prerequisites

Make sure you have Flutter installed on your machine. If you don't have it, download it from [flutter.dev](https://flutter.dev/docs/get-started/install).

Check your installation:

```bash
flutter doctor
```

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/yourusername/bpp_frontend.git
   cd bpp_frontend
   ```

2. **Get dependencies**

   ```bash
   flutter pub get
   ```

3. **Run the app**
   - For Android emulator or device:
     ```bash
     flutter run
     ```
   - For specific device:
     ```bash
     flutter run -d <device_id>
     ```
   - For web:
     ```bash
     flutter run -d chrome
     ```
   - For iOS (macOS only):
     ```bash
     flutter run -d ios
     ```

## Dependencies

- `file_picker`: For selecting files from device
- `url_launcher`: For opening URLs in browsers
- `http`: For making HTTP requests to the backend API
- `crypto`: For encryption and hashing operations
- `shared_preferences`: For local data storage (user sessions)
- `share_plus`: For sharing content with other apps
- `pdfx`: For viewing PDF documents

## How to Use

### Registration

1. Launch the app and navigate to the registration screen
2. Enter your username, email, and password
3. Tap "Register" to create your account

### Login

1. Enter your email and password
2. Tap "Login" to access your account
3. Your session is saved automatically

### Browsing Books

1. Go to the Library screen
2. View all books or use the search feature
3. Tap on any book to see detailed information
4. Share books with others using the share button

### Managing Patents

1. Navigate to the Patents screen
2. Browse existing patents or add new ones
3. View patent details, inventors, and descriptions

### Creating Contributions

1. Go to "My Contributions" screen
2. Add new books, patents, or update scholar information
3. Fill out the form and submit
4. Your contributions appear in the library

## Building for Release

### Android

```bash
flutter build apk
# or for app bundle (recommended for Google Play)
flutter build appbundle
```

### iOS

```bash
flutter build ios
# Then open in Xcode to sign and upload to App Store
```

### Web

```bash
flutter build web
# Output is in build/web/
```

### Windows/macOS

```bash
flutter build windows
flutter build macos
```

## Troubleshooting

**Issue**: `Flutter packages get` fails

- Try: `flutter clean && flutter pub get`

**Issue**: App won't run on Android emulator

- Check: `flutter doctor` to ensure Android SDK is properly installed
- Try: Restart the emulator and run `flutter clean` before running again

**Issue**: Getting permission errors on iOS

- Make sure you have Xcode command line tools installed
- Try: `sudo xcode-select --switch /Applications/Xcode.app/select`

**Issue**: PDF files not displaying

- Ensure the file path is correct and the file exists
- Check that the `pdfx` package is properly installed

## Contributing

1. Create a new branch for your feature

   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Make your changes and test them

3. Commit your changes

   ```bash
   git add .
   git commit -m "Add your feature description"
   ```

4. Push to your branch

   ```bash
   git push origin feature/your-feature-name
   ```

5. Create a Pull Request on GitHub

## Backend API

This app communicates with a backend API. Make sure the backend server is running and accessible. Update the API endpoints in your services as needed.

The backend code is located in the `bpp_backend` repository.

## Code Style

- Follow Flutter and Dart conventions
- Use meaningful variable and function names
- Add comments for complex logic
- Keep widgets focused on single responsibility

## Future Improvements

- [ ] Add offline support with local database
- [ ] Implement advanced search filters
- [ ] Add user ratings and reviews
- [ ] Implement push notifications
- [ ] Add export to different file formats
- [ ] Create user communities and groups

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contact & Support

For questions or issues, please contact the development team or open an issue on GitHub.

---

**Last Updated**: June 2026
**App Version**: 1.0.0
