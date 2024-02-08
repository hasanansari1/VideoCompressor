// import 'dart:io';
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:video_compress/video_compress.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
// import 'package:video_player/video_player.dart';
//
// import 'button.dart';
//
// class VideoCompressed extends StatefulWidget {
//   const VideoCompressed({Key? key}) : super(key: key);
//
//   @override
//   State<VideoCompressed> createState() => _VideoCompressedState();
// }
//
// class _VideoCompressedState extends State<VideoCompressed> {
//   File? fileVideo;
//   Uint8List? thumbnailBytes;
//   int? videoSize;
//   MediaInfo? compressedVideoInfo;
//   late VideoPlayerController _videoController;
//   bool isVideoPlaying = false;
//
//   @override
//   void initState() {
//     super.initState();
//     initializeFirebase();
//     _videoController = VideoPlayerController.network('');
//   }
//
//   Future<void> initializeFirebase() async {
//     await Firebase.initializeApp();
//   }
//
//   @override
//   void dispose() {
//     _videoController.dispose();
//     super.dispose();
//   }
//
//   Future<void> pickVideo() async {
//     final picker = ImagePicker();
//
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text("Select Video"),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               ListTile(
//                 leading: Icon(Icons.photo_library),
//                 title: Text("Pick from Gallery"),
//                 onTap: () async {
//                   Navigator.pop(context);
//                   final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
//                   if (pickedFile == null) return;
//                   final file = File(pickedFile.path);
//                   setState(() => fileVideo = file);
//                   generateThumbnail(fileVideo!);
//                   getVideoSize(fileVideo!);
//                   await compressVideo();
//                 },
//               ),
//               ListTile(
//                 leading: Icon(Icons.videocam),
//                 title: Text("Record Video"),
//                 onTap: () async {
//                   Navigator.pop(context);
//                   final pickedFile = await picker.pickVideo(source: ImageSource.camera);
//                   if (pickedFile == null) return;
//                   final file = File(pickedFile.path);
//                   setState(() => fileVideo = file);
//                   generateThumbnail(fileVideo!);
//                   getVideoSize(fileVideo!);
//                   await compressVideo();
//                 },
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   Future<void> generateThumbnail(File file) async {
//     final thumbnailBytes = await VideoCompress.getByteThumbnail(file.path);
//     setState(() => this.thumbnailBytes = thumbnailBytes);
//   }
//
//   Future<void> getVideoSize(File file) async {
//     final size = await file.length();
//     setState(() => videoSize = size);
//   }
//
//   Widget buildThumbnail() => thumbnailBytes == null
//       ? const CircularProgressIndicator()
//       : Image.memory(thumbnailBytes!, height: 100);
//
//   Widget buildVideoInfo() {
//     if (videoSize == null) return Container();
//     final size = videoSize! / 1000;
//
//     return Column(
//       children: [
//         Text('Original Video Info',
//             style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
//         SizedBox(height: 8),
//         Text("SIZE: $size KB", style: TextStyle(fontSize: 20)),
//       ],
//     );
//   }
//
//   Future<void> compressVideo() async {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => Dialog(child: ProgressDialogWidget()),
//     );
//
//     try {
//       if (fileVideo != null) {
//         final info = await VideoCompressApi.compressVideo(fileVideo!);
//         setState(() => compressedVideoInfo = info);
//
//         // if (info != null && info.path != null) {
//         //   await uploadToFirebase(File(info.path!));
//         // }
//       }
//     } finally {
//       Navigator.of(context).pop(); // Close the progress dialog
//     }
//   }
//
//   Future<void> uploadToFirebase(File file) async {
//     try {
//       final storage = firebase_storage.FirebaseStorage.instance;
//       final storageRef = storage.ref().child('compressed_videos/${DateTime.now().millisecondsSinceEpoch}.mp4');
//
//       // Check if the file exists before uploading
//       if (!await file.exists()) {
//         print('Error: File does not exist.');
//         return;
//       }
//
//       // Upload the file
//       await storageRef.putFile(file);
//
//       // Get the download URL
//       final downloadURL = await storageRef.getDownloadURL();
//
//       print('Video uploaded to Firebase Storage: $downloadURL');
//     } catch (e) {
//       print('Error uploading video to Firebase Storage: $e');
//       // Print additional details about the error
//       if (e is firebase_storage.FirebaseException) {
//         print('Firebase Storage error code: ${e.code}');
//       }
//     }
//   }
//
//   Widget buildVideoCompressInfo() {
//     if (compressedVideoInfo == null) return Container();
//     final size = compressedVideoInfo!.filesize! / 1000;
//
//     return Column(
//       children: [
//         Text("Compressed Video Info",
//             style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
//         SizedBox(height: 8),
//         Text("Size $size KB"),
//         SizedBox(height: 8),
//         Text("${compressedVideoInfo!.path}", textAlign: TextAlign.center),
//       ],
//     );
//   }
//
//   Future<void> playCompressedVideo() async {
//     if (compressedVideoInfo != null && compressedVideoInfo!.path != null) {
//       final videoURL = compressedVideoInfo!.path!;
//       _videoController = VideoPlayerController.network(videoURL);
//       await _videoController.initialize();
//       await _videoController.play();
//       setState(() {
//         isVideoPlaying = true;
//       });
//     }
//   }
//
//   Widget buildCompressedVideoPlayer() {
//     return isVideoPlaying
//         ? Container(
//       width: MediaQuery.of(context).size.width,
//       height: 300.0, // Set the desired height
//       child: VideoPlayer(_videoController),
//     )
//         : Container();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.green,
//         title: Text(
//           "Video Compressor",
//           style: TextStyle(
//               fontWeight: FontWeight.bold,
//               fontStyle: FontStyle.italic,
//               color: Colors.white),
//         ),
//       ),
//       body: SingleChildScrollView(
//         child: Center(
//           child: Padding(
//             padding: const EdgeInsets.only(top: 100),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//
//
//                 if (fileVideo == null)
//                   ButtonWidget(text: "Select Video", onClicked: pickVideo)
//                 else
//                   Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       GestureDetector(
//                         onTap: playCompressedVideo,
//                         child: Stack(
//                           alignment: Alignment.center,
//                           children: [
//                             buildThumbnail(),
//                             buildCompressedVideoPlayer(),
//                           ],
//                         ),
//                       ),
//                       SizedBox(height: 24),
//                       buildVideoInfo(),
//                       SizedBox(height: 24),
//                       buildVideoCompressInfo(),
//                       SizedBox(height: 24),
//
//
//
//                       ElevatedButton(onPressed: (){
//
//
//
//                       }, child: Text('Trim video'))
//
//
//                     ],
//                   ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class VideoCompressApi {
//   static Future<MediaInfo?> compressVideo(File file) async {
//     try {
//       MediaInfo? mediaInfo = await VideoCompress.compressVideo(file.path,
//         quality: VideoQuality.DefaultQuality,
//         deleteOrigin: false, // It's false by default
//       );
//       return mediaInfo;
//     } catch (e) {
//       VideoCompress.cancelCompression();
//       return null;
//     }
//   }
// }
//
// class ProgressDialogWidget extends StatefulWidget {
//   const ProgressDialogWidget({Key? key}) : super(key: key);
//
//   @override
//   State<ProgressDialogWidget> createState() => _ProgressDialogWidgetState();
// }
//
// class _ProgressDialogWidgetState extends State<ProgressDialogWidget> {
//   late Subscription subscription;
//   double? progress;
//
//   @override
//   void initState() {
//     super.initState();
//
//     subscription = VideoCompress.compressProgress$.subscribe(
//             (progress) => setState(() => this.progress = progress));
//   }
//
//   @override
//   void dispose() {
//     VideoCompress.cancelCompression();
//     subscription.unsubscribe();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final value = progress == null ? progress : progress! / 100;
//
//     return Padding(
//       padding: EdgeInsets.all(20),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text('Compressing Video...', style: TextStyle(fontSize: 20)),
//           SizedBox(height: 24),
//           LinearProgressIndicator(value: value, minHeight: 12),
//           SizedBox(height: 16),
//           ElevatedButton(
//             onPressed: () => VideoCompress.cancelCompression(),
//             child: Text("Cancel"),
//           )
//         ],
//       ),
//     );
//   }
// }
//
//
//
//
//
//
//
//
//
//





import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:video_player/video_player.dart';
import 'package:video_trimmer/video_trimmer.dart';
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
          child: Padding(
            padding: const EdgeInsets.only(top: 100),
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
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  TrimmerView(fileVideo!),
                            ),
                          );
                        },
                        child: Text('Trim video'),
                      ),
                    ],
                  ),
              ],
            ),
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


