# How to Run the Emergency Communication System 🚀

## Prerequisites

Before running this project, ensure you have:

1. **Flutter SDK** installed (3.10 or higher)
   - Check: `flutter --version`
   - Install from: https://flutter.dev/docs/get-started/install

2. **Git** (to clone the project)

3. **A device to run on:**
   - Chrome browser (for web/testing UI)
   - Android device with USB debugging
   - Android emulator
   - Or Windows desktop

---

## Step-by-Step Instructions

### **Step 1: Clone/Download the Project**

```bash
cd Emergency-Communication-
```

---

### **Step 2: Install Dependencies**

⚠️ **IMPORTANT:** You MUST run this command first!

```bash
flutter pub get
```

**What this does:**
- Downloads all packages listed in `pubspec.yaml`
- Installs dependencies
- Sets up the project

**When to run it:**
- First time setting up the project
- After pulling new changes
- After modifying `pubspec.yaml`

---

### **Step 3: Check Available Devices**

```bash
flutter devices
```

**You'll see something like:**
```
Windows (desktop) • windows • windows-x64
Chrome (web)      • chrome  • web-javascript
Edge (web)        • edge    • web-javascript
Android Device    • ABC123  • android-arm64  (if phone connected)
```

---

### **Step 4: Run the App**

#### **Option A: Run in Chrome (Recommended for Testing UI)** 🌐

```bash
flutter run -d chrome
```

**Features:**
- ✅ Hot reload works (`r` key)
- ✅ Fast startup
- ✅ All UI visible
- ⚠️ Bluetooth/WiFi won't work (hardware not available)

---

#### **Option B: Run on Android Device** 📱 (Best for Full Features)

1. **Enable USB Debugging on your Android phone:**
   - Settings → About Phone → Tap "Build Number" 7 times
   - Settings → Developer Options → Enable "USB Debugging"

2. **Connect phone via USB**

3. **Run:**
```bash
flutter run
```
or
```bash
flutter run -d <device-id>
```

**Features:**
- ✅ Hot reload works
- ✅ Bluetooth functional (when implemented)
- ✅ WiFi Direct functional (when implemented)
- ✅ GPS functional

---

#### **Option C: Run on Windows Desktop** 💻

```bash
flutter run -d windows
```

---

#### **Option D: Run on All Devices** 🔄

```bash
flutter run -d all
```

---

## Hot Reload Commands

Once the app is running, you can use these commands **in the terminal**:

| Key | Action |
|-----|--------|
| `r` | **Hot Reload** - Apply code changes instantly (keeps state) |
| `R` | **Hot Restart** - Full restart (clears state) |
| `h` | Help - Show all commands |
| `q` | Quit - Stop the app |
| `s` | Take screenshot |
| `w` | Dump widget hierarchy |

---

## Common Commands

### **Install/Update Dependencies**
```bash
flutter pub get
```

### **Update Dependencies to Latest**
```bash
flutter pub upgrade
```

### **Check for Outdated Packages**
```bash
flutter pub outdated
```

### **Clean Build Cache** (if having issues)
```bash
flutter clean
flutter pub get
```

### **Run with Verbose Logging**
```bash
flutter run -v
```

### **Build for Release** (when ready)
```bash
flutter build apk          # Android APK
flutter build appbundle    # Android App Bundle
flutter build web          # Web version
flutter build windows      # Windows executable
```

---

## Project Structure

```
Emergency-Communication-/
├── lib/
│   ├── main.dart                 ← App entry point
│   ├── screens/                  ← All UI screens
│   ├── widgets/                  ← Reusable components
│   ├── models/                   ← Data models
│   ├── database/                 ← SQLite setup
│   ├── services/                 ← Business logic (coming in Week 4+)
│   └── utils/                    ← Constants, helpers
├── pubspec.yaml                  ← Dependencies
└── README.md
```

---

## Testing the Current Build (Week 3)

### **What Works Now:**
✅ Complete UI (7 screens)
✅ Navigation between screens
✅ Animations and transitions
✅ Hot reload

