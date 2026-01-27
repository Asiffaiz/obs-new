import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import 'dart:isolate';
import 'dart:ui';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:permission_handler/permission_handler.dart';

// Top-level callback function for download status updates
// This must be top-level for @pragma annotation to work with native code
@pragma('vm:entry-point')
void downloadCallback(String id, int status, int progress) {
  final SendPort? send = IsolateNameServer.lookupPortByName(
    'downloader_send_port',
  );
  send?.send([id, status, progress]);
}

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

  @override
  void initState() {
    super.initState();
    IsolateNameServer.registerPortWithName(
      _port.sendPort,
      'downloader_send_port',
    );

    _port.listen((dynamic data) {
      // data[0] = id, data[1] = status, data[2] = progress
      int newProgress = data[2] as int;

      setState(() {
        progress = newProgress;
      });
    });

    FlutterDownloader.registerCallback(downloadCallback);
  }

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    _port.close();
    super.dispose();
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

  /// Sanitize file name to prevent download issues
  String _sanitizeFileName(String fileName) {
    // Remove or replace invalid characters for file names
    String sanitized = fileName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim();
    
    // Ensure it has .pdf extension if it doesn't have one
    if (!sanitized.toLowerCase().endsWith('.pdf')) {
      sanitized = '$sanitized.pdf';
    }
    
    // Limit length to prevent issues
    if (sanitized.length > 200) {
      sanitized = '${sanitized.substring(0, 200)}.pdf';
    }
    
    return sanitized;
  }

  /// Check and delete existing partial downloads
  Future<void> _cleanupExistingDownload(String savedDir, String fileName) async {
    try {
      final filePath = '$savedDir/$fileName';
      final file = File(filePath);
      
      // Delete existing file if it exists (to avoid 416 Range Not Satisfiable error)
      if (await file.exists()) {
        await file.delete();
      }
      
      // Also check for any existing download tasks with same file name and cancel them
      final tasks = await FlutterDownloader.loadTasks();
      if (tasks != null) {
        for (var task in tasks) {
          if (task.status == DownloadTaskStatus.running ||
              task.status == DownloadTaskStatus.paused ||
              task.status == DownloadTaskStatus.failed) {
            if (task.filename == fileName || task.url == widget.url) {
              try {
                await FlutterDownloader.remove(
                  taskId: task.taskId,
                  shouldDeleteContent: true,
                );
              } catch (e) {
                // Ignore errors when removing tasks
              }
            }
          }
        }
      }
    } catch (e) {
      // Ignore cleanup errors
      print('Cleanup error: $e');
    }
  }

  /// Main download function you can call anywhere
  Future<void> downloadFile(
    BuildContext context,
    String url,
    String fileName,
  ) async {
    try {
      // Sanitize file name
      final sanitizedFileName = _sanitizeFileName(fileName);
      
      // Request permissions (Android only)
      if (Platform.isAndroid) {
        // Request notification permission for download notifications
        await Permission.notification.request();
        
        // For Android 10+ (API 29+), we don't need storage permission for Downloads folder
        // But we still request it for older devices
        if (await Permission.storage.isDenied) {
          await Permission.storage.request();
        }
        
        // Also request manage external storage for Android 11+ if needed
        if (await Permission.manageExternalStorage.isDenied) {
          // Only request if really needed (usually not needed for Downloads folder)
        }
      }

      // Resolve save directory
      String savedDir;
      if (Platform.isAndroid) {
        // Try to use public Downloads folder first
        final downloads = Directory("/storage/emulated/0/Download");
        if (await downloads.exists()) {
          savedDir = downloads.path;
        } else {
          // Fallback to external storage directory
          final dir = await getExternalStorageDirectory();
          savedDir = dir?.path ?? '/storage/emulated/0/Download';
        }
      } else {
        // iOS - use documents directory
        final dir = await getApplicationDocumentsDirectory();
        savedDir = dir.path;
      }

      // Clean up any existing partial downloads to prevent 416 errors
      await _cleanupExistingDownload(savedDir, sanitizedFileName);

      // Enqueue download with proper configuration
      final taskId = await FlutterDownloader.enqueue(
        url: url,
        savedDir: savedDir,
        fileName: sanitizedFileName,
        headers: {
          // Add headers to prevent resume issues
          'Accept-Encoding': 'identity', // Disable compression
        },
        showNotification: true, // Android notification
        openFileFromNotification: true, // Tap to open on Android
        saveInPublicStorage: true, // Android → public Downloads folder
        requiresStorageNotLow: false, // Don't fail if storage is low
      );

      if (context.mounted && taskId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("⬇️ Download started: $sanitizedFileName"),
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ Failed to start download. Please try again."),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Download failed: ${e.toString()}"),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => downloadFile(context, url, fileName),
            ),
          ),
        );
      }
      print('Download error: $e');
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
