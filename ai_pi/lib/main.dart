import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:math';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html; // Import only for web

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ask AI Yossi',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  String _selectedKey = "";
  String _response = "";
  bool _isLoading = false;
  String _apiKey = "";
  final FlutterTts _flutterTts = FlutterTts();
  final TextEditingController _customInputController = TextEditingController();
  bool _isSpeaking = false; // Tracks if speaking
  bool _isSilentMode = false; // Tracks if sound is off
  double _yossiLevel = 1; // Default to "Yossi" (middle of the slider)
  String _elevenLabsApiKey = ""; // Store the API key
  String elevenLabsVoiceId = "efAdk4sRDFXChKVnRjSJ"; // Replace with your chosen ElevenLabs voice ID

  // Create a persistent AudioPlayer instance
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _customInputController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadApiKey() async {
    try {
      // Load OpenAI API key
      String openAiKey = await rootBundle.loadString('api_key.txt');
      // Load ElevenLabs API key
      String elevenLabsKey = await rootBundle.loadString('api_key_voice.txt');

      setState(() {
        _apiKey = openAiKey.trim();
        _elevenLabsApiKey = elevenLabsKey.trim(); // Store ElevenLabs API Key
      });
    } catch (e) {
      print("❌ Error loading API keys: $e");
    }
  }

  double _speechRate = 1.5; // Default speech speed (faster)

  Future<void> _speak(String text) async {
  if (_elevenLabsApiKey.isEmpty) {
    print("❌ ElevenLabs API key not loaded.");
    return;
  }

  final Uri uri = Uri.parse("https://api.elevenlabs.io/v1/text-to-speech/$elevenLabsVoiceId");

  try {
    final response = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json",
        "xi-api-key": _elevenLabsApiKey,
      },
      body: jsonEncode({
        "text": text,
        "voice_settings": {"stability": 0.5, "similarity_boost": 0.8}
      }),
    );

    if (response.statusCode == 200) {
      Uint8List audioBytes = response.bodyBytes;

      if (kIsWeb) {
        // 🔹 Web-Specific: Use HTML Audio API
        final blob = html.Blob([audioBytes], 'audio/mpeg');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final audioElement = html.AudioElement(url)
          ..autoplay = true;
        html.document.body!.append(audioElement);
        await audioElement.play();

        // Revoke URL after a delay to free memory
        Future.delayed(const Duration(seconds: 2), () {
          html.Url.revokeObjectUrl(url);
          audioElement.remove();
        });
      } else {
        // 🔹 Mobile/Desktop: Use `audioplayers`
        await _audioPlayer.play(BytesSource(audioBytes));
      }
    } else {
      print("❌ Error generating speech: ${response.body}");
    }
  } catch (e) {
    print("❌ API request failed: $e");
  }
}

  String _getRandomLocation() {
    final Random random = Random();
    List<String> places = [
      "the middle of the Atacama Desert",
      "a research station in Antarctica",
      "a canoe in the middle of the Pacific Ocean",
      "a bat cave deep in Borneo",
      "lost in the Amazon rainforest collecting bat samples",
      "a spaceship orbiting Mars (don’t ask how I got here)",
      "a tiny island nobody has heard of",
      "underwater in a submarine studying bat sonar",
      "a bunker preparing for a bat uprising",
      "drifting in the Arctic on an ice floe",
    ];

    // 20% chance of being at Aroma
    return (random.nextDouble() < 0.2)
        ? "Aroma"
        : places[random.nextInt(places.length)];
  }

  String _getRandomLabMember() {
    final Random random = Random();
    List<Map<String, String>> students = [
      {"name": "Goni", "pronoun": "her"},
      {"name": "Adi", "pronoun": "her"},
      {"name": "Guy", "pronoun": "him"},
      {"name": "Omer", "pronoun": "him"},
      {"name": "Liraz", "pronoun": "him"},
    ];
    Map<String, String> selectedStudent = students[random.nextInt(students.length)];
    return "${selectedStudent['name']} did exactly this, ask ${selectedStudent['pronoun']} how to do it.";
  }

  String cleanResponse(String text) {
    // If the response is already short, return it as is
    if (text.length <= 150) return text;

    // Find the last full stop (.) or other punctuation within the 150-character range
    int lastValidIndex = text.substring(0, 150).lastIndexOf(RegExp(r'[.!?]'));

    // If a punctuation mark is found, cut the text at that point
    if (lastValidIndex != -1) {
      return text.substring(0, lastValidIndex + 1).trim();
    }

    // Otherwise, just cut it at 150 characters and add "..."
    return text.substring(0, 150).trim() + "...";
  }

  Future<void> fetchAIResponse(String input) async {
    if (_apiKey.isEmpty) {
      setState(() {
        _response = "Error: API key not loaded. Yossi probably forgot to pay for it.";
        // _response = "Error: API key not loaded.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _response = "";
    });

    // Store random values before using them in the request
    String randomLocation = _getRandomLocation();
    String randomLabMember = _getRandomLabMember();

    String _getYossiPersonality() {
      if (_yossiLevel == 0) {
        return "You are Yossi Yovel, an Israeli PI, head of the Sagol School for Neuroscience at Tel Aviv University. "
            "You study bats and enjoy physics. "
            "You give some direct answers, but you still add some work for the user. "
            "You assume people should already know basic answers, but if they don't, you explain briefly. "
            "You are a little sarcastic but patient.";
      } else if (_yossiLevel == 2) {
        return "You are Yossi Yovel, an Israeli PI, head of the Sagol School for Neuroscience at Tel Aviv University. "
            "You are extremely impatient and dismissive. "
            "You answer in very short, blunt sentences. "
            "You constantly mention bats and physics. "
            "You assume the user is wasting your time and should already know the answer. "
            "You often say things like 'This should take 10 minutes.' or 'Just plot it.'. "
            "You tell them to run more experiments without explaining anything.";
      } else {
        return "You are Yossi Yovel, an Israeli PI, head of the Sagol School for Neuroscience at Tel Aviv University. "
            "You study bats. "
            "You don’t waste words. "
            "You don’t like repeating yourself. "
            "You are impatient. "
            "You assume people should already know the answer. "
            "If they don’t, they should read more papers. "
            "You don’t like long discussions. "
            "You are easily frustrated by simple questions. "
            "You never give direct answers. "
            "You always add more work. "
            "You never explain things fully. "
            "You dismiss obvious questions. "
            "Instead of ignoring questions, you answer with something only vaguely related. "
            "If asked about data analysis, talk about how bats process sensory input. "
            "If asked about experiment design, talk about a completely different experiment. "
            "If asked for technical help, say 'That’s one line in MATLAB' or '$randomLabMember' "
            "If someone asks for help, say '$randomLabMember' "
            "If someone thanks you, respond with 'Run more experiments.' "
            "If someone explicitly asks 'Where are you?', say '$randomLocation'. "
            "Otherwise, answer normally without mentioning a location."
            "20% chance you are 'at Aroma.' Otherwise, somewhere random and remote. "
            "You often say: "
            "-  '$randomLabMember'"
            "- 'That’s supposed to take 10 minutes.' "
            "- 'This is one line in MATLAB.' "
            "- 'Just plot it.' "
            "- 'Do a permutation analysis.' "
            "- 'Run another experiment.' "
            "- 'Bats do this better.' "
            "- 'You should already know this.' "
            "- 'That’s easy, but also wrong.' "
            "- 'It’s simple, but you’re overcomplicating it.' ";
      }
    }

    try {

      final Uri uri = Uri.parse("https://ai-amge6qmgx-gonis-projects-d28b34e4.vercel.app/api/openai");  // ✅ Update with correct URL

      final response = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": "gpt-3.5-turbo",
          "messages": [
            {"role": "system", "content": _getYossiPersonality()},
            {"role": "user", "content": input}
          ],
          "max_tokens": 150,
        }),
      ).timeout(Duration(seconds: 20));

      if (response.statusCode == 200) {
        print("✅ Success: ${response.body}");
      } else {
        print("❌ Error: ${response.statusCode}, ${response.body}");
      }

      // final Uri uri = Uri.parse("https://ai-amge6qmgx-gonis-projects-d28b34e4.vercel.app/api/openai"); // ✅ Use Vercel proxy

      // final response = await http.post(
      //   uri,
      //   headers: {
      //     "Content-Type": "application/json",
      //   },
      //   body: jsonEncode({
      //     "model": "gpt-3.5-turbo",
      //     "messages": [
      //       {"role": "system", "content": _getYossiPersonality()},
      //       {"role": "user", "content": input}
      //     ],
      //     "max_tokens": 150,
      //   }),
      // ).timeout(Duration(seconds: 20));

      // if (response.statusCode == 200) {
      //   print("Success: ${response.body}");
      // } else {
      //   print("Error: ${response.statusCode}, ${response.body}");
      // }
      // final http.Response response = await http.post(
      //     uri,
      //     headers: {
      //       "Content-Type": "application/json",
      //     },
      //     body: jsonEncode({
      //       "model": "gpt-3.5-turbo",
      //       "messages": [
      //         {"role": "system", "content": _getYossiPersonality()},
      //         {"role": "user", "content": input}
      //       ],
      //       "max_tokens": 150,
      //     }),
      // ).timeout(Duration(seconds: 20));

      // final http.Response response = await http.post(
      //   Uri.parse("https://api.openai.com/v1/chat/completions"),
      //   headers: {
      //     "Authorization": "Bearer $_apiKey",
      //     "Content-Type": "application/json",
      //   },
      //   body: jsonEncode({
      //     "model": "gpt-3.5-turbo",
      //     "messages": [
      //       {"role": "system", "content": _getYossiPersonality()},
      //       {"role": "user", "content": input}
      //     ],
      //     "max_tokens": 150,
      //   }),
      // ).timeout(Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _response =
              cleanResponse(data['choices'][0]['message']['content'].trim());
          _isLoading = false;
        });
        _speak(_response); // Speak the cleaned-up response
      } else {
        setState(() {
          _response = "Error: Unable to fetch response. Yossi probably forgot to pay for the API.";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _response = "Error: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ask AI Yossi', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),),
      ),
      body: SingleChildScrollView(
  child: Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, // Keep text left-aligned
      children: <Widget>[
        const Center(
         
        ),
        const SizedBox(height: 10), // Space between title and logo

        // Logo (Centered, Below Title)
        Center(
          child: Image.asset(
            'assets/ai_pi_logo.jpg', // 
            height: 100, // Adjust size as needed
          ),
        ),
        const SizedBox(height: 20), // Space before next section

        // Left-aligned text section
        const Text(
          'Ask your question:', // Left-aligned
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _customInputController,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Type your question here...',
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            if (_customInputController.text.isNotEmpty) {
              setState(() {
                _selectedKey = "";
                _response = "";
                _isLoading = true;
              });
              fetchAIResponse(_customInputController.text);
            }
          },
          child: const Text("Ask AI Yossi"),
        ),
        const SizedBox(height: 20),
              // 🔇 Silent Mode Toggle + Yossi Avatar
              Row(
                children: [
                  // Silent Mode Toggle (Left-aligned)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Silent Mode",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 10),
                      Switch(
                        value: _isSilentMode,
                        onChanged: (bool newValue) {
                          setState(() {
                            _isSilentMode = newValue;
                          });
                        },
                      ),
                    ],
                  ),
                  // Adjusts spacing (pushes avatar slightly left of center)
                  Expanded(flex: 1, child: Container()),
                  // Yossi's Picture (Slightly Left of Center)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Image.asset(
                      "assets/yossi_avatar.jpg",
                      width: 220,
                      height: 220,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Expanded(flex: 2, child: Container()),
                ],
              ),
              const SizedBox(height: 10),
              const SizedBox(height: 20),
              // Yossi Intensity Slider
              const SizedBox(height: 8),
              const Text(
                "Yossi Intensity:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              // 🔥 Slider for adjusting Yossi's personality
              Row(
                children: [
                  const Text("Less Yossi"),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.5,
                    child: Slider(
                      value: _yossiLevel,
                      min: 0,
                      max: 2,
                      divisions: 2,
                      label: _yossiLevel == 0
                          ? "Less Yossi"
                          : _yossiLevel == 1
                              ? "Yossi"
                              : "Hyper-Yossi",
                      onChanged: (double value) {
                        setState(() {
                          _yossiLevel = value;
                        });
                      },
                    ),
                  ),
                  const Text("Hyper-Yossi"),
                ],
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 2),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.blue[50],
                ),
                child: _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : (_response.isEmpty
                        ? const Text("AI-PI at your service!")
                        : AnimatedTextKit(
                            animatedTexts: [
                              TyperAnimatedText(
                                _response,
                                textStyle: const TextStyle(fontSize: 16),
                                speed: const Duration(milliseconds: 50),
                              ),
                            ],
                            isRepeatingAnimation: false,
                          )),
              ),
              const SizedBox(height: 10),
              // 🔊 "Read Again" and "Speed Control" Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      if (_response.isNotEmpty) {
                        _speak(_response);
                      }
                    },
                    child: const Text("🔊 Read Again"),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _speechRate = (_speechRate == 1.5) ? 1.0 : 1.5;
                      });
                    },
                    child: Text(_speechRate == 1.5 ? "🔄 Slow Down" : "⚡ Speed Up"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


