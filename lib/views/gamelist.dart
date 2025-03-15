import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:battleships/game.dart';
import 'package:battleships/views/gameview.dart';
import 'package:battleships/views/gameplayview.dart';
import 'package:battleships/views/login.dart';

class GameListView extends StatefulWidget {
  final String username;
  final String accessToken;

  GameListView({required this.username, required this.accessToken});

  @override
  _GameListViewState createState() => _GameListViewState();
}

class _GameListViewState extends State<GameListView> {
  late Future<List<Game>> _games;
  bool showCompletedGames = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _refreshGames();
  }

  Future<void> _refreshGames() async {
    setState(() {
      _games = _fetchGames();
    });
  }

  Future<List<Game>> _fetchGames() async {
    final String baseUrl = 'http://165.227.117.48';
    final String endpoint = '/games';
    final String url = '$baseUrl$endpoint';

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer ${widget.accessToken}'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (responseData.containsKey('games')) {
        final List<dynamic> gamesData = responseData['games'];
        final List<Game> games =
            gamesData.map((game) => Game.fromJson(game)).toList();
        return games;
      } else {
        throw Exception('Invalid response structure. Expected "games" field.');
      }
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Login again'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => LoginView(),
                    ),
                  );
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
      throw Exception('Failed to fetch games');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Game List'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshGames,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Signed in as'),
                  Text(
                    widget.username,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.add),
              title: Text('New Game'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => GameView(
                          accessToken: widget.accessToken, opponent: "_")),
                ).then((_) {
                  _scaffoldKey.currentState?.openEndDrawer();
                  _refreshGames();
                });
              },
            ),
            ListTile(
              leading: Icon(Icons.games),
              title: Text('New Game (AI)'),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Select AI Opponent'),
                      content: Container(
                        height: 150,
                        child: Column(
                          children: [
                            ListTile(
                              title: Text('Random'),
                              onTap: () {
                                Navigator.pop(context, 'random');
                              },
                            ),
                            ListTile(
                              title: Text('Perfect'),
                              onTap: () {
                                Navigator.pop(context, 'perfect');
                              },
                            ),
                            ListTile(
                              title: Text('One Ship'),
                              onTap: () {
                                Navigator.pop(context, 'oneship');
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ).then((selectedOpponent) {
                  if (selectedOpponent != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GameView(
                          accessToken: widget.accessToken,
                          opponent: selectedOpponent,
                        ),
                      ),
                    ).then((_) {
                      _scaffoldKey.currentState?.openEndDrawer();
                      _refreshGames();
                    });
                  }
                });
              },
            ),
            ListTile(
              leading: Icon(Icons.list),
              title: Text(showCompletedGames
                  ? 'Show Active Games'
                  : 'Show Completed Games'),
              onTap: () {
                setState(() {
                  showCompletedGames = !showCompletedGames;
                });
                _refreshGames();
              },
            ),
            ListTile(
              leading: Icon(Icons.exit_to_app),
              title: Text('Log Out'),
              onTap: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<Game>>(
        future: _fetchGames(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final List<Game> games = snapshot.data ?? [];
            final List<Game> filteredGames = showCompletedGames
                ? games
                    .where((game) => game.status == 1 || game.status == 2)
                    .toList()
                : games
                    .where((game) => game.status == 0 || game.status == 3)
                    .toList();
            return ListView.builder(
              itemCount: filteredGames.length,
              itemBuilder: (context, index) {
                final Game game = filteredGames[index];
                return ListTile(
                  title: Text(
                      'Game ID: ${game.id}  ${game.player1} (vs) ${game.player2}'),
                  subtitle: Text(getTurnText(game.turn, game.position)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                          'Status: ${getStatusText(game.status, game.position)}'),
                      SizedBox(width: 10),
                      if (!showCompletedGames)
                        GestureDetector(
                          onTap: () {
                            _deleteGame(game.id);
                          },
                          child: Icon(Icons.delete),
                        ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GamePlayView(
                            gameId: game.id, accessToken: widget.accessToken),
                      ),
                    ).then((_) {
                      _scaffoldKey.currentState?.openEndDrawer();
                      _refreshGames();
                    });
                  },
                );
              },
            );
          }
        },
      ),
    );
  }

  String getStatusText(int status, int position) {
    switch (status) {
      case 0:
        return 'Matchmaking';
      case 1:
        return position == status ? 'You Won' : 'You Lost';
      case 2:
        return position == status ? 'You Won' : 'You Lost';
      case 3:
        return 'Active';
      default:
        return 'Unknown';
    }
  }

  String getTurnText(int turn, int position) {
    if (turn != position) return 'Oponent turn';
    if (turn == position) return 'My turn';
    return 'Inactive';
  }

  void _deleteGame(int gameId) async {
    final String apiUrl = 'http://165.227.117.48/games/$gameId';
    final response = await http.delete(
      Uri.parse(apiUrl),
      headers: {'Authorization': 'Bearer ${widget.accessToken}'},
    );

    if (response.statusCode == 200) {
      setState(() {});
    } else {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      if (responseData.containsKey('message')) {
        final String message = responseData['message'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
          ),
        );
      } else if (responseData.containsKey('error')) {
        final String error = responseData['error'];
        print('Error: $error');
      } else {
        print('Failed to delete game. Status code: ${response.statusCode}');
      }
    }
  }
}
