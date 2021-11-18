import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart';
import 'package:streamify/Film.dart';

import 'VideoPlayer.dart';

class EpSelector extends StatefulWidget {
  final Film film;
  const EpSelector({Key? key, required this.film}) : super(key: key);

  @override
  _EpSelectorState createState() => _EpSelectorState();
}

class _EpSelectorState extends State<EpSelector> {

  @override
  Widget build(BuildContext context) {
    widget.film.arrivedMin = 0;
    return Scaffold(
        appBar: AppBar(title: Text(widget.film.filmTitle)),
        body: buildTvSeriesListView(context)
    );
  }

  /// Build the seasons and episodes widget.
  buildTvSeriesListView(BuildContext context) {
    return ListView.builder(
        itemCount: widget.film.episodes.length,
        itemBuilder: (context, index) {
          String season = widget.film.episodes.keys.elementAt(index);
          Map episodes = widget.film.episodes[season];
          int epNum = 1;
          return Column(
            children: [
              ExpansionTile(
                title: Text(
                  season, style: TextStyle(fontWeight: FontWeight.bold),),
                children: [
                  for (var episodeTitle in episodes.keys)
                    ListTile(
                        title: Text("${season[season.length -
                            1]}x${epNum++} -  $episodeTitle"),
                        trailing: Icon(Icons.play_arrow),
                        onTap: () async {
                          await _getVideoUri(episodes[episodeTitle]);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    VideoPlayer(film: widget.film)
                            ),
                          );
                        }
                    )
                ],
              ),
            ],
          );
        }
    );
  }

  /// Decrypt the hidden video uri.
  _getVideoUri(String episodeUri) async {
    final uriFilmDescription = await get(
        Uri.parse(episodeUri));
    print(uriFilmDescription.statusCode);
    if (uriFilmDescription.statusCode == 200) {
      try {
        var document = parse(uriFilmDescription.body.toString());
        var link = document.body!.text.split('["')[1];
        link = link
            .split('"]')
            .first
            .replaceAll("\\", "");
        // the method above is valid for only one link
        List<int> res = [];
        try {
          res = base64.decode(base64.normalize(link));
        } catch (exc) {
          link = link
              .split('",')
              .first;
          res = base64.decode(base64.normalize(link));
        }
        widget.film.fileVideoUri = utf8.decode(res);
      } catch (exc) {
        print("exc on $episodeUri while extracting the film uri");
      }
    }
  }

}