class TrimmerView extends StatefulWidget {
  final File file;

  TrimmerView(this.file);

  @override
  _TrimmerViewState createState() => _TrimmerViewState();
}

class _TrimmerViewState extends State<TrimmerView> {
  final Trimmer _trimmer = Trimmer();

  double _startValue = 0.0;
  double _endValue = 0.0;

  bool _isPlaying = false;
  bool _progressVisibility = false;


  Future<void> _saveVideo() async {
    setState(() {
      _progressVisibility = true;
    });

    await _trimmer.saveTrimmedVideo(
      startValue: _startValue,
      endValue: _endValue,
      onSave: (String? outputPath) {
        setState(() {
          _progressVisibility = false;
          if (outputPath != null) {
            print('OUTPUT PATH: $outputPath');
            final snackBar = SnackBar(content: Text('Video save successfully'));
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          } else {
            print('Failed to save video');
            final snackBar = SnackBar(content: Text('Failed to save video'));
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          }
        });
      },
    );
  }

  void _loadVideo() {
    _trimmer.loadVideo(videoFile: widget.file);
  }

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Video Trimmer"),
      ),
      body: Builder(
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.only(bottom: 30.0),
            color: Colors.black,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Visibility(
                  visible: _progressVisibility,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.red,
                  ),
                ),
                ElevatedButton(
                  onPressed: _progressVisibility
                      ? null
                      : () async {
                    await _saveVideo();
                  },
                  child: Text("SAVE"),
                ),
                Expanded(
                  child: VideoViewer(trimmer: _trimmer),
                ),



                Center(
                  child: TrimViewer(
                    trimmer: _trimmer,
                    viewerHeight: 50.0,
                    viewerWidth: MediaQuery.of(context).size.width,
                    maxVideoLength: const Duration(seconds: 60),
                    onChangeStart: (value) => _startValue = value,
                    onChangeEnd: (value) => _endValue = value,
                    onChangePlaybackState: (value) =>
                        setState(() => _isPlaying = value
                        ),
                  ),
                ),





                TextButton(
                  child: _isPlaying
                      ? Icon(
                    Icons.pause,
                    size: 80.0,
                    color: Colors.white,
                  )
                      : Icon(
                    Icons.play_arrow,
                    size: 80.0,
                    color: Colors.white,
                  ),
                  onPressed: () async {
                    bool playbackState = await _trimmer.videoPlaybackControl(
                      startValue: _startValue,
                      endValue: _endValue,
                    );
                    setState(() {
                      _isPlaying = playbackState;
                    });
                  },
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}





























