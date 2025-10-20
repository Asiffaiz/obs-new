import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import 'dart:isolate';
import 'dart:ui';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:permission_handler/permission_handler.dart';

class CustomPdfViewer extends StatefulWidget {
  final String url;
  final String title;
  const CustomPdfViewer({super.key, required this.url, required this.title});

  @override
  State<CustomPdfViewer> createState() => _CustomPdfViewerState();
}

class _CustomPdfViewerState extends State<CustomPdfViewer> {
  ReceivePort _port = ReceivePort();
  int progress = 0;
  final String _portName = "downloader_send_port";

  @override
  void initState() {
    super.initState();
    IsolateNameServer.registerPortWithName(
      _port.sendPort,
      'downloader_send_port',
    );

    _port.listen((dynamic data) {
      String id = data[0];
      DownloadTaskStatus status = DownloadTaskStatus.fromInt(data[1]);
      int newProgress = data[2];

      setState(() {
        progress = newProgress;
      });
    });

    FlutterDownloader.registerCallback(downloadCallback);
  }

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    super.dispose();
  }

  @pragma('vm:entry-point')
  static void downloadCallback(String id, int status, int progress) {
    final SendPort? send = IsolateNameServer.lookupPortByName(
      'downloader_send_port',
    );
    send?.send([id, status, progress]);
  }

  // Future<void> downloadPdf(
  //   BuildContext context,
  //   String url,
  //   String fileName,
  // ) async {
  //   try {
  //     // Save in app's document directory
  //     Directory appDocDir = await getApplicationDocumentsDirectory();
  //     String savePath = "${appDocDir.path}/$fileName";

  //     await Dio().download(url, savePath);

  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text("✅ Downloaded successfully: $fileName"),
  //         backgroundColor: Colors.green,
  //       ),
  //     );
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text("Failed to download"),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //   }
  // }

  /// Main download function you can call anywhere
  Future<void> downloadFile(
    BuildContext context,
    String url,
    String fileName,
  ) async {
    try {
      // Request permissions (Android only)
      if (Platform.isAndroid) {
        await Permission.notification.request();
        await Permission.storage.request();
      }

      // Resolve save directory
      String savedDir;
      if (Platform.isAndroid) {
        final downloads = Directory("/storage/emulated/0/Download");
        if (await downloads.exists()) {
          savedDir = downloads.path;
        } else {
          final dir = await getExternalStorageDirectory();
          savedDir = dir!.path;
        }
      } else {
        final dir = await getApplicationDocumentsDirectory();
        savedDir = dir.path;
      }

      // Enqueue download
      final taskId = await FlutterDownloader.enqueue(
        url: url,
        savedDir: savedDir,
        fileName: fileName,
        showNotification: true, // Android notification
        openFileFromNotification: true, // Tap to open on Android
        saveInPublicStorage: true, // Android → public Downloads folder
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⬇️ Download started: $fileName")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("❌ Download failed: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.title, style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            onPressed: () {
              downloadFile(context, widget.url, widget.title);
            },
            icon: Icon(Icons.download),
          ),
        ],
      ),
      body: SfPdfViewer.network(widget.url),
    );
  }
}
