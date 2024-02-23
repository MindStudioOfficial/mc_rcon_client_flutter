import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class RCONConnection {}

@immutable
class RCONPacket {
  const RCONPacket({
    required this.id,
    required this.type,
    required this.body,
  });

  factory RCONPacket.fromBytes(Uint8List bytes) {
    // length excludes the length field itself
    final length = bytes.buffer.asByteData().getInt32(0, Endian.little);
    final id = bytes.buffer.asByteData().getInt32(4, Endian.little);
    final type = bytes.buffer.asByteData().getInt32(8, Endian.little);
    var body = '';
    try {
      body = ascii.decode(bytes.sublist(12, 4 + length - 2));
    } catch (e) {
      try {
        body = utf8.decode(bytes.sublist(12, 4 + length - 2));
      } catch (e) {
        throw Exception('Unsupported encoding for RCONPacket body');
      }
    }

    return RCONPacket(id: id, type: type, body: body);
  }

  final int id; // int32 rcon packet id
  final int type; // int32 rcon packet type
  final String body; // string (null terminated ascii) rcon packet body

  Uint8List toBytes() {
    final idBytes = Uint8List(4)
      ..buffer.asByteData().setInt32(0, id, Endian.little);
    final typeBytes = Uint8List(4)
      ..buffer.asByteData().setInt32(0, type, Endian.little);

    var bodyBytes = Uint8List(0);
    try {
      bodyBytes = Uint8List.fromList(ascii.encode(body));
    } catch (e) {
      try {
        bodyBytes = Uint8List.fromList(utf8.encode(body));
      } catch (e) {
        throw Exception('Unsupported encoding for RCONPacket body');
      }
    }

    final nullTerminator = Uint8List(2)
      ..buffer.asByteData().setInt16(0, 0, Endian.little);

    final bytes = Uint8List.fromList([
      ...idBytes,
      ...typeBytes,
      ...bodyBytes,
      ...nullTerminator,
    ]);

    final length = bytes.length;

    return Uint8List.fromList([
      ...Uint8List(4)..buffer.asByteData().setInt32(0, length, Endian.little),
      ...bytes,
    ]);
  }

  @override
  String toString() {
    return 'RCONPacket(id: $id, type: $type, body: $body)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RCONPacket &&
        other.id == id &&
        other.type == type &&
        other.body == body;
  }

  @override
  int get hashCode => id.hashCode ^ type.hashCode ^ body.hashCode;
}

class RCONPacketTypes {
  static const int login = 3;
  static const int command = 2;
  static const int response = 0;
}
