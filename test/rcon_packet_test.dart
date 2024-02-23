import 'dart:convert';
import 'dart:typed_data';

import 'package:fl_rcon_client/rcon.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('test creation of RCON Packet', () {
    const packet = RCONPacket(id: 1, type: 2, body: 'test');
    expect(packet.id, 1);
    expect(packet.type, 2);
    expect(packet.body, 'test');

    final bytes = packet.toBytes();

    expect(bytes.length, 18);
    expect(bytes.buffer.asByteData().getInt32(0, Endian.little), 14);
    expect(bytes.buffer.asByteData().getInt32(4, Endian.little), 1);
    expect(bytes.buffer.asByteData().getInt32(8, Endian.little), 2);
    expect(bytes.sublist(12, 16), ascii.encode('test'));
    expect(bytes.buffer.asByteData().getInt8(16), 0);
    expect(bytes.buffer.asByteData().getInt8(17), 0);

    final packet2 = RCONPacket.fromBytes(bytes);
    expect(packet2.id, 1);
    expect(packet2.type, 2);
    expect(packet2.body, 'test');
  });
}
