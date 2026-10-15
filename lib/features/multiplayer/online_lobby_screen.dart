import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/widgets.dart';
import 'multiplayer_repository.dart';
import 'protocol.dart';
import '../../l10n/strings.dart';

/// Lobby online — UI + hợp đồng thật, server giả lập cục bộ (chưa có mạng).
String _errorText(String error) {
  if (error == 'roomNotFound') return Strings.roomNotFound;
  return error;
}

Widget? _seatMark(bool isMe) {
  if (isMe) return const FolkIcon(Icons.person_pin_rounded);
  return null;
}

class OnlineLobbyScreen extends StatefulWidget {
  const OnlineLobbyScreen({super.key});

  @override
  State<OnlineLobbyScreen> createState() => _OnlineLobbyScreenState();
}

class _OnlineLobbyScreenState extends State<OnlineLobbyScreen> {
  // Một hub dùng chung cho cả màn: mô phỏng nhiều client trên cùng máy.
  static final _hub = FakeServerHub();
  late final LocalFakeMultiplayerRepository _repo =
      LocalFakeMultiplayerRepository(
        _hub,
        'me-${DateTime.now().microsecondsSinceEpoch}',
      );
  StreamSubscription<ServerMessage>? _sub;
  final _code = TextEditingController();
  int _count = 2;
  StateSnapshot? _room;
  String? _error;
  int _action = 0;
  int _bots = 0;

  @override
  void initState() {
    super.initState();
    _sub = _repo.messages.listen((m) {
      if (!mounted) return;
      setState(() {
        switch (m) {
          case StateSnapshot():
            _room = m;
            _error = null;
          case MoveRejected(:final reason):
            _error = reason;
          default:
            break;
        }
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _repo.close();
    _code.dispose();
    super.dispose();
  }

  String _aid() => '${_repo.clientId}#${_action++}';

  Future<void> _addSimulatedGuest() async {
    final room = _room;
    if (room == null) return;
    final guest = LocalFakeMultiplayerRepository(
      _hub,
      'guest-${_bots++}-${room.matchId}',
    );
    await guest.send(
      JoinRoom('${guest.clientId}#0', room.matchId, Strings.guestName(_bots)),
    );
    // Giữ kết nối khách mở trong vòng đời demo.
  }

  @override
  Widget build(BuildContext context) {
    final room = _room;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(Strings.onlineTitle)),
      body: AppBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.18),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const FolkIcon(Icons.info_outline_rounded),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            Strings.onlineNotice,
                            key: const Key('onlineNotice'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (room == null) ...[
                  SegmentedButton<int>(
                    segments: [
                      for (final n in [2, 3, 4])
                        ButtonSegment(
                          value: n,
                          label: Text(Strings.playersCount(n)),
                        ),
                    ],
                    selected: {_count},
                    onSelectionChanged: (v) => setState(() => _count = v.first),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    icon: const FolkIcon(Icons.add_home_rounded),
                    label: Text(Strings.createRoom),
                    onPressed: () => _repo.send(
                      CreateRoom(_aid(), Strings.defaultPlayerName(1), _count),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _code,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: Strings.roomCode,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    icon: const FolkIcon(Icons.login_rounded),
                    label: Text(Strings.joinRoom),
                    onPressed: () => _repo.send(
                      JoinRoom(
                        _aid(),
                        _code.text.trim(),
                        Strings.defaultPlayerName(2),
                      ),
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        _errorText(_error!),
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                ] else ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Strings.roomCreated(room.matchId),
                            style: theme.textTheme.titleMedium,
                          ),
                          SelectableText(
                            room.matchId,
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 6,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            Strings.waitingPlayers(
                              room.seats.length,
                              room.playerCount,
                            ),
                          ),
                          const SizedBox(height: 8),
                          for (var i = 0; i < room.seats.length; i++)
                            ListTile(
                              dense: true,
                              leading: PlayerAvatar(playerId: i, size: 28),
                              title: Text(room.seats[i]),
                              trailing: _seatMark(i == room.playerId),
                            ),
                          if (room.state != null)
                            Text(
                              'revision ${room.revision} · state ✓',
                              style: theme.textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (room.seats.length < room.playerCount)
                    OutlinedButton.icon(
                      icon: const FolkIcon(Icons.person_add_alt_rounded),
                      label: Text(Strings.addSimulatedClient),
                      onPressed: _addSimulatedGuest,
                    ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    icon: const FolkIcon(Icons.cloud_off_rounded),
                    label: Text(Strings.onlineUnavailable),
                    onPressed: null,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
