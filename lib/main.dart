import 'dart:convert';
import 'package:Affirmations_App/favorites.dart';
import 'package:Affirmations_App/types/Affirmation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Affirmations',
      home: HomePage(
        title: 'Affirmations',
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final String title;

  HomePage({required this.title});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<Affirmation> affirmation;
  Future<String>? _randomImage;

  IconData _icon = Icons.favorite_border;

  late String _currentAffirmation;
  final _favorites = Set<String>();

  @override
  void initState() {
    super.initState();
    this.affirmation = fetchAffirmation();
    _fetchRandomImage();
  }

  /// Make an HTTP request to the affirmations API to get an affirmation
  Future<Affirmation> fetchAffirmation() async {
    final Uri url = Uri.parse('https://www.affirmations.dev/');
    final response = await http.get(url);
    Affirmation result;

    // Check the status of the http request for errors
    switch (response.statusCode) {
      case 200:
        result = Affirmation.fromJson(json.decode(response.body));
        break;
      default:
        throw Exception('Error getting affirmation from API');
    }

    // Set the favorite icon if it is an already favorite affirmation
    setState(() {
      _currentAffirmation = result.affirmation;
      _icon = _favorites.contains(_currentAffirmation)
      ? Icons.favorite
      : Icons.favorite_border;
    });

    return result;
  }

   Future<void> _fetchRandomImage() async {
    const String apiUrl = 'https://api.api-ninjas.com/v1/randomimage?category=nature';
    const String apiKey = 'gOew/3L5sijrIjdxpHmXpw==ijn4ToCAido6ivAD';

  final headers = {
    'X-Api-Key': apiKey,
    'Accept': 'application/json',
  };

  try {
    final response = await http.get(Uri.parse(apiUrl), headers: headers);

    if (response.statusCode == 200) {
      final base64Image = response.body;
      setState(() {
        _randomImage = Future.value(base64Image);
      });
    } else {
      throw Exception('Error loading random image: ${response.statusCode}');
    }
      print('Response body: ${response.body}'); 
  } catch (e) {
    throw Exception('Error loading random image: $e');
  }
}


Widget buildButtonMenu() {
  return Container(
    color: Colors.black12,
    child: ButtonBar(
      alignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        IconButton(
          icon: Icon(Icons.refresh),
          tooltip: 'Reload Affirmation',
          onPressed: () async {
            setState(() {
              _icon = Icons.favorite_border;
              _currentAffirmation = 'null';
            });
            try {
              final List<dynamic> results = await Future.wait([fetchAffirmation(), _fetchRandomImage()]);
              setState(() {
                affirmation = Future<Affirmation>.value(results[0]);
              });
            } catch (e) {
              print('Error loading affirmation or random image: $e');
            }
          },
        ),
        IconButton(
          icon: Icon(_icon),
          tooltip: 'Like current affirmation',
          onPressed: () {
            setState(() {
              if (!_favorites.contains(_currentAffirmation)) {
                _icon = Icons.favorite;
                _favorites.add(_currentAffirmation);
              } else {
                _icon = Icons.favorite_border;
                _favorites.remove(_currentAffirmation);
              }
            });
          },
        ),
        IconButton(
          icon: Icon(Icons.menu),
          tooltip: 'See liked affirmations',
          onPressed: () {
            setState(() {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FavoritesPage(_favorites)),
              ).then((value) {
                setState(() {
                  if (!_favorites.contains(_currentAffirmation)) {
                    _icon = Icons.favorite_border;
                  }
                });
              });
            });
          },
        ),
      ],
    ),
  );
}


Widget buildAffirmation() {
  return Expanded(
    child: Container(
      alignment: Alignment.center,
      padding: EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FutureBuilder<Affirmation>(
            future: affirmation,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text('Error loading affirmation: ${snapshot.error}');
              } else if (snapshot.hasData) {
                final affirmationData = snapshot.data!;
                _currentAffirmation = affirmationData.affirmation;
                return Stack(
                  children: [
                    Transform.translate(
                      offset: Offset(-1, 0),
                      child: Text(
                        affirmationData.affirmation,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 35,
                          fontWeight: FontWeight.bold,
                          foreground: Paint()
                            ..style = PaintingStyle.stroke
                            ..strokeWidth = 2.0
                            ..color = Colors.black,
                        ),
                      ),
                    ),
                    Text(
                      affirmationData.affirmation,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 35,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                );
              } else {
                return Text('No affirmation data available.');
              }
            },
          ),
        ],
      ),
    ),
  );
}
  
  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text(widget.title),
      backgroundColor: Color.fromARGB(255, 1, 206, 234),
    ),
    body: FutureBuilder<String>(
      future: _randomImage,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text('Error loading random image: ${snapshot.error}'),
          );
        } else if (snapshot.hasData) {
          final base64Image = snapshot.data!;
          final imageBytes = base64Decode(base64Image);
          return Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: MemoryImage(imageBytes),
                fit: BoxFit.cover,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  buildAffirmation(),
                  buildButtonMenu(),
                ],
              ),
            ),
          );
        } else {
          return Center(
            child: Text('No image data available.'),
          );
        }
      },
    ),
  );
}
}