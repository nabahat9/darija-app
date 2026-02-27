import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'theme/app_colors.dart';
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

  // Fetch next phrase from backend
  Future<void> fetchNextPhrase() async {
    setState(() {
      phraseAr = null;
      phraseEn = null;
      recordedFilePath = null;
      phraseId = null;
    });

    try {
      final url = Uri.parse(
          'https://darija-backend-vtrh.onrender.com/api/next-phrase?user_id=${widget.userId}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['message'] != null) {
          setState(() {
            phraseAr = "No more phrases to record";
            phraseEn = "";
          });
        } else {
          setState(() {
            phraseAr = data['phrase_ar'] ?? '';
            phraseEn = data['phrase_en'] ?? '';
            phraseId = data['id'];
          });
        }
      } else {
        print('Failed to fetch phrase: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching phrase: $e');
    }
  }

  // Start recording
  Future<void> startRecording() async {
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Microphone permission denied')));
      return;
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      final path =
          '${dir.path}/${widget.name}_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(
        path: path,
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        samplingRate: 44100,
      );

      setState(() {
        isRecording = true;
        recordedFilePath = path;
      });
    } catch (e) {
      print('Error starting recording: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // Stop recording
  Future<void> stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        isRecording = false;
        if (path != null) recordedFilePath = path;
      });
    } catch (e) {
      print('Error stopping recording: $e');
      setState(() => isRecording = false);
    }
  }

  // Play recorded audio
  Future<void> playRecording() async {
    if (recordedFilePath == null || !File(recordedFilePath!).existsSync())
      return;

    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(DeviceFileSource(recordedFilePath!));
    } catch (e) {
      print('Error playing recording: $e');
    }
  }

  // Upload recording to backend
  // Upload recording to backend

  Future<void> uploadRecording() async {
    if (recordedFilePath == null || phraseId == null) return;

    setState(() {
      isUploading = true;
    });

    try {
      final uri = Uri.parse(
        'https://darija-backend-vtrh.onrender.com/api/recording',
      );

      // Create multipart request
      var request = http.MultipartRequest('POST', uri);

      // Add form fields
      request.fields['phrase_id'] = phraseId.toString();
      request.fields['user_id'] = widget.userId.toString();

      // Make sure file exists
      final file = File(recordedFilePath!);
      if (!file.existsSync()) {
        throw Exception("Recorded file does not exist");
      }

      // Add file
      request.files.add(
        await http.MultipartFile.fromPath(
          'audio', // MUST match backend: req.files.audio
          file.path,
          contentType: MediaType('audio', 'm4a'), // correct MIME type
        ),
      );

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Recording uploaded successfully!')),
        );
        await fetchNextPhrase();
      } else {
        print('Upload failed: ${response.statusCode}');
        print('Response body: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload recording')),
        );
      }
    } catch (e) {
      print('Error uploading recording: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading recording: $e')),
      );
    } finally {
      setState(() {
        isUploading = false;
      });
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Hi, ${widget.name}!',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Please record the Darija phrase written in Arabic letters',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 30),
                if (phraseAr == null || phraseEn == null)
                  const CircularProgressIndicator()
                else
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          phraseAr!,
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          phraseEn!,
                          style:
                              const TextStyle(fontSize: 18, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 30),
                GestureDetector(
                  onTap: isRecording ? stopRecording : startRecording,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color:
                          isRecording ? Colors.transparent : AppColors.primary,
                      border: Border.all(
                        color: isRecording ? Colors.red : Colors.transparent,
                        width: 4,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        isRecording ? 'Stop' : 'Start',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isRecording ? Colors.red : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (isRecording)
                  const Text(
                    'Recording in progress...',
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
                if (!isRecording && recordedFilePath != null) ...[
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: playRecording,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Play Recording'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: isUploading ? null : uploadRecording,
                    icon: const Icon(Icons.upload_file),
                    label:
                        Text(isUploading ? 'Uploading...' : 'Upload Recording'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: fetchNextPhrase,
                  child: const Text('Next Phrase'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 30),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
