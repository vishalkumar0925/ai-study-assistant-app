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
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('https://ai-study-assistant-zrey.onrender.com/'));

    if (controller.platform is AndroidWebViewController) {
      final AndroidWebViewController androidController =
          controller.platform as AndroidWebViewController;
      
      androidController.setOnShowFileSelector((params) async {
        try {
          final FilePickerResult? result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['pdf'],
          );
          if (result != null && result.files.single.path != null) {
            String filePath = result.files.single.path!;
            String fileName = result.files.single.name;
            
            controller.runJavaScript(
              "const textElement = document.querySelector('p, span, div'); if(textElement) { textElement.innerText = '$fileName'; }"
            );
            
            return [filePath];
          }
        } catch (e) {
          debugPrint("File picker error: $e");
        }
        return [];
      });
    }
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