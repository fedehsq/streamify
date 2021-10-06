import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart';
import 'package:streamify/CommonWidget.dart';
import 'package:streamify/HomePage.dart';

const SOURCE = "https://docs.google.com/document/d/1Kh0ZhzV62M8WrWDswS5G4zHN7is8UoJg-_Xv3D3oG9w/";

class SourceSearch extends StatefulWidget{
  const SourceSearch({Key? key}) : super(key: key);

  @override
  _SourceSearchState createState() => _SourceSearchState();
}

class _SourceSearchState extends State<SourceSearch> with CommonWidget {

  /// Connect to document for extracting domain uri.
  @override
  Widget build(BuildContext context) =>
      FutureBuilder<String>(
          future: _getHost(),
          builder: (context, AsyncSnapshot<String> snapshot) {
            if (snapshot.hasData) {
              return HomePage(host: utf8.decode(base64.decode(base64.normalize(snapshot.data ?? ""))));
            } else {
              return buildAnimatedText("Attendi...");
            }
          }
      );

  Future<String> _getHost() async {
    final response = await get(Uri.parse(SOURCE));
    if (response.statusCode == 200) {
      var document = parse(response.body.toString());
      String host = document
          .getElementsByTagName("title")
          .first
          .text
          .split(" - Documenti Google")
          .first;
      return host;
    } else {
      print(response.statusCode);
      return "";
    }
  }
}
