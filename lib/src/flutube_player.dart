import 'dart:async';
import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

enum SourceVideo { YOUTUBE, MP4 }

class FluTube extends StatefulWidget {
  /// Youtube video URL(s)
  final _videourls;

  /// Initialize the Video on Startup. This will prep the video for playback.
  final bool autoInitialize;

  /// Play the video as soon as it's displayed
  final bool autoPlay;

  /// Start video at a certain position
  final Duration startAt;

  /// Whether or not the video should loop
  final bool looping;

  /// Whether or not to show the controls
  final bool showControls;

  /// The Aspect Ratio of the Video. Important to get the correct size of the
  /// video!
  ///
  /// Will fallback to fitting within the space allowed.
  final double aspectRatio;

  /// Allow screen to sleep
  final bool allowScreenSleep;

  /// Show mute icon
  final bool allowMuting;

  /// Show fullscreen button.
  final bool allowFullScreen;

  /// Device orientation when leaving fullscreen.
  final List<DeviceOrientation> deviceOrientationAfterFullscreen;

  /// System overlays when exiting fullscreen.
  final List<SystemUiOverlay> systemOverlaysAfterFullscreen;

  /// The placeholder is displayed underneath the Video before it is initialized
  /// or played.
  final Widget placeholder;

  /// Play video directly in fullscreen
  final bool fullscreenByDefault;

  /// Whether or not to show the video thumbnail when the video did not start playing.
  final bool showThumb;

  /// Video events

  /// Video start
  final VoidCallback onVideoStart;

  /// Video end
  final VoidCallback onVideoEnd;

  /// Source video 
  final SourceVideo source;

  ///custom Thumnail 
  final Widget customThumnail;
  
  FluTube(
    this._videourls, {
    Key key,
    this.aspectRatio,
    this.autoInitialize = false,
    this.autoPlay = false,
    this.startAt,
    this.looping = false,
    this.placeholder,
    this.showControls = true,
    this.fullscreenByDefault = false,
    this.showThumb = true,
    this.allowMuting = true,
    this.allowScreenSleep = false,
    this.allowFullScreen = true,
    this.deviceOrientationAfterFullscreen,
    this.systemOverlaysAfterFullscreen,
    this.onVideoStart,
    this.onVideoEnd,
    this.customThumnail,
    this.source = SourceVideo.MP4
  }) : super(key: key) {
    assert(_videourls is String, 'The video URL needs to be of type String.');
  }

  FluTube.playlist(
    this._videourls, {
    Key key,
    this.aspectRatio,
    this.autoInitialize = false,
    this.autoPlay = false,
    this.startAt,
    this.placeholder,
    this.looping = false,
    this.showControls = true,
    this.fullscreenByDefault = false,
    this.showThumb = true,
    this.allowMuting = true,
    this.allowScreenSleep = false,
    this.allowFullScreen = true,
    this.deviceOrientationAfterFullscreen,
    this.systemOverlaysAfterFullscreen,
    this.onVideoStart,
    this.onVideoEnd,
    this.customThumnail,
    this.source = SourceVideo.YOUTUBE
  }) : super(key: key) {
    assert(_videourls is List<String>, 'The video playlist needs to be of type List<String>.');
    assert(_videourls.length > 0, 'Playlist should not be empty!');
  }

  @override
  FluTubeState createState() => FluTubeState();
}

class FluTubeState extends State<FluTube>{
  static Map mapAspecRatio = Map();
  VideoPlayerController videoController;
  ChewieController chewieController;
  bool isPlaying = false;
  bool _needsShowThumb;
  int _currentlyPlaying = 0; // Track position of currently playing video

  String _lastUrl;
  bool get _isPlaylist => widget._videourls is List<String>;

  @override
  initState() {
    super.initState();
    _needsShowThumb = !widget.autoPlay;
    if(_isPlaylist) {
      _initialize((widget._videourls as List<String>)[0]); // Play the very first video of the playlist
    } else {
      _initialize(widget._videourls as String);
    }
  }

