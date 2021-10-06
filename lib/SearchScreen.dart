import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:streamify/CommonWidget.dart';
import 'package:streamify/EpSelector.dart';
import 'package:streamify/FilmPresentation.dart';
import 'package:streamify/UriFunction.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'Film.dart';
import 'VideoPlayer.dart';

class SearchScreen extends StatefulWidget {
  final String title;
  final String domain;

  const SearchScreen({Key? key, required this.title, required this.domain})
      : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with UriHelper, CommonWidget {

  // while website inside the WebView is loading
  bool _isLoading = true;
  // films found for the title research
  final List<Film> _films = [];
  // films chosen as _favourites
  final List<Film> _favourites = [];
  // films started to see
  final List<Film> _started = [];
  // controller of WebView
  late WebViewController _controller;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        // trigger leaving and use own data
        Navigator.pop(context, [_favourites, _started]);
        // we need to return a future
        return Future.value(true);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text("Streamify"),
        ),
        body: _isLoading ? _webPageDesign() : _buildFilmView(),
      ),
    );
  }

  /// Return a scaffold that hides the webView while the researched items are loaded.
  _webPageDesign() {
    return Scaffold(
      body: Stack(
          fit: StackFit.expand,
          alignment: AlignmentDirectional.center,
          children: [
            WebView(
              onWebViewCreated: (controller) {
                _controller = controller;
              },
              onPageFinished: (finish) async => _evalJS(),
              initialUrl: "${widget.domain}?s=${widget
                  .title}",
              javascriptMode: JavascriptMode.unrestricted,
            ),
            // custom loader composed by big film image and progress bar
            if (_isLoading)
              Scaffold(
                  backgroundColor: Colors.black,
                  body: buildAnimatedText("Sto cercando...")
              ),
          ]
      ),
    );
  }

  /// Once the films are found, extract all the needed info from the html.
  /// When all info are done, set the boolean that build the list of films Widget.
  _evalJS() async {
    String html = await _controller.evaluateJavascript(
        "window.document.getElementsByClassName('search-page')[0].outerHTML;");
    var elements = html.split("result-item");
    bool searched = false;
    for (int i = 1; i < elements.length; i++) {
      searched = true;
      var href = elements[i]
          .split('a href=\\"')
          .last
          .split('/\\">')
          .first + "/";
      var src = elements[i]
          .split('img src=\\"')
          .last
          .split('\\"')
          .first;
      var title = elements[i]
          .split('alt=\\"')
          .last
          .split('\\">')
          .first;
      var rank = elements[i]
          .split('IMDb ')
          .last
          .split("\\")
          .first;
      var category = elements[i].contains("tvshows") ? "Serie Tv" : "Film";
      double r = 0.0;
      try {
        r = double.parse(rank);
      } catch (exc) {}
      Film film = Film(title, "gds", href, src, category, 0, 0, title);
      film.rating = r;
      _films.add(film);
    }
    if (searched) {
      setState(() {
        _isLoading = false;
      });
    }
    if (html.contains("Nessun risultato")) {
      Navigator.pop(context);
    }
  }

  /// Build the list of found films.
  _buildFilmView() {
    return ListView.builder(
        itemCount: _films.length,
        itemBuilder: (context, index) {
          return index != 0
              ? Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: _films[index].description.isEmpty ? _buildInfoView(index) : _buildItemView(index),
              ))
              :
          Column(children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text("${_films.length} risultati per: ${widget.title}",
                textAlign: TextAlign.center, style: TextStyle(fontSize: 16),),
            ),
            _films[index].description.isEmpty ? _buildInfoView(index) : _buildItemView(index),
          ],);
        });
  }

  /// Download film's rank and film's description,
  /// then build the row containing these info.
  _buildInfoView(int index) {
    return FutureBuilder<void>(
        future: downloadDescription(_films[index]),
        builder: (context, AsyncSnapshot<void> snapshot) {
          return snapshot.connectionState == ConnectionState.done
              ? _buildItemView(index)
              : Center(
              child: CircularProgressIndicator(strokeWidth: 1, color: Colors.red,));
        }
    );
  }

  /// Build the container containing the card containing the film.
  ListTile _buildItemView(int index) {
    return ListTile(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) =>
            _films[index].category == "Film"
                ? VideoPlayer(film: _films[index])
                : EpSelector(film: _films[index]),
          ),
        );
        if (!_started.contains(_films[index]) &&
            _films[index].arrivedMin != 0) {
          _started.add(_films[index]);
        }
      },
      leading: CircleAvatar(backgroundImage: Image
          .network(_films[index].coverImage)
          .image),
      title: Text(_films[index].filmTitle),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_films[index].quality.isNotEmpty)
            Text(_films[index].quality),
          buildStarsRow(_films[index])
        ],
      ),
      // Check empty case for film and tv series: in that case download
      // the info, otherwise display them
      trailing: _buildInfoLoveButtonsRow(index),
    );
  }

  /// Build the row containing the favourite button and the info button.
  _buildInfoLoveButtonsRow(int index) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Film description icon
        IconButton(icon: Icon(Icons.info),
            onPressed: () async {
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (BuildContext context) =>
                          FilmPresentation(film: _films[index])
                  ));
              if (_films[index].favourite == 0) {
                _favourites.remove(_films[index]);
              } else {
                _favourites.add(_films[index]);
              }
              setState(() {});
            }
        ),
        // Favourite icon
        IconButton(icon: _films[index].favourite == 1
            ? Icon(Icons.favorite, color: Colors.red)
            : Icon(Icons.favorite_border),
          // Add/remove the current film in/from favourite_Films
          onPressed: () {
            setState(() {
              _films[index].favourite = _films[index].favourite == 0 ? 1 : 0;
              if (_films[index].favourite == 0) {
                _favourites.remove(_films[index]);
              } else {
                _favourites.add(_films[index]);
              }
            });
          },
        ),
      ],
    );
  }
}
