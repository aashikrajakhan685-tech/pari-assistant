import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';

void main() {
  runApp(const PariApp());
}

class PariApp extends StatefulWidget {
  const PariApp({super.key});

  @override
  State<PariApp> createState() => _PariAppState();
}

class _PariAppState extends State<PariApp> {
  Color primaryGlow = const Color(0xFF00F2FE);

  void changeGlowColor(Color color) {
    setState(() {
      primaryGlow = color;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pari Voice AI',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B0E14),
      ),
      home: PariHomeScreen(
        primaryGlow: primaryGlow,
        onColorChanged: changeGlowColor,
      ),
    );
  }
}

class PariHomeScreen extends StatefulWidget {
  final Color primaryGlow;
  final Function(Color) onColorChanged;

  const PariHomeScreen({
    super.key,
    required this.primaryGlow,
    required this.onColorChanged,
  });

  @override
  State<PariHomeScreen> createState() => _PariHomeScreenState();
}

class _PariHomeScreenState extends State<PariHomeScreen>
    with SingleTickerProviderStateMixin {
  // ==========================================
  // IMPORTANT: APNI GOOGLE AI STUDIO API KEY YAHAN DAALEN
  // ==========================================
  final String apiKey = "AQ.Ab8RN6K7F1eCa_lrpxynLSTDmPYw8rWc8uOW5XridBZCRfeXZg"

  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;

  bool _isListening = false;
  bool _isThinking = false;
  String _userText = "Tap the microphone to speak with Pari...";
  String _pariResponse = "Hello! I am Pari. How can I help you today?";

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _initTts();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  void _initTts() async {
    await _flutterTts.setLanguage("hi-IN");
    await _flutterTts.setPitch(1.1);
    await _flutterTts.setSpeechRate(0.45);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (val) => setState(() => _isListening = false),
      );

      if (available) {
        setState(() {
          _isListening = true;
          _userText = "Listening...";
        });

        _speech.listen(
          onResult: (val) {
            setState(() {
              _userText = val.recognizedWords;
            });
            if (val.finalResult && _userText.isNotEmpty) {
              _getAIResponse(_userText);
            }
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _getAIResponse(String prompt) async {
    setState(() {
      _isThinking = true;
      _pariResponse = "Pari is thinking...";
    });

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
    );

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text":
                      "Your name is Pari, an intelligent and friendly AI assistant. Answer the user clearly in Hindi, Maithili, or simple English as requested. Keep the answers concise and helpful. User query: $prompt"
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiText = data['candidates'][0]['content']['parts'][0]['text'];

        setState(() {
          _pariResponse = aiText;
          _isThinking = false;
        });

        _speak(aiText);
      } else {
        setState(() {
          _pariResponse = "Error connecting to AI server. Please check your API key.";
          _isThinking = false;
        });
      }
    } catch (e) {
      setState(() {
        _pariResponse = "Something went wrong. Please check your network.";
        _isThinking = false;
      });
    }
  }

  Future<void> _speak(String text) async {
    await _flutterTts.stop();
    await _flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header (MIUI Customization Bar)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "PARI AI",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.palette_outlined, color: Colors.white),
                        onPressed: () {
                          _showThemeDialog(context);
                        },
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Center Glowing Orb (Real-time Visualizer)
                GestureDetector(
                  onTap: _listen,
                  child: AnimatedBuilder(
                    animation: _animController,
                    builder: (context, child) {
                      double scale = _isListening
                          ? 1.0 + (_animController.value * 0.25)
                          : 1.0;
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.primaryGlow.withOpacity(0.2),
                            boxShadow: [
                              BoxShadow(
                                color: widget.primaryGlow.withOpacity(_isListening ? 0.8 : 0.4),
                                blurRadius: _isListening ? 45 : 25,
                                spreadRadius: _isListening ? 15 : 5,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              _isListening ? Icons.mic : Icons.mic_none,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  _isListening
                      ? "Listening to you..."
                      : _isThinking
                          ? "Pari is thinking..."
                          : "Tap orb to speak",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    letterSpacing: 1.1,
                  ),
                ),

                const Spacer(),

                // Glassmorphism Response Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: widget.primaryGlow.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "YOU: $_userText",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const Divider(color: Colors.white24, height: 20),
                            Text(
                              _pariResponse,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2640),
        title: const Text("Choose Accent Glow", style: TextStyle(color: Colors.white)),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _colorOption(const Color(0xFF00F2FE)),
            _colorOption(const Color(0xFF9D50BB)),
            _colorOption(const Color(0xFF11998E)),
            _colorOption(const Color(0xFFFF512F)),
          ],
        ),
      ),
    );
  }

  Widget _colorOption(Color color) {
    return GestureDetector(
      onTap: () {
        widget.onColorChanged(color);
        Navigator.pop(context);
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