  void _initialize(String _url) {
    _lastUrl = _url;
    _fetchVideoURL(_url).then((url) {
      videoController = VideoPlayerController.network(url)
        ..addListener(_playingListener)
        ..addListener(_errorListener)
        ..addListener(_endListener);

      // Video start callback
      if(widget.onVideoStart != null) {
        videoController.addListener(_startListener);
      }

      if(widget.autoInitialize)
      {
        videoController.initialize().then((values){
          chewieController = ChewieController(
              videoPlayerController: videoController,
              aspectRatio: widget.aspectRatio ?? (FluTubeState.mapAspecRatio[widget._videourls] ?? (videoController?.value?.aspectRatio ?? 16/9)),
              autoInitialize: widget.autoInitialize,
              autoPlay: widget.autoPlay,
              startAt: widget.startAt,
              looping: _isPlaylist ? false : widget.looping,
              placeholder: widget.placeholder,
              showControls: widget.showControls,
              fullScreenByDefault: widget.fullscreenByDefault,
              allowFullScreen: widget.allowFullScreen,
              deviceOrientationsAfterFullScreen: widget.deviceOrientationAfterFullscreen,
              systemOverlaysAfterFullScreen: widget.systemOverlaysAfterFullscreen,
              allowedScreenSleep: widget.allowScreenSleep,
              allowMuting: widget.allowMuting
          );
          setState((){})  ;
        });
      }else{

        chewieController = ChewieController(
          videoPlayerController: videoController,
          aspectRatio: widget.aspectRatio ?? (FluTubeState.mapAspecRatio[widget._videourls] ?? (videoController?.value?.aspectRatio ?? 16/9)),
          autoInitialize: widget.autoInitialize,
          autoPlay: widget.autoPlay,
          startAt: widget.startAt,
          looping: _isPlaylist ? false : widget.looping,
          placeholder: widget.placeholder,
          showControls: widget.showControls,
          fullScreenByDefault: widget.fullscreenByDefault,
          allowFullScreen: widget.allowFullScreen,
          deviceOrientationsAfterFullScreen: widget.deviceOrientationAfterFullscreen,
          systemOverlaysAfterFullScreen: widget.systemOverlaysAfterFullscreen,
          allowedScreenSleep: widget.allowScreenSleep,
          allowMuting: widget.allowMuting
        );
      }
      


      
    });
  }

  _playingListener() {
    if(videoController.value != null && videoController.value.initialized && FluTubeState.mapAspecRatio[widget._videourls] == null){
      FluTubeState.mapAspecRatio[widget._videourls] = videoController.value.aspectRatio;
    }
    if(isPlaying != videoController.value.isPlaying){
      setState(() {
        isPlaying = videoController.value.isPlaying;
      });
    }
  }

  _startListener() {
    if(videoController.value.initialized && isPlaying)
      widget.onVideoStart();
  }

  _endListener() {
    // Video end callback
    if(videoController != null) {
      if(videoController.value.initialized && !videoController.value.isBuffering) {
        if(videoController.value.position >= videoController.value.duration){
          if(isPlaying){
            chewieController.pause();
            chewieController.seekTo(Duration());
          }
          if(widget.onVideoEnd != null)
            widget.onVideoEnd();
          if(widget.showThumb && !_isPlaylist){
            setState(() {
              _needsShowThumb = true;
            });
          }
          if(_isPlaylist) {
            if(_currentlyPlaying < (widget._videourls as List<String>).length - 1){
              _playlistLoadNext();
            } else {
              if(widget.looping) {
                _playlistLoop();
              }
            }
          }
        }
      }
    }
  }

  _errorListener() {
    if (!videoController.value.hasError) return;
    if (videoController.value.errorDescription.contains("code: 403")) _initialize(_lastUrl);
  }

  _playlistLoadNext() {
    chewieController?.dispose();
    setState(() {
      _currentlyPlaying++;
    });
    videoController.pause();
    videoController = null;
    _initialize((widget._videourls as List<String>)[_currentlyPlaying]);
    chewieController.play();
  }

  _playlistLoop() {
    chewieController?.dispose();
    setState(() {
      _currentlyPlaying = 0;
    });
    videoController.pause();
    videoController = null;
    _initialize((widget._videourls as List<String>)[0]);
    chewieController.play();
  }

