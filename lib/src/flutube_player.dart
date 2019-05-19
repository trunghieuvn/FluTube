import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class FluTube extends StatefulWidget {
  /// USER INPUT VARS

  /// YouTube video URL
  final String videoUrl;

  /// Video aspect ratio
  final double aspectRatio;

  /// Constructor
  FluTube(
      this.videoUrl, {
      this.aspectRatio = 16 / 9, // Aspect ratio defaults to 16 / 9
  });

  @override
  _FluTubeState createState() => _FluTubeState();
}

class _FluTubeState extends State<FluTube> {
  WebViewController _controller;

  @override
  Widget build(BuildContext context) {
    _loadHtmlFromAssets();
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: Builder(
        builder: (BuildContext context) {
          return WebView(
            initialUrl: Uri.dataFromString('assets/yt_player.html', mimeType: 'text/html').toString(),
            javascriptMode: JavascriptMode.unrestricted,
            onWebViewCreated: (WebViewController webViewController) {
              _controller = webViewController;
            },
            onPageFinished: (url) {
              print(url);
              _controller.evaluateJavascript('loadVideo("${widget.videoUrl.substring(widget.videoUrl.indexOf('v=') + 2)}", 0);');
            },
          );
        }
      ),
    );
  }

  _loadHtmlFromAssets() async {
    String fileText = await rootBundle.loadString('assets/yt_player.html');
    _controller.loadUrl( Uri.dataFromString(
        fileText,
        mimeType: 'text/html',
        encoding: Encoding.getByName('utf-8')
    ).toString());
  }
}