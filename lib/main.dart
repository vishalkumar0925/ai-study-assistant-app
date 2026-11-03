import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';

void main() {
  runApp(const MaterialApp(
    home: LoadingScreen(), // Splash screen sabse pehle chalegi
    debugShowCheckedModeBanner: false,
  ));
}

// 1. Aapka Custom Purple Loading Screen
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    // 3 second baad automatic WebViewApp par chala jayega
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WebViewApp()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0B1E), // Dark purple background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _animation,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Colors.purpleAccent, Colors.deepPurple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purpleAccent.withValues(alpha: 0.6),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              "AI Study Assistant",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Preparing your study space...",
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.purpleAccent),
            ),
          ],
        ),
      ),
    );
  }
}

// 2. Aapka Original File Picker WebView Code (Bina kisi ched-chad ke)
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
      backgroundColor: const Color(0xFF0F0B1E),
      body: SafeArea(
        child: WebViewWidget(controller: controller),
      ),
    );
  }
}