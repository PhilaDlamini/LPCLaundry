import 'package:equatable/equatable.dart';

class User extends Equatable{
  final String name;
  final String block;
  final String room;
  final String uid;

  User({this.name, this.uid, this.block, this.room});

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
        name: map['name'] ?? '',
        block: map['block'] ?? '',
        room: map['room'] ?? '',
        uid: map['uid'] ?? '');
  }

  Map<String, String> toMap() {
    return {
      'name': name,
      'block': block,
      'room': room,
      'uid': uid,
    };
  }

  @override
  String toString() {
    return 'Name: $name Block: $block Room: $room Uid: $uid';
  }

  @override
  List<Object> get props => [name, block, room, uid];

}
