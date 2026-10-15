import '../../../core/game_models/game_event.dart';
import '../../../l10n/strings.dart';

String _refillNotice(String player, int borrowedTotal, bool noBorrow) {
  if (noBorrow) return Strings.refillMsg(player);
  return Strings.borrowMsg(player, borrowedTotal);
}

/// Câu thông báo cho sự kiện đáng báo (nạp, trả nợ, loại...); null nếu không.
String? gameNoticeText(GameEvent e, String Function(int id) name) {
  return switch (e) {
    RefillEvent(:final playerId, :final borrowed) => _refillNotice(
      name(playerId),
      borrowed.values.fold<int>(0, (a, b) => a + b),
      borrowed.isEmpty,
    ),
    RepayEvent(:final fromId, :final amount) => Strings.repayMsg(
      name(fromId),
      amount,
    ),
    EliminateEvent(:final playerId) => Strings.eliminateMsg(name(playerId)),
    RuleLoopGuardEvent() => Strings.loopGuardMsg,
    _ => null,
  };
}
