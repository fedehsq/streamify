import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/cupertino.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart';
import 'package:streamify/DatabaseHelper.dart';
import 'package:video_player/video_player.dart';
import 'Film.dart';

class VideoPlayer extends StatefulWidget {
  final Film film;

  const VideoPlayer({Key? key, required this.film}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _VideoPlayerState();
  }
}

class _VideoPlayerState extends State<VideoPlayer> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  final dbHelper = DatabaseHelper.instance;


  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        var minArrived = await _videoPlayerController.position;
        widget.film.arrivedMin = minArrived!.inSeconds;
        widget.film.episodeArrived = widget.film.fileVideoUri;
        await dbHelper.insert(widget.film);
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
            child: _chewieController != null &&
                _chewieController!
                    .videoPlayerController.value.isInitialized
                ?
            Chewie(
              controller: _chewieController!,
            )
                : _initialLoader()),
      ),
    );
  }

  /// Get the video file and then initialize the video player on that file.
  Future<void> _initializePlayer() async {
    print(widget.film.fileVideoUri);
    try {
      var filmFileUri = await _getVideo(widget.film.fileVideoUri);
      if (filmFileUri.isEmpty) {
        filmFileUri = await _getVideo(widget.film.fileVideoUri);
      }
      _videoPlayerController = VideoPlayerController.network(filmFileUri);
      await Future.wait([
        _videoPlayerController.initialize(),
      ]);
      _createChewieController();
      setState(() {});
    } catch (exc) {
      print(exc);
      Navigator.pop(context);
    }
  }

  /// Create the controller.
  void _createChewieController() {
    _chewieController = ChewieController(
      startAt: Duration(seconds: widget.film.arrivedMin),
      materialProgressColors: ChewieProgressColors(
        playedColor: Colors.red,
      ),
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      looping: false,
      allowedScreenSleep: false,
    );
  }

  /// Analyze the video host and extract the hidden video.
  _getVideo(String? video) async {
    final film = await get(Uri.parse(video!));
    if (film.statusCode == 200) {
      if (film.body.contains("streamtape")) {
        return _getStreamtapeVideo(film);
      } else {
        return _getMixDropVideo(film);
      }
    }
  }

  /// Get the file video for the stream.
  String? _getStreamtapeVideo(Response film) {
    try {
      var document = parse(film.body.toString());
      var link = document.getElementById("ideoolink")!.text;
      link = link
          .split("&token")
          .first;
      var token = document.body!
          .text
          .split("document.getElementById('ideoolink').innerHTML")
          .last;
      token = token
          .split("&token=")
          .last
          .split("')")
          .first;
      link = "https:" + link + "&token=" + token;
      return link;
    } catch (exc) {
      print(exc);
      Navigator.pop(context);
    }
  }

  /// Decrypt and get the file video for the stream.
  String? _getMixDropVideo(Response film) {
    try {
      String body = film.body;
      String prefix = body.split("'|MDCore|").last.split("|").first;
      String delivery = body.split("'|MDCore|").last.split(prefix)[1].split("|")[1];
      String token = delivery.contains("delivery") ?
      body.split(delivery).last.split("|")[1] + ".mp4?s=" :
          delivery + ".mp4?s=";
      delivery = delivery.contains("delivery") ? delivery : prefix;
      prefix = prefix.contains("delivery") ? "a" : prefix;
      String timeValidity = body.split("|true|").last.split("|").first + "&e=";
      String tmp = body.split("|wurl|").last.split("|_t").first;
      List<String> ts  = tmp.split("|");
      if (ts.length == 4)
        return "";
      String t1 = ts.last;
      String t2 = ts[ts.length - 2];
      timeValidity += t1 + "&_t=" + t2;
      var link = "https://$prefix-$delivery.mxdcontent.net/v/$token$timeValidity";
      print(link);
      return link;
    } catch (exc) {
      print(exc);
    }
  }

  /// Build a stack that displays the cover film image while the video
  /// controller is setting up.
  _initialLoader() {
    return Stack(
      fit: StackFit.expand,
      alignment: AlignmentDirectional.center,
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Image.network(widget.film.coverImage,
            fit: BoxFit.fill,
          ),
        ),
        Center(child: CircularProgressIndicator(color: Colors.red, strokeWidth: 1.5,)),
      ],
    );
  }
}
