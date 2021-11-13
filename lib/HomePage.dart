import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:streamify/CommonWidget.dart';
import 'package:streamify/EpSelector.dart';
import 'package:streamify/FilmPresentation.dart';
import 'package:streamify/SearchScreen.dart';

import 'DatabaseHelper.dart';
import 'Film.dart';
import 'VideoPlayer.dart';
import 'UriFunction.dart';

class HomePage extends StatefulWidget {
  final String host;
  const HomePage({Key? key, required this.host}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with UriHelper, CommonWidget {
  // Indicate if user is writing for search a film
  bool _searchMode = false;
  // Indicate if the items must be downloaded from network
  // Useful for not reloading the web site while scrolling the films list
  // when already downloaded
  bool _downloadHomePage = true;
  bool _downloadTopFilmTvSeries = true;
  // Title to search
  String _title = "";
  // Current _page of the bottom button bar
  int _page = 0;
  // Controller for search textview
  late TextEditingController _searchController;
  // Page controller of the bottom bottom button bar initialized on _page 0
  final PageController _pageController = PageController(initialPage: 0);
  // Last film added on the web site
  final List<Film> _todayFilms = [];
  // Last film added on the web site
  final List<Film> _todayTvSeries = [];
  // Showcase films on the web site
  final List<Film> _cinemaFilms = [];
  // User's favourite films
  final List<Film> _favouritesFilms = [];
  // User's started films
  final List<Film> _startedFilms = [];
  // User's started films
  final List<Film> _topFilms = [];
  // User's started films
  final List<Film> _topTvSeries = [];
  // reference to singleton class that manages the database
  final dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    _searchController = TextEditingController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: _buildPageView(),
      bottomNavigationBar: _buildBottomButtonBar(),
    );
  }

  /// --------------------------------------------------------------------------
  /// -------------------------------- APP BAR ---------------------------------
  /// --------------------------------------------------------------------------

