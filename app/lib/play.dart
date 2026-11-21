import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'data.dart';
import 'game.dart';

class PlayScreen extends StatefulWidget {
  final LevelDef level;
  const PlayScreen(this.level, {super.key});
  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> with SingleTickerProviderStateMixin {
  LevelDef get lv => widget.level;
  int step = 0; // 0 مواد، 1 مخلوط، 2 پخت، 3 تزئین
  late int totalTime;
  late int timeLeft;
  Timer? _timer;
  int mistakes = 0;
  int bakePenalty = 0;
  String bakeText = '';
  final Set<String> got = {};
  final List<String> placed = [];
  String? wrong;
  double mix = 0;
  bool done = false;
  late final AnimationController oven;
  late final double center;
  late final double zone;
  late final List<Ingredient> pool;

  @override
  void initState() {
    super.initState();
    totalTime = lv.seconds + game.extraTime;
    timeLeft = totalTime;
    center = 0.3 + Random(lv.id * 7).nextDouble() * 0.4;
    zone = lv.zone + game.ovenBonus;
    pool = List<Ingredient>.of(allIngredients)..shuffle(Random(lv.id));
    oven = AnimationController(vsync: this, duration: Duration(milliseconds: max(700, 1500 - lv.id * 90)))
      ..repeat(reverse: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (done || !mounted) return;
      setState(() => timeLeft--);
      if (timeLeft <= 0) _fail();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    oven.dispose();
    super.dispose();
  }

  void _flash(String id) {
    setState(() {
      mistakes++;
      wrong = id;
    });
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => wrong = null);
    });
  }

  void _pick(Ingredient i) {
    if (done || got.contains(i.id)) return;
    if (lv.ingredients.contains(i.id)) {
      setState(() {
        got.add(i.id);
        if (got.length == lv.ingredients.length) step = 1;
      });
    } else {
      _flash(i.id);
    }
  }

  void _bakeTap() {
    final d = (oven.value - center).abs();
    setState(() {
      if (d <= zone / 2) {
        bakePenalty = 0;
        bakeText = 'پخت عالی! 😍';
      } else if (d <= zone) {
        bakePenalty = 10;
        bakeText = 'پخت معمولی 🙂';
      } else {
        bakePenalty = 25;
        bakeText = 'کمی خراب شد 😅';
      }
      step = 3;
    });
  }

  void _top(String t) {
    if (done) return;
    if (placed.length < lv.toppings.length && lv.toppings[placed.length] == t) {
      setState(() => placed.add(t));
      if (placed.length == lv.toppings.length) _win();
    } else {
      _flash(t);
    }
  }

  void _win() {
    done = true;
    _timer?.cancel();
    final bonus = (max(timeLeft, 0) * 10 / totalTime).round();
    final score = (100 - mistakes * 8 - bakePenalty + bonus).clamp(0, 110).toInt();
    final s = score >= 95 ? 3 : (score >= 75 ? 2 : 1);
    final reward = 20 + score ~/ 2 + lv.id * 5 + s * 10;
    game.finishLevel(lv.id, s, reward);
    _dialog(true, s, reward);
  }

  void _fail() {
    done = true;
    _timer?.cancel();
    _dialog(false, 0, 0);
  }

  void _dialog(bool ok, int s, int reward) {
    final idx = levels.indexWhere((l) => l.id == lv.id);
    final next = idx + 1 < levels.length ? levels[idx + 1] : null;
    final canNext = ok && next != null && game.isUnlocked(next);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(ok ? 'آفرین آیلین! 🎉' : 'وقت تموم شد ⏰', textAlign: TextAlign.center),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          if (ok) Text('⭐' * s + '☆' * (3 - s), style: const TextStyle(fontSize: 36)),
          if (ok) Text('🪙 ${fa(reward)} سکه گرفتی'),
          if (ok && next != null && !canNext) const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('برای باز شدن مرحله بعد ستاره بیشتری لازمه؛ مرحله‌های قبلی رو دوباره بازی کن!', textAlign: TextAlign.center),
          ),
          if (!ok) const Text('یه بار دیگه امتحان کن، می‌تونی!'),
        ]),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          if (canNext)
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PlayScreen(next)));
              },
              child: const Text('مرحله بعد'),
            ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PlayScreen(lv)));
            },
            child: const Text('دوباره'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('بازگشت'),
          ),
        ],
      ),
    );
  }

  Widget _ingredients() => Column(children: [
        const Text('مواد لازم رو پیدا کن!', style: kHeading),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: lv.ingredients.map((id) {
            final i = byId(id);
            return Chip(
              label: Text('${i.emoji} ${i.name}'),
              backgroundColor: got.contains(id) ? Colors.green.shade100 : Colors.white,
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: GridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: pool.map((i) {
              final isGot = got.contains(i.id);
              final isWrong = wrong == i.id;
              return GestureDetector(
                onTap: () => _pick(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isWrong ? Colors.red.shade100 : (isGot ? Colors.green.shade100 : Colors.white),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: kPink, width: 2),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(i.emoji, style: const TextStyle(fontSize: 38)),
                    Text(i.name),
                  ]),
                ),
              );
            }).toList(),
          ),
        ),
      ]);

  Widget _mix() => Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('با انگشتت دور کاسه بچرخون! 🌀', style: kHeading),
        const SizedBox(height: 24),
        GestureDetector(
          onPanUpdate: (d) {
            if (done || step != 1) return;
            setState(() {
              mix += d.delta.distance * game.mixSpeed / 1200;
              if (mix >= 1) {
                mix = 1;
                step = 2;
              }
            });
          },
          child: Container(
            width: 260,
            height: 260,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Transform.rotate(angle: mix * 25, child: const Text('🥣', style: TextStyle(fontSize: 120))),
          ),
        ),
        const SizedBox(height: 24),
        LinearProgressIndicator(
          value: mix,
          minHeight: 14,
          borderRadius: BorderRadius.circular(8),
          color: kPink,
          backgroundColor: Colors.white,
        ),
      ]);

  Widget _bake() => Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('وقتی نشونگر تو ناحیه سبزه، بزن! 🔥', style: kHeading),
        const SizedBox(height: 30),
        LayoutBuilder(builder: (context, cons) {
          final w = cons.maxWidth;
          return AnimatedBuilder(
            animation: oven,
            builder: (context, _) => SizedBox(
              height: 60,
              width: w,
              child: Stack(children: [
                Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30))),
                Positioned(
                  left: (center - zone / 2) * w,
                  width: zone * w,
                  top: 0,
                  bottom: 0,
                  child: Container(decoration: BoxDecoration(color: Colors.green.shade300, borderRadius: BorderRadius.circular(30))),
                ),
                Positioned(left: oven.value * w - 4, top: 0, bottom: 0, child: Container(width: 8, color: kBrown)),
              ]),
            ),
          );
        }),
        const SizedBox(height: 30),
        const Text('🍞', style: TextStyle(fontSize: 90)),
        const SizedBox(height: 30),
        SizedBox(
          width: 200,
          height: 56,
          child: FilledButton(onPressed: _bakeTap, child: const Text('الان! ✋', style: TextStyle(fontSize: 22))),
        ),
      ]);

  Widget _decorate() => Column(children: [
        Text(bakeText, style: kHeading),
        const SizedBox(height: 8),
        const Text('تزئین رو دقیقاً به ترتیب سفارش انجام بده:'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (int i = 0; i < lv.toppings.length; i++)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: i < placed.length ? Colors.green.shade100 : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: i == placed.length ? kPink : Colors.transparent, width: 2),
                ),
                child: Text(lv.toppings[i], style: const TextStyle(fontSize: 26)),
              ),
          ],
        ),
        const Spacer(),
        Text(placed.join(' '), style: const TextStyle(fontSize: 34)),
        const Text('🎂', style: TextStyle(fontSize: 110)),
        const Spacer(),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: toppingPalette.map((t) {
            return GestureDetector(
              onTap: () => _top(t),
              child: Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: wrong == t ? Colors.red.shade100 : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: kPink, width: 2),
                ),
                child: Text(t, style: const TextStyle(fontSize: 32)),
              ),
            );
          }).toList(),
        ),
      ]);

  Widget _body() {
    switch (step) {
      case 0:
        return _ingredients();
      case 1:
        return _mix();
      case 2:
        return _bake();
      default:
        return _decorate();
    }
  }

  @override
  Widget build(BuildContext context) {
    const labels = ['مواد', 'مخلوط', 'پخت', 'تزئین'];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBg,
        title: Text(lv.title),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Center(
              child: Text('⏱ ${fa(max(timeLeft, 0))}',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: timeLeft <= 10 ? Colors.red : kBrown)),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(children: [
          Text('${lv.customer}: «${lv.cake} می‌خوام!»', style: const TextStyle(color: kBrown)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (int i = 0; i < 4; i++)
                Text(labels[i],
                    style: TextStyle(
                        fontWeight: i == step ? FontWeight.bold : FontWeight.normal,
                        color: i == step ? kPink : Colors.grey)),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(child: _body()),
        ]),
      ),
    );
  }
}
