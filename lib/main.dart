import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';

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
      ..addJavaScriptChannel(
        'FlutterFilePicker',
        onMessageReceived: (JavaScriptMessage message) async {
          if (message.message == 'pick') {
            try {
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['pdf'],
                withData: true,
              );
              if (result != null && result.files.single.bytes != null) {
                final bytes = result.files.single.bytes!;
                final fileName = result.files.single.name;
                final base64String = base64Encode(bytes);

                controller.runJavaScript("""
                  (function() {
                    const base64 = '$base64String';
                    const name = '$fileName';
                    
                    const byteCharacters = atob(base64);
                    const byteNumbers = new Array(byteCharacters.length);
                    for (let i = 0; i < byteCharacters.length; i++) {
                      byteNumbers[i] = byteCharacters.charCodeAt(i);
                    }
                    const byteArray = new Uint8Array(byteNumbers);
                    const blob = new Blob([byteArray], {type: 'application/pdf'});
                    const file = new File([blob], name, {type: 'application/pdf'});
                    
                    const dataTransfer = new DataTransfer();
                    dataTransfer.items.add(file);
                    
                    const fileInput = document.querySelector('input[type="file"]');
                    if (fileInput) {
                      fileInput.files = dataTransfer.files;
                      fileInput.dispatchEvent(new Event('change', { bubbles: true }));
                      fileInput.dispatchEvent(new Event('input', { bubbles: true }));
                    }
                  })();
                """);
              }
            } catch (e) {
              debugPrint("File picker error: $e");
            }
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            controller.runJavaScript("""
              if (!window._filePickerInitialized) {
                window._filePickerInitialized = true;
                document.addEventListener('click', function(e) {
                  const target = e.target.closest('button, label, input, div');
                  if (target) {
                    const text = target.innerText ? target.innerText.toLowerCase() : '';
                    if (text.includes('browse') || text.includes('upload') || target.tagName === 'INPUT') {
                      e.preventDefault();
                      e.stopPropagation();
                      window.FlutterFilePicker.postMessage('pick');
                    }
                  }
                }, true);
              }
            """);
          },
        ),
      )
      ..loadRequest(Uri.parse('https://ai-study-assistant-zrey.onrender.com/'));
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