import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:battleships/views/login.dart';

class GamePlayView extends StatefulWidget {
  final String accessToken;
  final int gameId;

  GamePlayView({required this.accessToken, required this.gameId});

  @override
  _GamePlayViewState createState() => _GamePlayViewState();
}

class _GamePlayViewState extends State<GamePlayView> {
  late Future<GameDetails> _gameDetails;
  bool isUserTurn = false;
  String selectedBox = "";
  String hoveredBox = '';

  @override
  void initState() {
    super.initState();
    _gameDetails = _fetchGameDetails();
  }

  Future<GameDetails> _fetchGameDetails() async {
    final String url = 'http://165.227.117.48/games/${widget.gameId}';

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer ${widget.accessToken}'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> gameDetailsData = jsonDecode(response.body);
      return GameDetails.fromJson(gameDetailsData);
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
      throw Exception('Failed to fetch game details');
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text('Game Details'),
      ),
      body: FutureBuilder<GameDetails>(
        future: _gameDetails,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final GameDetails gameDetails = snapshot.data!;
            isUserTurn = gameDetails.position == gameDetails.turn;
            return Column(
              children: [
                Container(
                  padding: EdgeInsets.all(5.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Game ID: ${gameDetails.id}'),
                            Text(
                                'Players: ${gameDetails.player1} (vs) ${gameDetails.player2}'),
                            Text('Status: ${_getGameStatus(gameDetails)}'),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.directions_boat,
                                color: Colors.blue,
                                size: 15,
                              ),
                              Text('Ships'),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.whatshot,
                                color: Colors.black,
                                size: 15,
                              ),
                              Text('My ship Wrecks'),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.clear,
                                color: Colors.red,
                                size: 15,
                              ),
                              Text('Shots missed'),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.check,
                                color: Colors.green,
                                size: 15,
                              ),
                              Text('Shots Sunk'),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: Container(
                    width: (screenHeight - 50) * 0.7,
                    height: (screenHeight - 50) * 0.7,
                    padding: EdgeInsets.only(left: screenWidth * 0.05),
                    child: Flexible(
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          crossAxisSpacing: 6.0,
                          mainAxisSpacing: 6.0,
                          childAspectRatio: 1,
                        ),
                        itemBuilder: (context, index) {
                          final row = index ~/ 6;
                          final column = index % 6;
                          final boxId =
                              '${String.fromCharCode('A'.codeUnitAt(0) + row - 1)}${column}';

                          return MouseRegion(
                            onEnter: (_) {
                              setState(() {
                                _handleBoxHover(boxId, gameDetails);
                              });
                            },
                            onExit: (_) {
                              setState(() {
                                hoveredBox = '';
                              });
                            },
                            child: GestureDetector(
                              onTap: () {
                                _handleBoxSelection(boxId, gameDetails);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: selectedBox == boxId
                                      ? Color.fromARGB(104, 71, 159, 223)
                                      : (hoveredBox == boxId)
                                          ? const Color.fromARGB(
                                              197, 158, 158, 158)
                                          : Colors.white,
                                ),
                                alignment: Alignment.center,
                                child: (row == 0 && column == 0)
                                    ? Text('')
                                    : (row == 0)
                                        ? Text('${column}')
                                        : (column == 0)
                                            ? Text(
                                                '${String.fromCharCode('A'.codeUnitAt(0) + row - 1)}')
                                            : _getIcon(
                                                boxId,
                                                gameDetails,
                                                screenHeight > screenWidth
                                                    ? screenWidth * 0.03
                                                    : screenHeight * 0.03),
                              ),
                            ),
                          );
                        },
                        itemCount: 36,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Container(
                  child: ElevatedButton(
                    onPressed:
                        isUserTurn ? () => _handleSubmit(gameDetails) : null,
                    child: Text('Submit'),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _getIcon(String boxId, GameDetails gameDetails, double iconsize) {
    List<IconData> icons = [];
    List<Color> colors = [];
    if (gameDetails.ships.contains(boxId)) {
      icons.add(Icons.directions_boat);
      colors.add(Colors.blue);
    }
    if (gameDetails.wrecks.contains(boxId)) {
      icons.add(Icons.whatshot);
      colors.add(Colors.black);
    }
    if (gameDetails.shots.contains(boxId)) {
      icons.add(Icons.clear);
      colors.add(Colors.red);
    }
    if (gameDetails.sunk.contains(boxId)) {
      icons.add(Icons.check);
      colors.add(Colors.green);
    }

    if (gameDetails.shots.contains(boxId) && gameDetails.sunk.contains(boxId)) {
      colors.remove(Colors.red);
      icons.remove(Icons.clear);
    }

    return _buildIcon(icons, colors, iconsize);
  }

  Widget _buildIcon(List<IconData> icons, List<Color> colors, double iconsize) {
    return Container(
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < icons.length; i++)
            Icon(
              icons[i],
              color: colors[i],
              size: iconsize,
            ),
        ],
      ),
    );
  }

