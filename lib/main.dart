// import 'package:flutter/material.dart';
// import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
//
// import 'VideoCompressor.dart';
//
// void main() {
//   WidgetsFlutterBinding.ensureInitialized();
//   FlutterFFmpegConfig().enableLogCallback(logCallback as LogCallback?);
//   runApp(MyApp());
// }
//
// void logCallback(int level, String message) {
//   print("FFmpegLogCallback: $level $message");
// }
//
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Video Compressor',
//       theme: ThemeData.light(),
//       debugShowCheckedModeBanner: false,
//       home: VideoCompressionScreen(),
//     );
//   }
// }
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'hello.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(),
      debugShowCheckedModeBanner: false,
      title: "Video Compressor",
      home: const VideoCompressed(),
    );
  }
}