// ignore_for_file: avoid_print
import 'dart:io';

import 'package:fl_rcon_client/command_history.dart';
import 'package:fl_rcon_client/minecraft_chat_parser.dart';
import 'package:fl_rcon_client/rcon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const Main());
}

class Main extends StatefulWidget {
  const Main({super.key});

  @override
  State<Main> createState() => _MainState();
}

class _MainState extends State<Main> {
  late TextEditingController _hostController;
  late TextEditingController _portController;
  late TextEditingController _passwordController;
  late TextEditingController _commandController;

  var _connectionState = ConnectionState.disconnected;
  var _authState = AuthState.notAuthenticated;

  final List<(String, Color)> _response = [];
  var _error = '';

  Socket? _socket;

  int _packetIdCounter = 3;

  final _commandHistory = CommandHistory();

  @override
  void initState() {
    super.initState();

    _hostController = TextEditingController();
    _portController = TextEditingController(text: '25575');
    _passwordController = TextEditingController();
    _commandController = TextEditingController();
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _passwordController.dispose();
    _commandController.dispose();
    super.dispose();
  }

  Future<void> connect() async {
    if (_connectionState != ConnectionState.disconnected) return;

    setState(() {
      _connectionState = ConnectionState.connecting;
    });

    final host = _hostController.text;

    // validate host
    if (host.isEmpty) {
      setState(() {
        _connectionState = ConnectionState.error;
        _error = 'Host cannot be empty';
      });
      return;
    }

    final port = int.tryParse(_portController.text) ?? 25575;

    // validate port
    if (port < 1 || port > 65535) {
      setState(() {
        _connectionState = ConnectionState.error;
        _error = 'Invalid port';
      });
      return;
    }

    try {
      _socket = await Socket.connect(host, port);
    } on SocketException catch (e) {
      setState(() {
        _connectionState = ConnectionState.error;
        _error = e.message;
      });
      return;
    }

    // listen for data

    _socket!.listen(
      (data) {
        try {
          final rconPacket = RCONPacket.fromBytes(data);
          handleRCONPacket(rconPacket);
        } catch (e) {
          // data might not be an rcon packet
          setState(() {
            _error = 'Received non-RCON data: $data';
          });
        }
      },
      onDone: () {
        setState(() {
          _connectionState = ConnectionState.disconnected;
        });
      },
      onError: (dynamic e) {
        setState(() {
          _connectionState = ConnectionState.error;
          _error = e.toString();
        });
      },
    );

    setState(() {
      _connectionState = ConnectionState.connected;
    });

    await login();
  }

  void handleRCONPacket(RCONPacket packet) {
    print(packet);
    if (packet.id == -1) {
      setState(() {
        _authState = AuthState.error;
        _error = packet.body;
        _socket?.close();
        _connectionState = ConnectionState.disconnected;
      });
      return;
    } else {
      setState(() {
        _authState = AuthState.authenticated;
        _response.addAll(MinecraftMessageParser.parse(packet.body));
      });
    }
  }

  Future<void> login() async {
    final password = _passwordController.text;

    final packet = RCONPacket(
      id: _packetIdCounter++,
      type: RCONPacketTypes.login,
      body: password,
    );

    _socket!.add(packet.toBytes());

    await _socket!.flush();

    print('Sent login packet: $packet');

    setState(() {
      _authState = AuthState.authenticating;
    });
  }

  void sendCommand(String command) {
    if (command.isEmpty) {
      return;
    }

    if (_socket == null) {
      setState(() {
        _error = 'Not connected';
      });
      return;
    }

    if (_connectionState != ConnectionState.connected) {
      setState(() {
        _error = 'Not connected';
      });
      return;
    }

    if (_authState != AuthState.authenticated) {
      setState(() {
        _error = 'Not authenticated';
      });
      return;
    }

    final packet = RCONPacket(
      id: _packetIdCounter++,
      type: RCONPacketTypes.command,
      body: command,
    );
    _socket!.add(packet.toBytes());

    print('Sent command: $command as packet: $packet');

    setState(() {
      _commandHistory.add(command);
      _commandHistory.reset();
      print(_commandHistory);
      _commandController.clear();
    });
  }

