import 'dart:convert';
import 'package:html/parser.dart';
import 'package:http/http.dart';
import 'package:streamify/Actor.dart';

import 'Film.dart';

mixin UriHelper {

  /// Get the http requests to the web site.
  /// Download all films information and create them as an object 'Film'.
  /// These films are that shown on the web site's homepage:
  /// - Films added today
  /// - Showcase films
  /// - Showcase films
  /// These films are added to the corresponding lists.
  Future<void> homepage(String domain, List<Film> cinemaFilms,
      List<Film> todayFilms, List<Film> todayTvSeries,
      List<Film> favourites) async {
    var filmList = await get(
        Uri.parse(domain));
    if (filmList.statusCode == 200) {
      String body = filmList.body;
      // there are films divided by 2 categories
      var nFilms = body
          .split(" Film</span>")
          .first;
      nFilms = nFilms
          .split("<span>")
          .last;
      var document = parse(filmList.body);
      _getHomePageFilms(
          document, cinemaFilms, todayFilms, favourites, int.parse(nFilms));
      _getHomePageTvSeries(document, todayTvSeries, favourites);
    }
  }

  /// Download the list of films to the cinema and the last added.
  void _getHomePageFilms(dynamic document, List<Film> cinemaFilms,
      List<Film> todayFilms, List<Film> favourites, int nFilms) {
    var elements = document
        .getElementsByClassName(
        "item movies");
    for (var elem in elements) {
      try {
        Film film = parseFilm(elem, favourites);
        nFilms-- > 0 ? cinemaFilms.add(film) : todayFilms.add(film);
      } catch (exc) {
        print("Exc downloading films list: $exc");
      }
    }
  }

  /// Extract the fields with which to build the Film.
  Film parseFilm(elem, List<Film> favourites) {
    var quality = elem
        .getElementsByClassName("quality")
        .last
        .text;
    // title of searched item
    String fTitle = elem
        .getElementsByTagName("img").first.attributes["alt"];
    // uri containing description and link of streaming
    var descriptionUri = elem
        .getElementsByTagName("a")
        .first
        .attributes["href"];
    // cover image
    var image = elem
        .getElementsByTagName("img")
        .first
        .attributes["src"];
    // there isn't info, default is unknown
    var category = descriptionUri.contains("film") ? "Film" : "Serie Tv";
    Film film = Film(
        fTitle, "gds", descriptionUri!, image!,
        category, 0, 0, fTitle);
    film.backgroundImage = image;
    film.quality = quality;
    swapFavouriteFilm(film, favourites);
    return film;
  }

  /// Download the list of last added tv series.
  _getHomePageTvSeries(dynamic document, List<Film> todayTvSeries,
      List<Film> favourites) {
    var tvSeries = document.getElementsByClassName("items")[2]
        .getElementsByClassName("poster");
    parseTvSeries(tvSeries, favourites, todayTvSeries);
  }

  /// Get the http requests to the web site.
  /// Download all films information and create them as an object 'Film'.
  /// These films are that shown on the web site's top page:
  /// - top films added
  /// - top tv series
  /// These films are added to the corresponding lists.
  Future<void> topPage(String domain, List<Film> topFilms,
      List<Film> topTvSeries,
      List<Film> favourites) async {
    var filmList = await get(
        Uri.parse("$domain/trending/?get=movies"));
    var tvSeries = await get(
        Uri.parse("$domain/trending/?get=tv"));
    if (filmList.statusCode == 200) {
      var document = parse(filmList.body);
      _getTopPageFilms(document, topFilms, favourites);
    }
    if (tvSeries.statusCode == 200) {
      var document = parse(tvSeries.body);
      _getTopPageTvSeries(document, topTvSeries, favourites);
    }
  }

  /// Download the list of 25 top films.
  void _getTopPageFilms(dynamic document, List<Film> topFilms, List<Film> favourites) {
    var elements = document
        .getElementsByClassName(
        "item movies");
    for (var elem in elements) {
      try {
        Film film = parseFilm(elem, favourites);
        topFilms.add(film);
      } catch (exc) {
        print("Exc downloading films list: $exc");
      }
    }
  }

  /// Download the list of 25 tv series.
  _getTopPageTvSeries(dynamic document, List<Film> topTvSeries,
      List<Film> favourites) {
    var tvSeries = document.getElementsByClassName("items").first
        .getElementsByClassName("poster");
    parseTvSeries(tvSeries, favourites, topTvSeries);
  }

  /// Extract the fields with which to build the tv series items.
  void parseTvSeries(tvSeries, List<Film> favourites, List<Film> tvSeries_) {
    for (var poster in tvSeries) {
      try {
        var descriptionUri = poster
            .getElementsByTagName("a")
            .first
            .attributes["href"];
        var image = poster
            .getElementsByTagName("img")
            .first
            .attributes["src"];
        var title = poster
            .getElementsByTagName("img")
            .first
            .attributes["alt"];
        /*
        var rank = poster
            .getElementsByClassName("rating")
            .first
            .text;
         */
        Film film = Film(
            title!, "gds", descriptionUri!, image!,
            "Serie Tv", 0, 0, title);
        film.rating = 0.0;
        swapFavouriteFilm(film, favourites);
        tvSeries_.add(film);
      } catch (exc) {
        print(exc);
      }
    }
  }

  /// Replace the current favourite film with the updated one after a web reloading.
  void swapFavouriteFilm(Film film, List<Film> favourites) {
    for (int i = 0; i < favourites.length; i++) {
      if (film.filmTitle == favourites[i].filmTitle) {
        film.favourite = 1;
        favourites.removeAt(i);
        favourites.insert(i, film);
        break;
      }
    }
  }

  /// Download the description of the film from uri
  Future<void> downloadDescription(Film film) async {
    // get the film description
    switch (film.host) {
      case "gds":
        switch (film.category) {
          case "Film" :
            await _downloadFilmDescription(film);
            break;
          case "Serie Tv" :
            await _downloadTvSeriesDescription(film);
            break;
        }
    }
  }

  /// Try to get the quality information about film from the html page
  /// parsing the class className
  String? _getQuality(dynamic html, Film film, String className) {
    String? quality;
    try {
      quality = html
          .getElementsByClassName(className)
          .last
          .text;
      return quality;
    } catch (exc) {
      print("exc on ${film.filmTitle}: $exc => quality");
    }
  }

  /// Extract the element from the triple.
  _getElementByClassTagAttribute(dynamic html, String className, String tagName,
      String attributeName) {
    String? element;
    try {
      element = html
          .getElementsByClassName(className)
          .last
          .getElementsByTagName(tagName)
          .first
          .attributes[attributeName];
      return element;
    } catch (exc) {
      throw exc;
    }
  }

  /// Get the element from html.
  _getElement(dynamic html, Film film, String className, String tagName,
      String attributeName, String errorMessage) {
    String? element;
    try {
      element = _getElementByClassTagAttribute(html, className, tagName, attributeName);
      return element;
    } catch (exc) {
      print("exc on ${film.filmTitle}: $exc => $errorMessage");
    }
  }

  /// Try to get the primary image of film from the html page
  /// parsing the class className.
  String? _getCoverImage(dynamic html, Film film, String className, String tagName,
      String attributeName) {
    return _getElement(html, film, className, tagName, attributeName, "cover image");
  }

  /// Try to get the background image of film from the html page
  /// parsing the class className.
  String? _getBackgroundImage(dynamic html, Film film, String className, String tagName,
      String attributeName) {
    return _getElement(html, film, className, tagName, attributeName, "background image");
  }

  /// Try to get the trailer of film from the html page
  /// parsing the class className.
  String? _getTrailerUri(dynamic html, Film film, String className, String tagName,
      String attributeName) {
    return _getElement(html, film, className, tagName, attributeName, "trailer uri");
  }

  /// Try to get the cast of film from the html page.
  List<Actor>? _getCast(dynamic html, Film film) {
    List<Actor> actorList = [];
    try {
     var actors = html
          .getElementsByClassName("person");
      for (var person in actors) {
        var primaryName = person
            .getElementsByClassName("name")
            .first
            .text;
        var picture = person
            .getElementsByTagName("img")
            .first
            .attributes["src"];
        actorList.add(Actor(primaryName, picture));
      }
      return actorList;
    } catch (exc) {
      print("exc on ${film.filmTitle}: $exc => cast");
    }
  }

  /// Try to get the genre of film from the html page.
  String? _getGenres(dynamic html, Film film, String className, String tagName) {
    try {
      String genre = "";
      var genres = html
          .getElementsByClassName(className)
          .last
          .getElementsByTagName(tagName);
      for (var g in genres) {
        genre += g.text + " - ";
      }
      genre = genre.substring(0, genre.length - 2);
      return genre;
    } catch (exc) {
      print("exc on ${film.filmTitle}: $exc => genre");
    }
  }

  /// Try to get the description of film from the html page.
  String? _getDescription(dynamic html, Film film, String className) {
    // get the film's plot
    try {
      String? description = html
          .getElementsByClassName(className)
          .last
          .text;
      return description;
    } catch (exc) {
      print("exc on ${film.filmTitle}: $exc => description");
    }
  }

  /// Try to get the rating of film from the html page.
  String? _getRank(dynamic html, Film film, String className, String className1) {
    String? rating = "";
    // get rank (IMDB or TMDB)
    try {
      rating = html
          .getElementsByClassName(className)
          .last
          .getElementsByClassName(className1)[1].text;
      rating = rating!
          .split("IMDb")
          .last
          .split(" ")
          .first;
      if (!rating.contains("N")) {
        return rating;
      }
    } catch (exc) {
      print("exc on ${film.filmTitle}: $exc => IMDB rank");
    }
    if (rating!.isEmpty || rating.contains("N")) {
      try {
        rating = html
            .getElementsByClassName(className)
            .last
            .getElementsByClassName(className1)[2].text;
        rating = rating!
            .split("TMDb")
            .last
            .split(" ")
            .first;
        return rating;
      } catch (exc) {
        print("exc on ${film.filmTitle}: $exc => TMDB rank");
      }
    }
  }

  /// Try to get the file video uri and decrypt it from the html page.
  List<int>? _getVideo(dynamic html, Film film) {
    List<int> res = [];
    var fileVideoUri = html.body!.text.split('["')[1];
    fileVideoUri = fileVideoUri
        .split('"]')
        .first;
    // the method above is valid for only one link
    try {
      res = base64.decode(base64.normalize(fileVideoUri));
      return res;
    } catch (exc) {
      print("exc on ${film.filmTitle}: $exc => file video uri");
      fileVideoUri = fileVideoUri
          .split('",')
          .first;
      res = base64.decode(base64.normalize(fileVideoUri));
      return res;
    }
  }

  /// Get the season and the episodes of tv series.
  void _getTvSeriesEpisodes(dynamic html, Film film) {
    var seasons = html.getElementsByClassName("episodios");
    for (int j = 0; j < seasons.length; j++) {
      // key is the episode title, the value is [episode, minArrived, toContinue]
      Map eps = {};
      var episodes = seasons[j].getElementsByClassName("episodiotitle");
      for (int i = 0; i < episodes.length; i++) {
        var episodeUri = episodes[i]
            .getElementsByTagName("a")
            .first
            .attributes["href"];
        var episodeTitle = episodes[i]
            .getElementsByTagName("a")
            .first
            .text;
        eps[episodeTitle] = episodeUri;
      }
      film.episodes["Stagione ${j + 1}"] = eps;
    }
  }

  /*
  googleQueryForTrickyTrailer(Film film) async {
    try {
      var googleQuery = await get(Uri.parse(
          "https://www.google.com/search?q=${film.filmTitle} trailer"));
      var result = googleQuery.body.toString();
      var idVideo = result.split("https://www.youtube.com/watch?v=")[1]
          .split('"')
          .first
          .split("</")
          .first;
      var trailerUri = "https://www.youtube.com/watch?v=$idVideo";
    } catch (exc) {
      print("exc on ${film.filmTitle}: $exc => trailer");
    }
  }

  googleQueryForTrickyImdbRank(Film film) async {
    // get IMDB rank
    try {
      var googleQuery = await get(Uri.parse(
          "https://www.google.com/search?q=${film.filmTitle} imdb"));
      var result = googleQuery.body.toString();
      var imdbFilmId = result.split("https://www.imdb.com/title/")[1].split("/").first;
      var imdbFilm = "https://www.imdb.com/title/$imdbFilmId";

      var imdbQuery = await get(Uri.parse(imdbFilm));
      result = imdbQuery.body.toString();
      var rating = result.split('"ratingValue":')[2].split("}").first;
    } catch (exc) {
      print("exc on ${film.filmTitle}: $exc => IMDB rank");
    }
  }

  Future<String?> getImdbRank(Film film) async {
    // get IMDB rank
    try {
      var googleQuery = await get(Uri.parse(
          "https://www.google.com/search?q=${film.filmTitle.replaceAll("&", "and")} imdb"));
      print(googleQuery.statusCode);
      var result = googleQuery.body.toString();
      var imdbFilmId = result.split("https://www.imdb.com/title/")[1].split("/").first;
      var imdbFilm = "https://www.imdb.com/title/$imdbFilmId";
      var imdbQuery = await get(Uri.parse(imdbFilm));
      result = imdbQuery.body.toString();
      var ratings = result.split('"ratingValue":');
      var rating = ratings.length > 2 ? ratings[2].split("}").first : ratings[1].split("}").first;
      return rating;
    } catch (exc) {
      print("exc on ${film.filmTitle}: $exc => IMDB rank");
      return film.rating.toString();
    }
  }
   */

  /// Download the description of the film from the website.
  Future<void> _downloadFilmDescription(Film film) async {
    final uriFilmDescription = await get(Uri.parse(film.descriptionUri));
    if (uriFilmDescription.statusCode == 200) {
      // reference to webpage
      var document = parse(uriFilmDescription.body.toString());
      // list of actors
      List<Actor> actorList = _getCast(document, film) ?? [];
      // background image of the film
      String? backgroundImage = _getBackgroundImage(document, film, "galeria animation-2", "img", "src") ?? "";
      // film's trailer
      String? trailerUri = _getTrailerUri(document, film, "videobox", "iframe", "src") ?? "";
      // film quality
      String? quality = _getQuality(document, film, "qualityx") ?? "";
      // primary image of the film
      String? coverImage = _getCoverImage(document, film, "poster", "img", "src") ?? "";
      String? genre = _getGenres(document, film, "sgeneros", "a") ?? "";
      // film's plot
      String? description = _getDescription(document, film, "sbox fixidtab") ?? "";
      // film's rank
      String? rating = _getRank(document, film, "sbox fixidtab", "custom_fields") ?? "0";
      // film!
      List<int>? fileVideoUri = _getVideo(document, film) ?? [];


      film.fileVideoUri = utf8.decode(fileVideoUri);
      film.quality = quality;
      //film.episodeTitle = film.filmTitle;
      film.coverImage = coverImage;
      film.backgroundImage = backgroundImage;
      film.genre = genre;
      film.trailerUri = trailerUri;
      film.actors = actorList;
      try {
        film.rating = double.parse(rating);
      } catch (exc) {
        print("$exc: => ${film.filmTitle}: $rating");
      }
      film.description = description
          .split("titolo")
          .first;
      film.description = film.description
          .split("Streaming")
          .last
          .trim();
    }
  }

  /// Download the description of the tv series from the website.
  Future<void> _downloadTvSeriesDescription(Film film) async {
    final uriFilmDescription = await get(Uri.parse(film.descriptionUri));
    if (uriFilmDescription.statusCode == 200) {
      var document = parse(uriFilmDescription.body.toString());

      // list of actors
      List<Actor> actorList = _getCast(document, film) ?? [];
      // background image of the film
      String? backgroundImage = _getBackgroundImage(document, film, "galeria", "img", "src") ?? "";
      // film's trailer
      String? trailerUri = _getTrailerUri(document, film, "videobox", "iframe", "src") ?? "";
      // primary image of the film
      var primaryImage = _getCoverImage(document, film, "poster", "img", "src") ?? "";
      // film's genres
      var genre = _getGenres(document, film, "sgeneros", "a")?? "";
      // film's plot
      var description = "";
      try {
        description = document.getElementsByClassName("sbox fixidtab")[3]
            .text
            .split("Trama")
            .last;
        description = description
            .split("titolo")
            .first;
      } catch (exc) {
        print("exc on ${film.filmTitle}: $exc => description");
      }

      //film.episodeTitle = film.filmTitle;
      film.coverImage = primaryImage;
      film.backgroundImage = backgroundImage;
      film.genre = genre;
      film.trailerUri = trailerUri;
      film.actors = actorList;
      //film.rating = rating.isEmpty ? 0 : double.parse(rating);
      _getTvSeriesEpisodes(document, film);
      film.description = description
          .split("titolo")
          .first;
      film.description = film.description
          .split("Streaming")
          .last
          .trim();
    }
  }
}