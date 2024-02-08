import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:video_player/video_player.dart';

import 'button.dart';

class VideoCompressed extends StatefulWidget {
  const VideoCompressed({Key? key}) : super(key: key);

  @override
  State<VideoCompressed> createState() => _VideoCompressedState();
}

class _VideoCompressedState extends State<VideoCompressed> {
  File? fileVideo;
  Uint8List? thumbnailBytes;
  int? videoSize;
  MediaInfo? compressedVideoInfo;
  late VideoPlayerController _videoController;
  bool isVideoPlaying = false;

  @override
  void initState() {
    super.initState();
    initializeFirebase();
    _videoController = VideoPlayerController.network('');
  }

  Future<void> initializeFirebase() async {
    await Firebase.initializeApp();
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  Future<void> pickVideo() async {
    final picker = ImagePicker();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Select Video"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text("Pick from Gallery"),
                onTap: () async {
                  Navigator.pop(context);
                  final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
                  if (pickedFile == null) return;
                  final file = File(pickedFile.path);
                  setState(() => fileVideo = file);
                  generateThumbnail(fileVideo!);
                  getVideoSize(fileVideo!);
                  await compressVideo();
                },
              ),
              ListTile(
                leading: Icon(Icons.videocam),
                title: Text("Record Video"),
                onTap: () async {
                  Navigator.pop(context);
                  final pickedFile = await picker.pickVideo(source: ImageSource.camera);
                  if (pickedFile == null) return;
                  final file = File(pickedFile.path);
                  setState(() => fileVideo = file);
                  generateThumbnail(fileVideo!);
                  getVideoSize(fileVideo!);
                  await compressVideo();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> generateThumbnail(File file) async {
    final thumbnailBytes = await VideoCompress.getByteThumbnail(file.path);
    setState(() => this.thumbnailBytes = thumbnailBytes);
  }

  Future<void> getVideoSize(File file) async {
    final size = await file.length();
    setState(() => videoSize = size);
  }

  Widget buildThumbnail() => thumbnailBytes == null
      ? const CircularProgressIndicator()
      : Image.memory(thumbnailBytes!, height: 100);

  Widget buildVideoInfo() {
    if (videoSize == null) return Container();
    final size = videoSize! / 1000;

    return Column(
      children: [
        Text('Original Video Info',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Text("SIZE: $size KB", style: TextStyle(fontSize: 20)),
      ],
    );
  }

  Future<void> compressVideo() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(child: ProgressDialogWidget()),
    );

    try {
      if (fileVideo != null) {
        final info = await VideoCompressApi.compressVideo(fileVideo!);
        setState(() => compressedVideoInfo = info);

        if (info != null && info.path != null) {
          await uploadToFirebase(File(info.path!));
        }
      }
    } finally {
      Navigator.of(context).pop(); // Close the progress dialog
    }
  }

  Future<void> uploadToFirebase(File file) async {
    try {
      final storage = firebase_storage.FirebaseStorage.instance;
      final storageRef = storage.ref().child('compressed_videos/${DateTime.now().millisecondsSinceEpoch}.mp4');

      // Check if the file exists before uploading
      if (!await file.exists()) {
        print('Error: File does not exist.');
        return;
      }

      // Upload the file
      await storageRef.putFile(file);

      // Get the download URL
      final downloadURL = await storageRef.getDownloadURL();

      print('Video uploaded to Firebase Storage: $downloadURL');
    } catch (e) {
      print('Error uploading video to Firebase Storage: $e');
      // Print additional details about the error
      if (e is firebase_storage.FirebaseException) {
        print('Firebase Storage error code: ${e.code}');
      }
    }
  }

  Widget buildVideoCompressInfo() {
    if (compressedVideoInfo == null) return Container();
    final size = compressedVideoInfo!.filesize! / 1000;

    return Column(
      children: [
        Text("Compressed Video Info",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Text("Size $size KB"),
        SizedBox(height: 8),
        Text("${compressedVideoInfo!.path}", textAlign: TextAlign.center),
      ],
    );
  }

  Future<void> playCompressedVideo() async {
    if (compressedVideoInfo != null && compressedVideoInfo!.path != null) {
      final videoURL = compressedVideoInfo!.path!;
      _videoController = VideoPlayerController.network(videoURL);
      await _videoController.initialize();
      await _videoController.play();
      setState(() {
        isVideoPlaying = true;
      });
    }
  }

  Widget buildCompressedVideoPlayer() {
    return isVideoPlaying
        ? Container(
      width: MediaQuery.of(context).size.width,
      height: 300.0, // Set the desired height
      child: VideoPlayer(_videoController),
    )
        : Container();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text(
          "Video Compressor",
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
              color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (fileVideo == null)
                ButtonWidget(text: "Select Video", onClicked: pickVideo)
              else
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: playCompressedVideo,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          buildThumbnail(),
                          buildCompressedVideoPlayer(),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                    buildVideoInfo(),
                    SizedBox(height: 24),
                    buildVideoCompressInfo(),
                    SizedBox(height: 24),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class VideoCompressApi {
  static Future<MediaInfo?> compressVideo(File file) async {
    try {
      MediaInfo? mediaInfo = await VideoCompress.compressVideo(file.path,
        quality: VideoQuality.DefaultQuality,
        deleteOrigin: false, // It's false by default
      );
      return mediaInfo;
    } catch (e) {
      VideoCompress.cancelCompression();
      return null;
    }
  }
}

class ProgressDialogWidget extends StatefulWidget {
  const ProgressDialogWidget({Key? key}) : super(key: key);

  @override
  State<ProgressDialogWidget> createState() => _ProgressDialogWidgetState();
}

class _ProgressDialogWidgetState extends State<ProgressDialogWidget> {
  late Subscription subscription;
  double? progress;

  @override
  void initState() {
    super.initState();

    subscription = VideoCompress.compressProgress$.subscribe(
            (progress) => setState(() => this.progress = progress));
  }

  @override
  void dispose() {
    VideoCompress.cancelCompression();
    subscription.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = progress == null ? progress : progress! / 100;

    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Compressing Video...', style: TextStyle(fontSize: 20)),
          SizedBox(height: 24),
          LinearProgressIndicator(value: value, minHeight: 12),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => VideoCompress.cancelCompression(),
            child: Text("Cancel"),
          )
        ],
      ),
    );
  }
}