  @override
  void dispose() {
    if (videoController != null) videoController.dispose();
    if (chewieController != null) chewieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String _linkImage = widget.source == SourceVideo.MP4 ? "https://fighttech.vn/media/image.png" : _videoThumbURL(_isPlaylist ? widget._videourls[_currentlyPlaying] : widget._videourls);
    if(widget.showThumb && !isPlaying && _needsShowThumb){
      return Center(
        child: Container(
          width: MediaQuery.of(context).size.width,
          child: AspectRatio(
            aspectRatio: widget.aspectRatio ?? (videoController?.value?.aspectRatio ?? 16/9),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                widget.customThumnail ??
                Image.network(
                  _linkImage,
                  fit: BoxFit.cover,
                ),
                Center(
                  child: ClipOval(
                    child: Container(
                      color: Colors.white,
                      child: IconButton(
                        iconSize: 50.0,
                        color: Colors.black,
                        icon: Icon(
                          Icons.play_arrow,
                        ),
                        onPressed: () async {
                          if(!videoController.value.initialized){
                            await videoController.initialize();
                            await videoController.play();

                          }else{
                            videoController.play();

                          }
                          setState(() {
                            _needsShowThumb = false;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      return chewieController != null ? Chewie(
        key: widget.key,
        controller: chewieController,
      ) : AspectRatio(
        aspectRatio: widget.aspectRatio ?? (FluTubeState.mapAspecRatio[widget._videourls] ?? (videoController?.value?.aspectRatio ?? 16/9)),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
  }

  Future<String> _fetchVideoURL(String yt) async {
    if(widget.source == SourceVideo.YOUTUBE){
      final response = await http.get(yt);
      Iterable parseAll = _allStringMatches(response.body, RegExp("\"url_encoded_fmt_stream_map\":\"([^\"]*)\""));
      final Iterable<String> parse = _allStringMatches(parseAll.toList()[0], RegExp("url=(.*)"));
      final List<String> urls = parse.toList()[0].split('url=');
      parseAll = _allStringMatches(urls[1], RegExp("([^&,]*)[&,]"));
      String finalUrl = Uri.decodeFull(parseAll.toList()[0]);
      if(finalUrl.indexOf('\\u00') > -1)
        finalUrl = finalUrl.substring(0, finalUrl.indexOf('\\u00'));
      return finalUrl;
    }else if(widget.source == SourceVideo.MP4) {
      return yt;
    }else{
      return null;
    }
    
  }

  Iterable<String> _allStringMatches(String text, RegExp regExp) => regExp.allMatches(text).map((m) => m.group(0));

  String _videoThumbURL(String yt) {
    String id = _getVideoIdFromUrl(yt);
    return "http://img.youtube.com/vi/$id/0.jpg";
  }
  
  String _getVideoIdFromUrl(String url) {
      // For matching https://youtu.be/<VIDEOID>
      RegExp regExp1 = new RegExp(r"youtu\.be\/([^#\&\?]{11})", caseSensitive: false, multiLine: false);
      // For matching https://www.youtube.com/watch?v=<VIDEOID>
      RegExp regExp2 = new RegExp(r"\?v=([^#\&\?]{11})", caseSensitive: false, multiLine: false);
      // For matching https://www.youtube.com/watch?x=yz&v=<VIDEOID>
      RegExp regExp3 = new RegExp(r"\&v=([^#\&\?]{11})", caseSensitive: false, multiLine: false);
      // For matching https://www.youtube.com/embed/<VIDEOID>
      RegExp regExp4 = new RegExp(r"embed\/([^#\&\?]{11})", caseSensitive: false, multiLine: false);
      // For matching https://www.youtube.com/v/<VIDEOID>
      RegExp regExp5 = new RegExp(r"\/v\/([^#\&\?]{11})", caseSensitive: false, multiLine: false);

      String matchedString;

      if(regExp1.hasMatch(url)) {
        matchedString = regExp1.firstMatch(url).group(0);
      }
      else if(regExp2.hasMatch(url)) {
        matchedString = regExp2.firstMatch(url).group(0);
      }
      else if(regExp3.hasMatch(url)) {
        matchedString = regExp3.firstMatch(url).group(0);
      }
      else if(regExp4.hasMatch(url)) {
        matchedString = regExp4.firstMatch(url).group(0);
      }
      else if(regExp5.hasMatch(url)) {
        matchedString = regExp5.firstMatch(url).group(0);
      }

      return matchedString != null ? matchedString.substring(matchedString.length - 11) : null;
    }
}
