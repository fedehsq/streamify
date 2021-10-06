
import 'package:streamify/DatabaseHelper.dart';

import 'Actor.dart';

class Film {
  late String filmTitle;
  late String coverImage;
  final String descriptionUri;
  final String host;
  final Map episodes = Map();
  List<Actor> actors = [];
  int favourite = 0;
  bool isVisible = true;
  String category = "";
  String quality = "";
  String genre = "";
  String backgroundImage = "";
  String episodeTitle = "";
  String episodeArrived = "";
  String fileVideoUri = "";
  String trailerUri = "";
  String description = "";
  double rating = 0;
  int arrivedMin = 0;

  Film(
      this.filmTitle,
      this.host,
      this.descriptionUri,
      this.coverImage,
      this.category,
      this.favourite,
      this.arrivedMin,
      this.episodeArrived,
    );

  // Convert a Dog into a Map. The keys must correspond to the names of the
  // columns in the database.
  Map<String, dynamic> toMap() {
    return {
      DatabaseHelper.columnFilmTitle: filmTitle,
      DatabaseHelper.columnHost: host,
      DatabaseHelper.columnDescriptionUri: descriptionUri,
      DatabaseHelper.columnCoverImage: coverImage,
      DatabaseHelper.columnCategory: category,
      DatabaseHelper.favourite: favourite,
      DatabaseHelper.arrivedMin: arrivedMin,
      DatabaseHelper.episodeArrived: episodeArrived
    };
  }
}
