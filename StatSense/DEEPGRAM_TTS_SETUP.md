# Deepgram TTS Integration Setup Guide

## ✅ What's Been Done

The StatSense app has been upgraded to use **Deepgram's Aura-2 Text-to-Speech** API, replacing the native AVSpeechSynthesizer for more natural-sounding speech.

### Files Created/Modified:

1. **DeepgramTTSService.swift** (NEW)
   - Complete Deepgram TTS integration
   - Async/await API with queue management
   - Multiple voice models support
   - Adjustable speech speed

2. **AccessibilityManager.swift** (MODIFIED)
   - Replaced AVSpeechSynthesizer with DeepgramTTSService
   - Maps user speech preferences to Deepgram models
   - Maintains all existing functionality

3. **Config.xcconfig** (MODIFIED)
   - Added `DEEPGRAM_TTS_API_KEY` configuration

---

## 🔑 Setup Instructions

### Step 1: Get Your Deepgram API Key

1. Go to [console.deepgram.com](https://console.deepgram.com/)
2. Sign up or log in
3. Navigate to **API Keys**
4. Create a new API key
5. Copy the key (starts with something like `xxx...`)

### Step 2: Add API Key to Config.xcconfig

Open `Config.xcconfig` and replace:
```
DEEPGRAM_TTS_API_KEY = YOUR_DEEPGRAM_TTS_KEY_HERE
```

With your actual key:
```
DEEPGRAM_TTS_API_KEY = your_actual_key_here
```

### Step 3: Add Key to Info.plist

You need to add the API key to your Info.plist file:

#### Option A: Using Xcode GUI
1. Open your `Info.plist` file
2. Click the `+` button to add a new row
3. Set Key: `DeepgramTTSAPIKey`
4. Set Type: `String`
5. Set Value: `$(DEEPGRAM_TTS_API_KEY)`

This will automatically pull the key from your Config.xcconfig file.

#### Option B: Edit as Source Code
1. Right-click `Info.plist` → "Open As" → "Source Code"
2. Add inside the `<dict>` tag:
```xml
<key>DeepgramTTSAPIKey</key>
<string>$(DEEPGRAM_TTS_API_KEY)</string>
```

### Step 4: Link Config.xcconfig to Your Target

1. Select your project in the Project Navigator
2. Select your **StatSense** target
3. Go to the **Info** tab
4. Look for **Configurations** section
5. For both **Debug** and **Release**, select `Config.xcconfig`

### Step 5: Clean and Rebuild

1. Press `Cmd + Shift + K` (Clean Build Folder)
2. Press `Cmd + B` (Build)
3. Run the app!

---

## 🎙️ Available Voice Models

The integration supports multiple Deepgram Aura-2 voices:

| Voice Model | Description | Use Case |
|-------------|-------------|----------|
| `aura-2-asteria-en` | American English, Female | Default, clear and professional |
| `aura-2-luna-en` | British English, Female | Alternative accent |
| `aura-2-stella-en` | Australian English, Female | Another accent option |
| `aura-2-athena-en` | American English, Female | Warmer tone |
| `aura-2-hera-en` | American English, Female | Authoritative tone |
| `aura-2-orion-en` | American English, Male | Male voice option |
| `aura-2-arcas-en` | American English, Male | Deeper male voice |
| `aura-2-perseus-en` | American English, Male | Younger male voice |
| `aura-2-angus-en` | Irish English, Male | Irish accent |
| `aura-2-orpheus-en` | American English, Male | Expressive male voice |
| `aura-2-helios-en` | British English, Male | British male voice |
| `aura-2-zeus-en` | American English, Male | Strong male voice |

### To Change the Default Voice:

Edit the `mapVoiceToDeepgramModel` function in `AccessibilityManager.swift`:

```swift
private func mapVoiceToDeepgramModel(_ voice: String) -> String {
    return "aura-2-orion-en" // Change this to any model above
}
```

---

## 🎛️ Features

### Speech Speed Control
- The app automatically maps your speech rate setting (0.0-1.0) to Deepgram's speed (0.7-1.5)
- Users can adjust speed in Settings

### Queue Management
- Multiple speech requests are queued automatically
- Priority speech interrupts current playback

### Error Handling
- Graceful fallback if API fails
- Helpful error messages in console

---

## 🧪 Testing

1. **Test Basic Speech:**
   - Run the app
   - Capture or load a graph
   - The analysis results should be spoken using Deepgram TTS

2. **Test Priority Speech:**
   - While speech is playing, trigger another analysis
   - New speech should interrupt (if priority is true)

3. **Test Speech Controls:**
   - Try pause/stop buttons during playback
   - Verify controls work correctly

---

## 🔧 Troubleshooting

### "Invalid API key" Error
- Check that `DeepgramTTSAPIKey` is in Info.plist
- Verify the key is correct in Config.xcconfig
- Make sure Config.xcconfig is linked to your target

### No Speech Plays
- Check console for error messages
- Verify audio permissions are granted
- Check device volume is up
- Test with headphones if simulator

### Unnatural Speech Still Plays
- Make sure you cleaned and rebuilt (Cmd+Shift+K, then Cmd+B)
- Check that `DeepgramTTSService` is actually being used (check console logs)

---

## 💰 Cost Considerations

Deepgram TTS charges per character:
- ~$0.015 per 1,000 characters for Aura-2 models
- A typical graph explanation is 200-500 characters
- Budget accordingly for production use

For development, you get free credits with a new account.

---

## 🚀 Production Best Practices

⚠️ **Never ship API keys in your binary!**

For production apps:
1. Create a backend server that issues short-lived tokens
2. Use environment variables only for development
3. Implement rate limiting
4. Monitor usage through Deepgram dashboard

---

## 📱 Additional Features You Can Add

### Custom Voice Selection UI
Add a settings option to let users choose their preferred voice:

```swift
// In SettingsView.swift
Picker("Voice", selection: $preferences.ttsVoice) {
    Text("Asteria (Female)").tag("aura-2-asteria-en")
    Text("Orion (Male)").tag("aura-2-orion-en")
    Text("Luna (British)").tag("aura-2-luna-en")
}
```

### Speed Control
Already implemented! Users can adjust via Settings → Speech Rate

### Audio Caching
For repeated phrases, cache the audio to save API calls and improve performance.

---

## ✨ Benefits Over Native TTS

1. **More Natural Sound**: Aura-2 models sound more human-like
2. **Consistent Quality**: Same voice across all iOS versions
3. **Better Prosody**: Natural pauses and intonation
4. **Multilingual**: Easy to add more languages
5. **Customizable**: More control over voice characteristics

---

## 📞 Support

- Deepgram Docs: https://developers.deepgram.com/docs/tts
- Deepgram Console: https://console.deepgram.com/
- StatSense Project: Check your project's README or documentation

---

**You're all set! Enjoy natural-sounding text-to-speech in StatSense! 🎉**