  void _handleBoxHover(String boxId, GameDetails gameDetails) {
    setState(() {
      final int row = boxId.codeUnitAt(0) - 'A'.codeUnitAt(0);

      final int column = int.parse(boxId.substring(1));

      if (row == -1 || column == 0) {
        return;
      }

      if (gameDetails.shots.contains(boxId) || gameDetails.sunk.contains(boxId))
        return;

      hoveredBox = boxId;
    });
  }

  void _handleBoxSelection(String boxId, GameDetails gameDetails) {
    setState(() {
      final int row = boxId.codeUnitAt(0) - 'A'.codeUnitAt(0);

      final int column = int.parse(boxId.substring(1));

      if (row == -1 || column == 0) {
        return;
      }

      if (gameDetails.shots.contains(boxId) || gameDetails.sunk.contains(boxId))
        return;

      selectedBox = boxId;
    });
  }

  void _handleSubmit(GameDetails gameDetails) async {
    final requestBody = {"shot": selectedBox};
    print('Request Body: $requestBody');

    const apiUrl = 'http://165.227.117.48/games/';
    final url = '${apiUrl}${gameDetails.id}';
    final response = await http.put(
      Uri.parse(url),
      headers: {
        'Content-type': 'application/json',
        'Authorization': 'Bearer ${widget.accessToken}',
      },
      body: jsonEncode(requestBody),
    );
    print('response : ${response.body}');

    // if (response.statusCode == 200) {
    final Map<String, dynamic> responseBody = jsonDecode(response.body);

    if (responseBody.containsKey('error')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(responseBody['error']),
          duration: Duration(seconds: 2),
        ),
      );
    } else if (response.statusCode != 200) {
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
      throw Exception('Failed to fetch game details');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(responseBody['sunk_ship'] ? 'Sunk a ship' : 'Missed Shot'),
          duration: Duration(seconds: 2),
        ),
      );

      if (responseBody['sunk_ship'] == true) {}

      if (responseBody['won'] == true) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Congratulations!'),
            content: Text('You have won the game.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      } else {
        setState(() {
          _gameDetails = _fetchGameDetails();
        });
      }
    }
  }

  String _getGameStatus(GameDetails gameDetails) {
    switch (gameDetails.status) {
      case 1:
        return 'Game completed, won by ${gameDetails.player1}';
      case 2:
        return 'Game completed, won by ${gameDetails.player2}';
      case 3:
        return 'Game in progress';
      default:
        return 'Matchmaking Phase';
    }
  }
}

class GameDetails {
  final int id;
  final int status;
  final int position;
  final int turn;
  final String player1;
  final String? player2;
  final List<String> ships;
  final List<String> wrecks;
  final List<String> shots;
  final List<String> sunk;

  GameDetails({
    required this.id,
    required this.status,
    required this.position,
    required this.turn,
    required this.player1,
    required this.player2,
    required this.ships,
    required this.wrecks,
    required this.shots,
    required this.sunk,
  });

  factory GameDetails.fromJson(Map<String, dynamic> json) {
    return GameDetails(
      id: json['id'] as int,
      status: json['status'] as int,
      position: json['position'] as int,
      turn: json['turn'] as int,
      player1: json['player1'] as String,
      player2: json['player2'] as String?,
      ships: List<String>.from(json['ships']),
      wrecks: List<String>.from(json['wrecks']),
      shots: List<String>.from(json['shots']),
      sunk: List<String>.from(json['sunk']),
    );
  }
}