  void disconnect() {
    _socket?.close();
    _socket = null;
    setState(() {
      _connectionState = ConnectionState.disconnected;
      _authState = AuthState.notAuthenticated;
      _response.clear();
      _error = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.from(
        colorScheme: const ColorScheme.dark().copyWith(
          primary: Colors.blue,
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('RCON Client'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              connectionInfo(),
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText.rich(
                    TextSpan(children: parseResponse(_response)),
                    textWidthBasis: TextWidthBasis.longestLine,
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: KeyboardListener(
                      focusNode: _commandFocusNode,
                      onKeyEvent: handleCommandKeyEvent,
                      child: TextField(
                        controller: _commandController,
                        decoration: const InputDecoration(
                          labelText: 'Command',
                        ),
                        onEditingComplete: () {
                          sendCommand(_commandController.text);
                        },
                        onSubmitted: (_) =>
                            sendCommand(_commandController.text),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      sendCommand(_commandController.text);
                    },
                    child: const Text('Send'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  final _commandFocusNode = FocusNode();

  void handleCommandKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      // on up key get previous command from history
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        final previousCommand = _commandHistory.getPrevious();
        print(_commandHistory);
        print(previousCommand);
        if (previousCommand != null) {
          _commandController.value = TextEditingValue(
            text: previousCommand,
            selection: TextSelection.fromPosition(
              TextPosition(offset: previousCommand.length),
            ),
          );
        } else {
          _commandController.clear();
        }
        print(_commandController.text);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        final nextCommand = _commandHistory.getNext();
        print(_commandHistory);
        print(nextCommand);
        if (nextCommand != null) {
          setState(() {
            _commandController.value = TextEditingValue(
              text: nextCommand,
              selection: TextSelection.fromPosition(
                TextPosition(offset: nextCommand.length),
              ),
            );
          });
        } else {
          _commandController.clear();
        }
        print(_commandController.text);
      }
    }
  }

  Widget connectionInfo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _hostController,
                decoration: const InputDecoration(labelText: 'Host'),
              ),
              TextField(
                controller: _portController,
                decoration: const InputDecoration(labelText: 'Port'),
              ),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    ElevatedButton(
                      onPressed:
                          _connectionState == ConnectionState.disconnected
                              ? () async {
                                  await connect();
                                }
                              : null,
                      child: const Text('Connect'),
                    ),
                    ElevatedButton(
                      onPressed: _connectionState == ConnectionState.connected
                          ? disconnect
                          : null,
                      child: const Text('Disconnect'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ConnectionState
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        connectionStateIcons[_connectionState],
                        color: connectionStateColors[_connectionState],
                      ),
                    ),
                    Text(connectionStateMessages[_connectionState]!),
                  ],
                ),
              ),
              // AuthState
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        authStateIcons[_authState],
                        color: authStateColors[_authState],
                      ),
                    ),
                    Text(authStateMessages[_authState]!),
                  ],
                ),
              ),
              if (_error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: SelectableText(
                    _error,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  List<InlineSpan> parseResponse(List<(String, Color)> response) {
    final spans = <InlineSpan>[];
    for (final (text, color) in response) {
      spans.add(TextSpan(text: text, style: TextStyle(color: color)));
    }
    return spans;
  }

  Map<ConnectionState, String> connectionStateMessages = {
    ConnectionState.disconnected: 'Disconnected',
    ConnectionState.connecting: 'Connecting...',
    ConnectionState.connected: 'Connected',
    ConnectionState.error: 'Error',
  };

  Map<ConnectionState, Color> connectionStateColors = {
    ConnectionState.disconnected: Colors.red,
    ConnectionState.connecting: Colors.yellow,
    ConnectionState.connected: Colors.green,
    ConnectionState.error: Colors.red,
  };

  Map<ConnectionState, IconData> connectionStateIcons = {
    ConnectionState.disconnected: Icons.close,
    ConnectionState.connecting: Icons.hourglass_empty,
    ConnectionState.connected: Icons.check,
    ConnectionState.error: Icons.error,
  };

  Map<AuthState, String> authStateMessages = {
    AuthState.notAuthenticated: 'Not Authenticated',
    AuthState.authenticating: 'Authenticating...',
    AuthState.authenticated: 'Authenticated',
    AuthState.error: 'Error',
  };

  Map<AuthState, Color> authStateColors = {
    AuthState.notAuthenticated: Colors.red,
    AuthState.authenticating: Colors.yellow,
    AuthState.authenticated: Colors.green,
    AuthState.error: Colors.red,
  };

  Map<AuthState, IconData> authStateIcons = {
    AuthState.notAuthenticated: Icons.lock_open,
    AuthState.authenticating: Icons.lock_clock,
    AuthState.authenticated: Icons.lock_outline,
    AuthState.error: Icons.error,
  };
}

enum ConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}

enum AuthState {
  notAuthenticated,
  authenticating,
  authenticated,
  error,
}
