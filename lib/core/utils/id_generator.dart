import 'dart:math';

class IdGenerator {
  static final _random = Random.secure();

  static String uuid() {
    const chars = 'abcdef0123456789';
    final segments = [8, 4, 4, 4, 12];
    return segments
        .map((len) => List.generate(
            len, (_) => chars[_random.nextInt(chars.length)]).join())
        .join('-');
  }

  static String inviteCode({int length = 6}) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no I/O/0/1 confusion
    return List.generate(
        length, (_) => chars[_random.nextInt(chars.length)]).join();
  }
}
