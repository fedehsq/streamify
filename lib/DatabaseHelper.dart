import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'Film.dart';

class DatabaseHelper {

  static final _databaseName = "film_database.db";
  static final _databaseVersion = 1;

  static final table = 'films';

  static final columnFilmTitle = 'film_title';
  static final columnHost = 'host';
  static final columnDescriptionUri = 'description_uri';
  static final columnCoverImage = 'cover_image';
  static final columnCategory = 'category';
  static final favourite = 'favourite';
  static final arrivedMin = 'arrived_min';
  static final episodeArrived = 'episode_arrived';

  // make this a singleton class
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // only have a single app-wide reference to the database
  static late Database _database;
  Future<Database> get database async {
    _database = await _initDatabase();
    return _database;
  }

  // this opens the database (and creates it if it doesn't exist)
  _initDatabase() async {
    return openDatabase(
        // Set the path to the database. Note: Using the `join` function from the
        // `path` package is best practice to ensure the path is correctly
        // constructed for each platform.
        join(await getDatabasesPath(), _databaseName),
        // When the database is first created, create a table to store dogs.
        onCreate: (db, version) {
          // Run the CREATE TABLE statement on the database.
          return db.execute('''
          CREATE TABLE $table (
            $columnFilmTitle TEXT PRIMARY KEY,
            $columnHost TEXT NOT NULL,
            $columnDescriptionUri TEXT NOT NULL,
            $columnCoverImage TEXT NOT NULL,
            $columnCategory TEXT NOT NULL,
            $favourite INTEGER NOT NULL,
            $arrivedMin INTEGER NOT NULL,
            $episodeArrived TEXT NOT NULL
          )
          ''');
        },
        // Set the version. This executes the onCreate function and provides a
        // path to perform database upgrades and downgrades.
        version: _databaseVersion,
      );
  }

  // Helper methods

  // Inserts a row in the database where each key in the Map is a column name
  // and the value is the column value. The return value is the id of the
  // inserted row.
  Future<void> insert(Film film) async {
    Database db = await instance.database;
    await db.insert(
      table,
      film.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // All of the rows are returned as a list of maps, where each map is
  // a key-value list of columns.
  Future<List<Film>> getFilms() async {
    Database db = await instance.database;
    // Query the table for all The Dogs.
    final List<Map<String, dynamic>> maps = await db.query(table);

    // Convert the List<Map<String, dynamic> into a List<Film>.
    return List.generate(maps.length, (i) {
      return Film(
        maps[i][columnFilmTitle],
        maps[i][columnHost],
        maps[i][columnDescriptionUri],
        maps[i][columnCoverImage],
        maps[i][columnCategory],
        maps[i][favourite],
        maps[i][arrivedMin],
        maps[i][episodeArrived],
      );
    });
  }


  // Deletes the row specified by the id. The number of affected rows is
  // returned. This should be 1 as long as the row exists.
  Future<int> delete(String title) async {
    Database db = await instance.database;
    return await db.delete(table, where: '$columnFilmTitle = ?', whereArgs: [title]);
  }
}