/// Funções puras de formatação (fáceis de testar, sem depender de widgets).
library;

/// `há 3 min`, `há 2 h`, `há 4 dias`...
String timeAgo(DateTime moment, DateTime now) {
  final diff = now.difference(moment);
  if (diff.inSeconds < 60) {
    return 'agora mesmo';
  }
  if (diff.inMinutes < 60) {
    return 'há ${diff.inMinutes} min';
  }
  if (diff.inHours < 24) {
    return 'há ${diff.inHours} h';
  }
  final days = diff.inDays;
  return days == 1 ? 'há 1 dia' : 'há $days dias';
}

/// `45s`, `1m 40s`, `1h 05m`.
String formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);
  if (hours > 0) {
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  }
  if (minutes > 0) {
    return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
  }
  return '${seconds}s';
}

/// Horário local no formato `HH:mm`.
String formatClock(DateTime moment) {
  final local = moment.toLocal();
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}
