import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data.dart';

class Game extends ChangeNotifier {
  int coins = 0;
  final Map<int, int> stars = {};
  final Set<String> owned = {};
  String hat = '';
  SharedPreferences? _p;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _p = p;
    coins = p.getInt('coins') ?? 0;
    hat = p.getString('hat') ?? '';
    owned
      ..clear()
      ..addAll(p.getStringList('owned') ?? <String>[]);
    stars.clear();
    for (final s in p.getStringList('stars') ?? <String>[]) {
      final a = s.split(':');
      stars[int.parse(a[0])] = int.parse(a[1]);
    }
    notifyListeners();
  }

  void _save() {
    final p = _p;
    if (p == null) return;
    p.setInt('coins', coins);
    p.setString('hat', hat);
    p.setStringList('owned', owned.toList());
    p.setStringList('stars', stars.entries.map((e) => '${e.key}:${e.value}').toList());
  }

  int get totalStars => stars.values.fold(0, (a, b) => a + b);
  int starsOf(int id) => stars[id] ?? 0;

  bool isUnlocked(LevelDef l) {
    if (l.id == 1) return true;
    return starsOf(l.id - 1) >= 1 && totalStars >= l.needStars;
  }

  double get ovenBonus => owned.contains('oven2') ? 0.12 : (owned.contains('oven1') ? 0.06 : 0.0);
  double get mixSpeed => owned.contains('mixer2') ? 2.2 : (owned.contains('mixer1') ? 1.5 : 1.0);
  int get extraTime => owned.contains('clock') ? 15 : 0;

  void finishLevel(int id, int starCount, int reward) {
    if (starCount > starsOf(id)) stars[id] = starCount;
    coins += reward;
    _save();
    notifyListeners();
  }

  bool buy(ShopItem i) {
    if (owned.contains(i.id) || coins < i.price) return false;
    if (i.requires != null && !owned.contains(i.requires)) return false;
    coins -= i.price;
    owned.add(i.id);
    _save();
    notifyListeners();
    return true;
  }

  void setHat(String h) {
    hat = h;
    _save();
    notifyListeners();
  }
}

final game = Game();
