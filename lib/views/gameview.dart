import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:battleships/views/login.dart';

class GameView extends StatefulWidget {
  final String accessToken;
  final String opponent;
  GameView({required this.accessToken, required this.opponent});

  @override
  _GameViewState createState() => _GameViewState();
}

class _GameViewState extends State<GameView> {
  List<String> selectedBoxes = [];
  String hoveredBox = '';

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text('Place Ships'),
      ),
      body: Column(
        children: [
          SizedBox(height: 20),
          Flexible(
            child: Container(
              width: screenHeight * 1.05,
              height: screenHeight,
              padding: EdgeInsets.only(left: screenWidth * 0.2),
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
                          _handleBoxHover(boxId);
                        });
                      },
                      onExit: (_) {
                        setState(() {
                          hoveredBox = '';
                        });
                      },
                      child: GestureDetector(
                        onTap: () {
                          _handleBoxSelection(boxId);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: selectedBoxes.contains(boxId)
                                ? Colors.blue
                                : (hoveredBox == boxId)
                                    ? Colors.grey
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
                                      : Text(''),
                        ),
                      ),
                    );
                  },
                  itemCount: 36,
                ),
              ),
            ),
          ),
          SizedBox(height: 1),
          Padding(
            padding: EdgeInsets.only(left: screenWidth * 0.3),
            child: ElevatedButton(
              onPressed: selectedBoxes.length >= 5 ? _handleSubmit : null,
              child: Text('Submit'),
            ),
          ),
          SizedBox(height: 10),
        ],
      ),
    );
  }

  void _handleBoxHover(String boxId) {
    setState(() {
      final int row = boxId.codeUnitAt(0) - 'A'.codeUnitAt(0);

      final int column = int.parse(boxId.substring(1));

      if (row == -1 || column == 0) {
        return;
      }

      if (!selectedBoxes.contains(boxId)) {
        hoveredBox = boxId;
        ;
      } else {
        hoveredBox = '';
      }
    });
  }

  void _handleBoxSelection(String boxId) {
    setState(() {
      final int row = boxId.codeUnitAt(0) - 'A'.codeUnitAt(0);

      final int column = int.parse(boxId.substring(1));

      if (row == -1 || column == 0) {
        return;
      }

      if (selectedBoxes.contains(boxId)) {
        selectedBoxes.remove(boxId);
      } else if (selectedBoxes.length < 5) {
        selectedBoxes.add(boxId);
      }
    });
  }

  void _handleSubmit() async {
    Map<String, dynamic> requestBody = {};
    if (widget.opponent == "_") {
      requestBody = {"ships": selectedBoxes};
    } else {
      requestBody = {
        "ships": selectedBoxes,
        "ai": widget.opponent,
      };
    }

    const apiUrl = 'http://165.227.117.48/games';
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-type': 'application/json',
        'Authorization': 'Bearer ${widget.accessToken}',
      },
      body: jsonEncode(requestBody),
    );

    final Map<String, dynamic> responseBody = jsonDecode(response.body);
    if (responseBody.containsKey('id')) {
      Navigator.of(context).pop();
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
    }
  }
}
