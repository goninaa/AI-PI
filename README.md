# 🚀 AI-PI Web App

### A Flutter web application that interacts with OpenAI.
🚨 This project was created as a lighthearted experiment for prof. Yossi Yovel's bat lab! 🦇😂

&#x20;

---

## 📌 **Features**

- 🎤 **AI-Powered Speech** - Uses ElevenLabs for text-to-speech conversion.
- 🤖 **Chat with AI-PI (GPT-3.5 Turbo)** - Interacts with OpenAI securely.
- 🎭 **Adjustable Personality** - Tune AI behavior using a **Yossi Intensity Slider**.
- 🔊 **Audio Feedback** - Plays generated responses via `flutter_tts`.
- 🌍 **Web & Mobile Support** - Works across devices.
- 🔐 **Secure API Calls** - Uses **backend proxy** to keep API keys **safe**.

---

## 🛠 **Project Setup**

### **1️⃣ Clone the Repository**

```bash
git clone https://github.com/your-username/your-repo-name.git
cd your-repo-name
```

### **2️⃣ Install Dependencies**

```bash
flutter pub get
```

### **3️⃣ Create a ****\`\`**** File (For Local Development)**

1. Create a new `.env` file inside the root directory.
2. Add your API keys (**DO NOT** commit this file!):

```env
OPENAI_API_KEY=sk-xxxxxxx
ELEVENLABS_API_KEY=your-elevenlabs-key
```

3. Load environment variables in `main.dart`:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}
```

---

## 🚀 **Running the Flutter Web App**

```bash
flutter run -d chrome
```

For mobile testing:

```bash
flutter run
```

---

## 🛡 **Security Considerations**

⚠ **DO NOT** expose API keys in Flutter code. ✅ Always use **backend proxy or environment variables** to manage keys. ✅ \*\*Ignore \*\*`** in **` to prevent accidental commits.

---

## 📜 **License**

This project is licensed under **MIT License**.

---

### **🚀 Enjoy Using AI-PI!**

Got questions? Reach out via GitHub Issues! 🚀

