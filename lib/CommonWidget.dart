import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'Film.dart';

mixin CommonWidget {

  /// Display a loading text with animations.
  Center buildAnimatedText(String text) {
    return Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: DefaultTextStyle(
            style: const TextStyle(
              fontFamily: 'DotGothic',
            ),
            child: AnimatedTextKit(
              animatedTexts: [
                TypewriterAnimatedText(text,
                    speed: Duration(milliseconds: 100)
                ),
              ],
            ),
          ),
        )
    );
  }

  /// Build the row containing the stars.
  Row buildStarsRow(Film film) {
    return Row(
      children: [
        film.rating > 2
            ? Icon(Icons.star, color: Colors.yellow, size: 16)
            : Icon(Icons.star_border, color: Colors.yellow, size: 16),
        film.rating > 4
            ? Icon(Icons.star, color: Colors.yellow, size: 16)
            : Icon(Icons.star_border, color: Colors.yellow, size: 16),
        film.rating >= 6
            ? Icon(Icons.star, color: Colors.yellow, size: 16)
            : Icon(Icons.star_border, color: Colors.yellow, size: 16),
        film.rating > 7 && film.rating < 8
            ? Icon(Icons.star_half, color: Colors.yellow, size: 16)
            : film.rating >= 8
            ? Icon(Icons.star, color: Colors.yellow, size: 16)
            : Icon(Icons.star_border, color: Colors.yellow, size: 16),
        film.rating > 8.5
            ? Icon(Icons.star_half, color: Colors.yellow, size: 16)
            : Icon(Icons.star_border, color: Colors.yellow, size: 16),
      ],
    );
  }

  /// Open a dialog describing the film.
  Future<void> showDescriptionDialog(Film film, BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(film.filmTitle),
          content: SingleChildScrollView(
            child: Text(film.description),
          ),
          actions: <Widget>[
            TextButton(
                child: const Text('Chiudi'),
                onPressed: () => Navigator.of(context).pop()
            ),
          ],
        );
      },
    );
  }

}