import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:streamify/UriFunction.dart';
import 'CommonWidget.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import 'Film.dart';

class FilmPresentation extends StatefulWidget {
  final Film film;
  const FilmPresentation({Key? key, required this.film}) : super(key: key);

  @override
  _FilmPresentationState createState() => _FilmPresentationState();
}

class _FilmPresentationState extends State<FilmPresentation> with CommonWidget, UriHelper {

  late final YoutubePlayerController _controller;

  @override
  void initState() {
    // Initialize the youtube controller
    _controller = YoutubePlayerController(
      initialVideoId: YoutubePlayer.convertUrlToId(widget.film.trailerUri) ?? "",
      flags: YoutubePlayerFlags(
        autoPlay: false,
      ),
    );
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context,
              bool innerBoxIsScrolled) {
            return <Widget>[
              buildSliverAppBar(),
            ];
          },
          body: ListView(
              padding: EdgeInsets.zero,
              children: [
                // film's description
                buildPaddingTitle("Trama"),
                buildDescription(),
                // cast
                if (widget.film.actors.length > 1)
                  buildPaddingTitle("Cast"),
                if (widget.film.actors.length > 1)
                  buildActorsListContainer(),
                // film's trailer
                if (widget.film.trailerUri.isNotEmpty)
                  Row(
                    children: [
                      Stack(
                          children: [
                            Padding(
                                padding: const EdgeInsets.only(
                                    left: 8, top: 32.0),
                                child: Image.asset(
                                  "images/youtube.png", width: 100,
                                  color: Colors.white,)
                            ),
                            Padding(
                                padding: const EdgeInsets.only(
                                    left: 8, top: 32.0),
                                child: Image.asset(
                                    "images/icon_youtube.png", width: 32)
                            ),
                          ]),
                      buildPaddingTitle("Trailer")
                    ],
                  ),
                if (widget.film.trailerUri.isNotEmpty)
                  buildYoutubePlayer(),
              ]
          ),
        )
    );
  }

  /// Build the dynamic floating app bar.
  SliverAppBar buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
          title: Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8),
            child: Text(widget.film.filmTitle,
                style: TextStyle(
                    fontFamily: 'Palette Mosaic',
                    fontSize: 12)),
          ),
          centerTitle: true,
          background: buildSliverAppBarBody()),
    );
  }

  /// Build the expanded item of app bar.
  buildSliverAppBarBody() {
    return Stack(
        alignment: Alignment.center,
        fit: StackFit.expand,
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Image.network(widget.film.backgroundImage.isEmpty
                ? widget.film.coverImage
                : widget.film.backgroundImage,
              fit: BoxFit.fill,
              loadingBuilder: (BuildContext context, Widget child,
                  ImageChunkEvent? loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                }
                return Center(
                  child: CircularProgressIndicator(
                      strokeWidth: 1, color: Colors.red),
                );
              },
              errorBuilder: (BuildContext context, Object exception,
                  StackTrace? stackTrace) {
                return Image.network(widget.film.coverImage,
                  fit: BoxFit.fill,
                );
              },
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Container(
                    height: 200,
                    width: 140,
                    child:
                    Card(
                        color: Colors.transparent,
                        clipBehavior: Clip.hardEdge,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Image.network(widget.film
                            .coverImage,
                          loadingBuilder: (BuildContext context, Widget child,
                              ImageChunkEvent? loadingProgress) {
                            if (loadingProgress == null) {
                              return child;
                            }
                            return Center(
                              child: CircularProgressIndicator(
                                  strokeWidth: 1, color: Colors.red),
                            );
                          },
                        )
                    )
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //_downloadImdbRank(widget.film),
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 32.0),
                          child: Row(
                            children: [
                              Image.asset("images/imdb.png", height: 28,),
                              Text(widget.film.rating == 0.0
                                  ? " N.A"
                                  : " ${widget.film.rating}", style: TextStyle(
                                  fontWeight: FontWeight.bold),)
                            ],
                          ),
                        ),
                        buildStarsRow(widget.film),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Container(
                        width: 100,
                        child: Text(
                            widget.film.genre,
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold)
                        ),
                      ),
                    ),
                  ],
                ),
                IconButton(
                    onPressed: () {
                      widget.film.favourite = widget.film.favourite == 0 ? 1 : 0;
                      setState(() {});
                    },
                    icon:
                    widget.film.favourite == 1 ?
                    Icon(Icons.favorite, color: Colors.red)
                        : Icon(Icons.favorite_border)
                )
              ],
            ),
          ),
        ]
    );
  }

  /*
  FutureBuilder<String?> _downloadImdbRank(Film film) {
    return FutureBuilder<String?>(
        future: getImdbRank(film),
        builder: (context,
            AsyncSnapshot<String?> snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data!.isEmpty)
              return Container();
            film.rating = double.parse(snapshot.data ?? "0");
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 32.0),
                  child: Row(
                    children: [
                      Image.asset("images/imdb.png", height: 28,),
                      Text(" ${widget.film.rating}", style: TextStyle(fontWeight: FontWeight.bold),)
                    ],
                  ),
                ),
                buildStarsRow(widget.film),
              ],
            );
          } else {
            return CircularProgressIndicator(
                strokeWidth: 1, color: Colors.red);
          }
        });
  }
   */

    Padding buildPaddingTitle(String title) {
    return Padding(
                padding: const EdgeInsets.only(top: 32, left: 16),
                child: Text(title, style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 20)),
              );
  }

  Container buildActorsListContainer() {
    return Container(
      height: 186,
      child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: widget.film.actors.length,
          itemBuilder: (context, index) {
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              clipBehavior: Clip.hardEdge,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (widget.film.actors[index].image.contains("no_foto_cast"))
                    Image.asset("images/person.png", width: 90),
                  if (!widget.film.actors[index].image.contains("no_foto_cast"))
                    Image.network(widget.film.actors[index].image,
                      loadingBuilder: (BuildContext context, Widget child,
                          ImageChunkEvent? loadingProgress) {
                        if (loadingProgress == null) {
                          return child;
                        }
                        return CircularProgressIndicator(
                            strokeWidth: 1, color: Colors.red);
                      },
                      errorBuilder: (BuildContext context, Object exception,
                          StackTrace? stackTrace) {
                        return Image.asset("images/person.png", width: 90,);
                      },
                    ),

                  Padding(
                    padding: EdgeInsets.only(
                        right: 8,
                        left: 8,
                        top: widget.film.actors[index].name.contains(" ")
                            ? 8
                            : 14,
                        bottom: widget.film.actors[index].name.contains(" ")
                            ? 8
                            : 14),
                    child: Text(
                      widget.film.actors[index].name.replaceAll(
                          " ", "\n").replaceAll("-", "\n"),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: TextStyle(fontSize: 10),
                    ),
                  )
                ],
              ),
            );
          }
      ),
    );
  }

  /// Build the youtube player.
  buildYoutubePlayer() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
      ),
    );
  }

  /// Build the description of the film.
  Padding buildDescription() {
    return Padding(
                padding: const EdgeInsets.only(left: 16, top: 8, right: 16),
                child: Text(
                  widget.film.description),
              );
  }


}