  /// The head of the scaffold: an AppBar containing the _title
  /// and the search button.
  AppBar _buildAppBar() {
    return AppBar(
      // _searchMode is enabled when user tap on the search icon:
      // in this case the app _title is replaced from a search TextField.
      // When the research is completed, disable the search mode and enable
      // the _fromNetwork mode
      backgroundColor: Colors.black,
      title: _searchMode ? TextField(
        autofocus: true,
        onEditingComplete: () async {
          _title = _searchController.text;
          _searchController.text = "";
          _searchMode = false;
          final films = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) =>
                  SearchScreen(title: _title, domain: widget.host)));
          // the result is composed by [favourites, started]
          for (Film film in films[0]) {
            if (!_favouritesFilms.contains(film)) {
              _favouritesFilms.add(film);
            }
          }
          for (Film film in films[1]) {
            if (!_startedFilms.contains(film)) {
              _startedFilms.add(film);
            }
          }
          for (Film film in films[0]) {
            await dbHelper.insert(film);
          }
          for (Film film in films[1]) {
            await dbHelper.insert(film);
          }
          setState(() {});
        },
        cursorColor: Colors.white,
        controller: _searchController,
        decoration: InputDecoration(
            hintText: 'Cerca...'
        ),
        // Display app _title when the search mode is disabled
      ) : Text('Streamify'),
      actions: [
        // When tap on search icon, enable the search mode
        if (!_searchMode)
          IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _searchMode = true;
                  _downloadHomePage = false;
                });
              })
      ],
      // Display a left arrow to exit from search mode
      leading: _searchMode ?
      IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () {
          setState(() {
            _searchMode = false;
            _title = "";
          });
        },) : null,
    );
  }

  /// --------------------------------------------------------------------------
  /// ---------------------------------- BODY ----------------------------------
  /// --------------------------------------------------------------------------

  /// The body of the scaffold: a PageView composed by 3 pages.
  PageView _buildPageView() {
    return PageView(
      scrollDirection: Axis.horizontal,
      controller: _pageController,
      // Needed to change the bottom button bar icons
      onPageChanged: (_page) =>
          setState(() {
            this._page = _page;
          }),
      children: [
        // first _page
        _buildHomePage(),
        // second _page
        _buildFavouritesPage(),
        // third _page
        _buildTopPage()
      ],
    );
  }

  /// Build the homepage, the first _page of _page view.
  /// Download films from internet on first access.
  /// The first _page (home icon) shows the film list.
  _buildHomePage() {
    return _downloadHomePage ? _getHomePageFilmsFromNetwork() : _buildHomePageFilmView();
  }

  /// Build the top page, the last _page of _page view.
  /// Download films from internet on first access.
  /// The last _page (menu icon) shows the film list.
  _buildTopPage() {
    return _downloadTopFilmTvSeries ? _getTopFilmsFromNetwork() : _buildTopPageFilmView();
  }

  /// Start the research on the web for the homepeage.
  /// Display an indicator until the films information are downloaded.
  FutureBuilder<void> _getHomePageFilmsFromNetwork() {
    return FutureBuilder<void>(
        future: _getHomePage(),
        builder: (context, AsyncSnapshot<void> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return _buildHomePageFilmView();
          } else {
            return Center(child: CircularProgressIndicator(
                      strokeWidth: 1, color: Colors.red));
          }
        }
    );
  }

  /// Start the research on the web for the top items.
  /// Display an indicator until the films information are downloaded.
  FutureBuilder<void> _getTopFilmsFromNetwork() {
    return FutureBuilder<void>(
        future: _getTopPage(),
        builder: (context, AsyncSnapshot<void> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return _buildTopPageFilmView();
          } else {
            return Center(child: CircularProgressIndicator(
                      strokeWidth: 1, color: Colors.red));
          }
        }
    );
  }

  /// Build the 3 lists in the first _page.
  /// Vertical list containing three or four horizontal lists:
  /// Horizontal Lists of film: '_started', '_cinemaFilms', _todayFilms', '_todayTvSeries'
  _buildHomePageFilmView() {
    /*
    return RefreshIndicator(
      onRefresh: () async {
        _fromNetwork = true;
        setState(() {});
      },
      child:
     */
       return ListView(
        children: [
          // First image on the top:
          // Check empty case for film and tv series: in that case download
          // the info, otherwise display it
          _cinemaFilms.first.description.isEmpty ?
          _downloadBigItem() : _buildBigItem(),
          if (_startedFilms.isNotEmpty)
            _buildTextPadding("Continua a guardare"),
          if (_startedFilms.isNotEmpty)
            _buildFilmListContainer(_startedFilms, false),
          _buildTextPadding("In sala"),
          _buildFilmListContainer(_cinemaFilms, true),
          _buildTextPadding("Ultimi film inseriti"),
          _buildFilmListContainer(_todayFilms, false),
          _buildTextPadding("Ultime serie tv inserite"),
          _buildFilmListContainer(_todayTvSeries, false)
        ],
      //),
    );
  }

  /// Build the 2 lists in the third _page.
  /// Vertical list containing two horizontal lists:
  /// Horizontal Lists of film: '_topFilms', _topTvSeries'
  _buildTopPageFilmView() {
       return ListView(
        children: [
          _buildTextPadding("Top 25 film"),
          _buildFilmListContainer(_topFilms, false),
          _buildTextPadding("Top 25 serie tv"),
          _buildFilmListContainer(_topTvSeries, false)
        ],
      //),
    );
  }

  /// Build a Text widget inside a Padding widget.
  Padding _buildTextPadding(String text) {
    return Padding(
          padding: const EdgeInsets.only(top: 32, left: 16.0),
          child: Text(text,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
        );
  }

  /// Build the layout of the horizontal List of film:
  /// '_cinemaFilms', _todayFilms', '_todayTvSeries'
  Container _buildFilmListContainer(List<Film> films, bool skipFirst) {
    return Container(
          height: 275,
          child: ListView.builder(
              padding: EdgeInsets.only(left: 8),
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              itemCount: films.length,
              itemBuilder: (context, index) =>
              // hide the big item from its list because it is already on the top
              skipFirst && index == 0 ?  Container() : _buildFilmCard(index, films),
        )
    );
  }

  /// Download the description of the first film.
  _downloadBigItem() {
    return FutureBuilder<void>(
        future: downloadDescription(_cinemaFilms.first),
        builder: (context, AsyncSnapshot<void> snapshot) {
          return snapshot.connectionState == ConnectionState.done
              ? _buildBigItem() : Center(
              child: CircularProgressIndicator(
                      strokeWidth: 1, color: Colors.red));
        }
    );
  }

  /// Build the showcase film layout (first big image).
  Column _buildBigItem() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(_cinemaFilms.first.filmTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Palette Mosaic', fontSize: 18)),
        ),
        Stack(
            alignment: Alignment.center,
            children: [
              Image.network(_cinemaFilms.first.backgroundImage,
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
              ),
              IconButton(
                  icon: Icon(Icons.play_arrow),
                  onPressed: () async {
                    await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                            _cinemaFilms.first.category == "Serie Tv"
                                ? EpSelector(film: _cinemaFilms.first)
                                : VideoPlayer(film: _cinemaFilms.first))
                    );
                    if (!_startedFilms.contains(_cinemaFilms.first) &&
                        _cinemaFilms.first.arrivedMin != 0) {
                      _startedFilms.add(_cinemaFilms.first);
                    }
                    setState(() {});
                  }
              ),
            ]
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Center(child: Text(_cinemaFilms.first.genre,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),),),
        ),
        _buildBigFilmInfoRow(_cinemaFilms.first),
      ],
    );
  }

  /// Build the container containing the card containing the film.
  _buildFilmCard(int index, List<Film> films) {
    return films[index].description.isEmpty ? _downloadFilmInfo(
        films[index], films) : _buildFilm(
        films[index], films);
  }

  /// Downloaded the descriptions (url, description, ranks..) of the film.
  /// Display an indicator until the download is completed.
  /// Then display the the card.
  _downloadFilmInfo(Film film, List<Film> films) {
    return FutureBuilder<void>(
        future: downloadDescription(film),
        builder: (context, AsyncSnapshot<void> snapshot) {
          return snapshot.connectionState == ConnectionState.done ?
          _buildFilm(film, films) :
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: CircularProgressIndicator(
                        strokeWidth: 1, color: Colors.red),
            ),
          );
        }
    );
  }

  /// Container with the Card containing the film.
  _buildFilm(Film film, List<Film> filmList) {
    return AnimatedOpacity(
      duration: Duration(milliseconds: 500),
      opacity: _page == 1 && !film.isVisible ? 0.0 : 1,
      child: Container(
          height: filmList == _favouritesFilms ? 340 : 275,
          width: filmList == _favouritesFilms ? 192 : 150,
          child:
          Stack(
              alignment: Alignment.topLeft,
              children: [
                Card(
                    clipBehavior: Clip.hardEdge,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: InkWell(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (BuildContext context) =>
                              filmList == _startedFilms ? VideoPlayer(
                                  film: film) :
                              film.category == "Film" ? VideoPlayer(
                                  film: film) : EpSelector(film: film),
                            ),
                          );
                          if (!_startedFilms.contains(film) && film.arrivedMin != 0) {
                            _startedFilms.add(film);
                            setState(() {});
                          }
                        },
                        child: Column(
                            children: [
                              Image.network(film.coverImage,
                                  loadingBuilder: (BuildContext context,
                                      Widget child,
                                      ImageChunkEvent? loadingProgress) {
                                    if (loadingProgress == null) {
                                      return child;
                                    }
                                    return CircularProgressIndicator(
                                        strokeWidth: 1, color: Colors.red);
                                  }),
                              // display rank rank
                              filmList == _startedFilms ? _buildDeleteChooserRow(film) : _buildInfoLoveRow(film)                          ]
                        )
                      // cover image),
                    )),
                if (film.quality.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      color: Colors.red,
                      width: film.quality.length > 3 ? 60 : 40,
                      height: 20,
                      child: Center(child: Text(film.quality)),
                    ),
                  ),
              ])
      ),
    );
  }

  /// Build the row containing the delete button and the episode chooser button.
  /// This builds occurs in the _arrivedFilms list
  _buildDeleteChooserRow(Film film) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        IconButton(
          icon: Icon(Icons.highlight_remove),
          onPressed: () async {
            _startedFilms.remove(film);
            film.arrivedMin = 0;
            // remove from db if the film is neither in favourites!
            if (!_favouritesFilms.contains(film)) {
              await dbHelper.delete(film.filmTitle);
            }
            setState(() {});
          },
        ),
        if (film.category == "Serie Tv")
          IconButton(onPressed: () => Navigator.push (
            context,
            MaterialPageRoute (
              builder: (BuildContext context) => EpSelector(film: film),
            ),
          ),
          icon: Icon(Icons.list))
      ],
    );
  }

  /*
  FutureBuilder<String?> _downloadImdbRank(Film film) {
    return FutureBuilder<String?>(
        future: getImdbRank(film),
        builder: (context,
            AsyncSnapshot<String?> snapshot) {
          if (snapshot.hasData) {
            film.rating = double.parse(snapshot.data ?? "6");
            return film == _cinemaFilms.first ? _buildShowCaseInfoRow(
                _cinemaFilms.first) : _buildStdInfoRow(film);
          } else {
            return Padding(
              padding: const EdgeInsets.only(top: 16, right: 48, left: 48),
              child: CircularProgressIndicator(
                  strokeWidth: 1, color: Colors.red),
            );
          }
        });
  }

   */

  /// Build the bottom row of the card:
  /// It displays imdb ranks, and an icon with the film description.
  _buildBigFilmInfoRow(Film film) {
    return ListTile(
      trailing:
      _buildInfoLoveRow(film),
      title: Text(
          film.rating == 0 ? " N.A" : "Rating: ${film.rating}"),
      subtitle: buildStarsRow(film),
    );
  }

  /*
  /// Build the bottom row of the card:
  /// It displays imdb ranks, and an icon with the film description.
  _buildStdInfoRow(Film film) {
    return _buildInfoLoveButtonsRow(film);
  }

   */

  /// Build the row containing the favourite button and the info button.
  Row _buildInfoLoveRow(Film film) {
    return Row(
      mainAxisSize: film == _cinemaFilms.first ? MainAxisSize.min : MainAxisSize
          .max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Film description icon
        IconButton(icon: Icon(Icons.info),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (BuildContext context) =>
                      FilmPresentation(film: film),
                ),
              );
              if (film.favourite == 0) {
                film.isVisible = false;
              } else {
                film.isVisible = true;
                if (!_favouritesFilms.contains(film)) {
                  _favouritesFilms.add(film);
                  await dbHelper.insert(film);
                }
              }
              setState(() {});
              if (film.favourite == 0 &&  _favouritesFilms.contains(film)) {
                Future.delayed(const Duration(milliseconds: 500), () async {
                  _favouritesFilms.remove(film);
                  if (!_startedFilms.contains(film)) {
                    await dbHelper.delete(film.filmTitle);
                  }
                  setState((){});
                });
              }
            }),
        // Favourite icon
        IconButton(icon: film.favourite == 1
            ? Icon(Icons.favorite, color: Colors.red)
            : Icon(Icons.favorite_border),
          // Add/remove the current film in/from favouriteFilms
          onPressed: () async {
            film.favourite = film.favourite == 0 ? 1 : 0;
            if (film.favourite == 0) {
              film.isVisible = false;
            } else {
              film.isVisible = true;
              _favouritesFilms.add(film);
              await dbHelper.insert(film);
            }
            setState(() {});
            if (film.favourite == 0) {
              Future.delayed(const Duration(milliseconds: 500), () async {
                _favouritesFilms.remove(film);
                if (!_startedFilms.contains(film)) {
                  await dbHelper.delete(film.filmTitle);
                }
                setState(() {});
              });
            }
          },
        ),
      ],
    );
  }


  /// Asynchronous function researching on the homepage of the domain.
  Future<void> _getHomePage() async {
    // open the db
    List<Film> dbFilms = await dbHelper.getFilms();
    for (Film film in dbFilms) {
      if (film.favourite == 1) {
        _favouritesFilms.add(film);
      }
      if (film.arrivedMin != 0) {
        film.fileVideoUri = film.episodeArrived;
        _startedFilms.add(film);
      }
    }
    await homepage(widget.host, _cinemaFilms, _todayFilms, _todayTvSeries, _favouritesFilms);
    _downloadHomePage = false;
  }

  /// Asynchronous function researching on the top page of the domain.
  Future<void> _getTopPage() async {
    await topPage(widget.host, _topFilms, _topTvSeries, _favouritesFilms);
    _downloadTopFilmTvSeries = false;
  }

  /// Build the favourites _page, the second _page of _page view.
  _buildFavouritesPage() {
    return ListView.builder(
      itemCount: _favouritesFilms.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Align(child:_buildFilmCard(index, _favouritesFilms)),
        );
      });
  }

  /// --------------------------------------------------------------------------
  /// --------------------------- BOTTOM BUTTON BAR ----------------------------
  /// --------------------------------------------------------------------------

  /// Build the bottom navigation bar showing the 3 sections available.
  ButtonBar _buildBottomButtonBar() {
    return ButtonBar(
        alignment: MainAxisAlignment.spaceAround,
        children: [
          // Display filled icon when the _page is selected
          _buildIconButton(Icons.home, Icons.home_outlined, 0),
          // Display filled icon when the _page is selected
          _buildIconButton(Icons.favorite, Icons.favorite_border, 1),
          // Display filled icon when the _page is selected
          _buildIconButton(Icons.playlist_add_check, Icons.list, 2),
        ]);
  }

  /// Display 'selected' icon when the 'expectedPage is selected
  /// otherwise display 'notSelected' icon.
  /// Pressing on the icon, _page controller jump to this _page.
  IconButton _buildIconButton(IconData selected, IconData notSelected,
      int expectedPage) {
    return IconButton(
        icon: _page == expectedPage ? Icon(selected) :
        Icon(notSelected),
        // On tap to the icon jump to indicated _page
        onPressed: () =>
            setState(() {
              _pageController.jumpToPage(expectedPage);
            }));
  }
}