import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:http_parser/http_parser.dart';

class RecordScreen extends StatefulWidget {
  final String name;
  final String age;
  final String gender;
  final int userId;

  const RecordScreen({
    Key? key,
    required this.name,
    required this.age,
    required this.gender,
    required this.userId,
  }) : super(key: key);

  @override
  _RecordScreenState createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  // Define your custom blue color here for easy access
  final Color primaryNavy = const Color.fromARGB(255, 51, 73, 112);
  
  final Record _audioRecorder = Record();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool isRecording = false;
  bool isUploading = false;
  String? recordedFilePath;

  int? phraseId;
  String? phraseAr;
  String? phraseEn;

  @override
  void initState() {
    super.initState();
    fetchNextPhrase();
  }

  // --- Backend Logic ---
  Future<void> fetchNextPhrase() async {
    setState(() {
      phraseAr = null;
      phraseEn = null;
      recordedFilePath = null;
      phraseId = null;
    });

    try {
      final url = Uri.parse('https://darija-backend-vtrh.onrender.com/api/next-phrase?user_id=${widget.userId}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['message'] != null) {
          setState(() {
            phraseAr = "Makanach klam kher (No more phrases)";
            phraseEn = "";
          });
        } else {
          setState(() {
            phraseAr = data['phrase_ar'] ?? '';
            phraseEn = data['phrase_en'] ?? '';
            phraseId = data['id'];
          });
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  // --- Recording Logic ---
  Future<void> startRecording() async {
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) return;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/${widget.name}_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(
        path: path,
        encoder: AudioEncoder.aacLc,
      );

      setState(() {
        isRecording = true;
        recordedFilePath = path;
      });
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> stopRecording() async {
    final path = await _audioRecorder.stop();
    setState(() {
      isRecording = false;
      if (path != null) recordedFilePath = path;
    });
  }

  Future<void> playRecording() async {
    if (recordedFilePath == null) return;
    await _audioPlayer.stop();
    await _audioPlayer.play(DeviceFileSource(recordedFilePath!));
  }

  Future<void> uploadRecording() async {
    if (recordedFilePath == null || phraseId == null) return;
    setState(() => isUploading = true);

    try {
      var request = http.MultipartRequest('POST', Uri.parse('https://darija-backend-vtrh.onrender.com/api/recording'));
      request.fields['phrase_id'] = phraseId.toString();
      request.fields['user_id'] = widget.userId.toString();
      request.files.add(await http.MultipartFile.fromPath('audio', recordedFilePath!, contentType: MediaType('audio', 'm4a')));

      final response = await request.send();
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yaetik saha! Recording Sent.')));
        await fetchNextPhrase();
      }
    } finally {
      setState(() => isUploading = false);
    }
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9), // Soft background to make the navy pop
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text("Algerian Darija AI", style: TextStyle(color: primaryNavy, fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              // User Greeting
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Sahit, ${widget.name}!', 
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryNavy)),
              ),
              const SizedBox(height: 30),

              // Phrase Card
              _buildPhraseCard(),

              const Spacer(),

              // Recording Area
              _buildRecorderSection(),

              const SizedBox(height: 20),

              // Dynamic Action Area (Upload/Play or Skip)
              if (recordedFilePath != null && !isRecording) 
                _buildReviewActions() 
              else 
                _buildSkipButton(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhraseCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: primaryNavy.withOpacity(0.08), blurRadius: 30, offset: const Offset(0, 10)),
        ],
      ),
      child: phraseAr == null 
        ? Center(child: CircularProgressIndicator(color: primaryNavy))
        : Column(
            children: [
              Text("ALGERIAN ARABIC", style: TextStyle(letterSpacing: 1.5, fontSize: 11, fontWeight: FontWeight.bold, color: primaryNavy.withOpacity(0.5))),
              const SizedBox(height: 16),
              Text(
                phraseAr!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, height: 1.3),
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider()),
              Text(
                phraseEn!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey[500], fontStyle: FontStyle.italic),
              ),
            ],
          ),
    );
  }

  Widget _buildRecorderSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: isRecording ? stopRecording : startRecording,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer pulse ring
              if (isRecording)
                TweenAnimationBuilder(
                  tween: Tween(begin: 0.8, end: 1.2),
                  duration: const Duration(milliseconds: 600),
                  builder: (context, double value, child) {
                    return Container(
                      width: 100 * value,
                      height: 100 * value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red.withOpacity(0.2),
                      ),
                    );
                  },
                ),
              // Main Button
              Container(
                height: 90,
                width: 90,
                decoration: BoxDecoration(
                  color: isRecording ? Colors.red : primaryNavy,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isRecording ? Colors.red : primaryNavy).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Icon(isRecording ? Icons.stop_rounded : Icons.mic_rounded, color: Colors.white, size: 40),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          isRecording ? "Sajel f klemek..." : "Abbes bech tsajel",
          style: TextStyle(color: isRecording ? Colors.red : primaryNavy.withOpacity(0.6), fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildReviewActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: playRecording,
            icon: Icon(Icons.play_arrow_rounded, color: primaryNavy),
            label: Text("Listen", style: TextStyle(color: primaryNavy)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: primaryNavy.withOpacity(0.3)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isUploading ? null : uploadRecording,
            icon: isUploading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.send_rounded, color: Colors.white),
            label: const Text("Send", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryNavy,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkipButton() {
    return TextButton(
      onPressed: fetchNextPhrase,
      child: Text("Skip this phrase", style: TextStyle(color: Colors.grey[400])),
    );
  }
}