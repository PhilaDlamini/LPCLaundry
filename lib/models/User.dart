import 'package:equatable/equatable.dart';

class User extends Equatable{
  final String name;
  final String block;
  final String room;
  final String uid;
  final String email;
  final bool currentlyQueued;

  User({this.name, this.uid, this.currentlyQueued, this.email, this.block, this.room});

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
        name: map['name'] ?? '',
        email: map['email'] ?? '',
        block: map['block'] ?? '',
        room: map['room'] ?? '',
        currentlyQueued: map['currentlyQueued'] ?? '',
        uid: map['uid'] ?? '');
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'block': block,
      'room': room,
      'uid': uid,
      'email': email,
      'currentlyQueued': currentlyQueued
    };
  }

  @override
  String toString() {
    return 'Name: $name Block: $block Room: $room Uid: $uid currentlyQueued: $currentlyQueued';
  }

  @override
  List<Object> get props => [name, block, room, uid, email];

}
