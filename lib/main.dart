import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(const MaterialApp(
    home: WebViewApp(),
    debugShowCheckedModeBanner: false,
  ));
}

class WebViewApp extends StatefulWidget {
  const WebViewApp({super.key});

  @override
  State<WebViewApp> createState() => _WebViewAppState();
}

class _WebViewAppState extends State<WebViewApp> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();

    final WebViewController webViewController = WebViewController();

    webViewController
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('https://ai-study-assistant-zrey.onrender.com/'));

    if (webViewController.platform is AndroidWebViewController) {
      final dynamic androidController = webViewController.platform;
      
      try {
        androidController.setOnShowFileChooser((params) async {
          try {
            final FilePickerResult? result = await FilePicker.platform.pickFiles();
            if (result != null && result.files.single.path != null) {
              return [result.files.single.path!];
            }
          } catch (e) {
            debugPrint("File picker error: $e");
          }
          return [];
        });
      } catch (e) {
        debugPrint("Set show file chooser error: $e");
      }
    }

    controller = webViewController;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: WebViewWidget(controller: controller),
      ),
    );
  }
}