### **What Doesn't Work Yet:**
❌ Actual Bluetooth communication (Week 5-6)
❌ WiFi Direct mesh networking (Week 6)
❌ Database storage (Week 4-5)
❌ Real GPS tracking (Week 7)
❌ Message encryption (Week 8)

---

## Workflow Example

```bash
# 1. First time setup
cd Emergency-Communication-
flutter pub get

# 2. Run in Chrome for UI testing
flutter run -d chrome

# 3. Make changes to code in your editor

# 4. Press 'r' in terminal to hot reload

# 5. See changes instantly in browser!
```

---

## Troubleshooting

### **Error: "Could not find a file named pubspec.yaml"**
**Solution:** Make sure you're in the project root directory
```bash
cd Emergency-Communication-
```

### **Error: "No devices found"**
**Solution:** 
- For Chrome: Make sure Chrome is installed
- For Android: Enable USB debugging and connect device
- Run: `flutter doctor` to check setup

### **Error: "Waiting for another flutter command to release the startup lock"**
**Solution:**
```bash
# Delete the lock file
rm -rf ~/.flutter_tool_state
# Or on Windows
del %USERPROFILE%\.flutter_tool_state
```

### **Hot reload not working?**
**Solution:**
- Press `R` for full hot restart
- Or restart the app: `q` then `flutter run` again

### **App not updating in browser?**
**Solution:**
- Hard refresh: `Ctrl + Shift + R` (Windows) or `Cmd + Shift + R` (Mac)

---

## Adding New Dependencies (Future Weeks)

When you need to add packages for Week 4+:

1. **Edit `pubspec.yaml`:**
```yaml
dependencies:
  flutter:
    sdk: flutter
  sqflite: ^2.3.0              # Add this
  path_provider: ^2.1.0        # Add this
  # ... more packages
```

2. **Install new packages:**
```bash
flutter pub get
```

3. **Hot restart the app:**
Press `R` in the terminal

---

## Development Tips

### **Fast Development Cycle:**
1. Keep `flutter run` running
2. Edit code in your IDE
3. Save file (Ctrl+S / Cmd+S)
4. Press `r` in terminal
5. See changes in < 1 second! ⚡

### **Best Practices:**
- ✅ Always run `flutter pub get` after cloning
- ✅ Use hot reload (`r`) for UI changes
- ✅ Use hot restart (`R`) for logic changes
- ✅ Test in Chrome for quick UI iterations
- ✅ Test on Android device for hardware features
- ✅ Run `flutter clean` if weird errors occur

---

## Quick Reference

| Command | Purpose |
|---------|---------|
| `flutter pub get` | Install dependencies (MUST RUN FIRST) |
| `flutter run -d chrome` | Run in Chrome browser |
| `flutter run` | Run on connected device |
| `flutter devices` | List available devices |
| `flutter clean` | Clean build cache |
| `flutter doctor` | Check Flutter setup |
| Press `r` | Hot reload (while running) |
| Press `R` | Hot restart (while running) |

---

## Current Project Status (After Week 3)

✅ **Week 1:** Research & requirements (documented)  
✅ **Week 2:** System design & architecture (complete)  
✅ **Week 3:** UI/UX design (7 screens, 4 widgets)  
⏳ **Week 4:** Environment setup (coming next)  
⏳ **Week 5-12:** Implementation, testing, deployment  

---

## Need Help?

1. **Flutter Issues:** Run `flutter doctor -v`
2. **App Crashes:** Check terminal for error messages
3. **UI Not Updating:** Try hot restart (`R`)
4. **Dependencies Issues:** Run `flutter clean && flutter pub get`

---

**Ready to Run?** 🚀

```bash
flutter pub get
flutter run -d chrome
```

Press `r` to hot reload after making changes!

---

**Note:** For full functionality (Bluetooth, WiFi Direct, GPS), you'll need an Android device. The UI works perfectly in Chrome for testing and development! 📱💻

