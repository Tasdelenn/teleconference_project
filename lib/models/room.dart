import 'package:teleconference_app/models/participant.dart';

class Room {
  final String id;
  final List<Participant> participants;

  Room({
    required this.id,
    required this.participants,
  });
}