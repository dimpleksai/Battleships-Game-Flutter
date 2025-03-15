class Game {
  final int id;
  final String player1;
  final String? player2;
  final int position;
  final int status;
  final int turn;

  Game({
    required this.id,
    required this.player1,
    required this.player2,
    required this.position,
    required this.status,
    required this.turn,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      id: json['id'] as int,
      player1: json['player1'] as String? ?? '',
      player2: json['player2'] as String? ?? '',
      turn: json['turn'] as int? ?? 0,
      status: json['status'] as int? ?? 0,
      position: json['position'] as int? ?? 0,
    );
  }
}
