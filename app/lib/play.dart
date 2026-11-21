import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'data.dart';
import 'game.dart';
import 'music.dart';

class PlayScreen extends StatefulWidget {
  final LevelDef level;
  const PlayScreen(this.level, {super.key});
  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> with SingleTickerProviderStateMixin {
  LevelDef get lv => widget.level;
  int step = 0, timeLeft = 0, totalTime = 0, mistakes = 0, bakePenalty = 0;
  Timer? timer;
  final Set<String> got = {};
  final List<String> placed = [];
  String? wrong;
  String bakeText = '';
  double mix = 0, batter = .1;
  bool done = false;
  late final AnimationController oven;
  late final double center, zone;
  late final List<Ingredient> pool;
  final music = BakeryMusic.instance;

  @override
  void initState() {
    super.initState();
    music.start();
    totalTime = lv.seconds + game.extraTime;
    timeLeft = totalTime;
    center = .3 + Random(lv.id * 7).nextDouble() * .4;
    zone = lv.zone + game.ovenBonus;
    pool = List<Ingredient>.of(allIngredients)..shuffle(Random(lv.id));
    oven = AnimationController(vsync: this, duration: Duration(milliseconds: max(700, 1500 - lv.id * 90)))..repeat(reverse: true);
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || done) return;
      setState(() => timeLeft--);
      if (timeLeft <= 0) _finish(false);
    });
  }

  @override
  void dispose() { timer?.cancel(); oven.dispose(); super.dispose(); }

  void _mistake(String id) {
    setState(() { mistakes++; wrong = id; });
    Future.delayed(const Duration(milliseconds: 400), () { if (mounted) setState(() => wrong = null); });
  }

  void _pick(Ingredient item) {
    if (done || got.contains(item.id)) return;
    if (!lv.ingredients.contains(item.id)) { _mistake(item.id); return; }
    setState(() { got.add(item.id); if (got.length == lv.ingredients.length) step = 1; });
  }

  void _bake() {
    final d = (oven.value - center).abs();
    setState(() {
      bakePenalty = d <= zone / 2 ? 0 : d <= zone ? 10 : 25;
      bakeText = bakePenalty == 0 ? 'پخت عالی و طلایی! 😍' : bakePenalty == 10 ? 'پخت قابل قبول 🙂' : 'کمی بیش از حد پخته شد 😅';
      step = 4;
    });
  }

  void _top(String t) {
    if (done) return;
    if (placed.length < lv.toppings.length && lv.toppings[placed.length] == t) {
      setState(() => placed.add(t));
      if (placed.length == lv.toppings.length) _finish(true);
    } else { _mistake(t); }
  }

  void _finish(bool success) {
    if (done) return;
    done = true; timer?.cancel();
    int stars = 0, reward = 0;
    if (success) {
      final bonus = (max(timeLeft, 0) * 10 / totalTime).round();
      final score = (100 - mistakes * 8 - bakePenalty + bonus).clamp(0, 110).toInt();
      stars = score >= 95 ? 3 : score >= 75 ? 2 : 1;
      reward = 20 + score ~/ 2 + lv.id * 5 + stars * 10;
      game.finishLevel(lv.id, stars, reward);
    }
    final index = levels.indexWhere((l) => l.id == lv.id);
    final next = index + 1 < levels.length ? levels[index + 1] : null;
    final canNext = success && next != null && game.isUnlocked(next);
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => AlertDialog(
      title: Text(success ? 'سفارش تحویل شد! 🎉' : 'زمان سفارش تمام شد ⏰', textAlign: TextAlign.center),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        if (success) Text('⭐' * stars + '☆' * (3 - stars), style: const TextStyle(fontSize: 34)),
        if (success) Text('🪙 ' + fa(reward) + ' سکه پاداش گرفتی'),
        if (!success) const Text('مشتری منتظر ماند؛ دوباره تلاش کن!'),
      ]),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        if (canNext) FilledButton(onPressed: () { Navigator.pop(ctx); Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PlayScreen(next))); }, child: const Text('مشتری بعدی')),
        OutlinedButton(onPressed: () { Navigator.pop(ctx); Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PlayScreen(lv))); }, child: const Text('تلاش دوباره')),
        TextButton(onPressed: () { Navigator.pop(ctx); Navigator.pop(context); }, child: const Text('بازگشت')),
      ],
    ));
  }

  Widget _customer() {
    const faces = ['👩🏻','👨🏽','👧🏻','👵🏻','👩🏽‍⚕️','👦🏻','👰🏻','👨🏻‍🍳'];
    final face = faces[(lv.id - 1) % faces.length];
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFFE0EC), Color(0xFFFFF2D8)]),
        borderRadius: BorderRadius.circular(22), border: Border.all(color: kPink.withOpacity(.5)),
      ),
      child: Row(children: [
        Container(width: 66, height: 66, alignment: Alignment.center,
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: Text(face, style: const TextStyle(fontSize: 42))),
        const SizedBox(width: 11),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(lv.customer, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBrown)),
          Text('«لطفاً یک ' + lv.title + ' خوشمزه برام آماده کن!»', style: const TextStyle(color: kBrown, fontSize: 13)),
          Text('سفارش ' + fa(lv.id) + '  •  ' + lv.emoji, style: const TextStyle(color: kBrown, fontWeight: FontWeight.bold)),
        ])),
      ]),
    );
  }

  Widget _stages() {
    const names = ['مواد اولیه','هم‌زدن','قالب','فر','تزئین'];
    return Row(children: List.generate(5, (i) => Expanded(child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 2), padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: i <= step ? kPink : Colors.white, borderRadius: BorderRadius.circular(9)),
      child: Text(names[i], textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: i <= step ? Colors.white : kBrown)),
    ))));
  }

  Widget _ingredients() => Column(children: [
    const Text('مواد اولیه سفارش را پیدا کن', style: kHeading),
    Wrap(spacing: 5, runSpacing: 2, children: lv.ingredients.map((id) {
      final item = byId(id);
      return Chip(avatar: Icon(got.contains(id) ? Icons.check_circle : Icons.circle_outlined, size: 16, color: got.contains(id) ? Colors.green : kPink),
        label: Text(item.emoji + ' ' + item.name), backgroundColor: got.contains(id) ? Colors.green.shade50 : Colors.white);
    }).toList()),
    const SizedBox(height: 6),
    Expanded(child: GridView.count(crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8,
      children: pool.map((item) {
        final selected = got.contains(item.id);
        return GestureDetector(onTap: () => _pick(item), child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(color: wrong == item.id ? Colors.red.shade100 : selected ? Colors.green.shade100 : Colors.white,
            borderRadius: BorderRadius.circular(17), border: Border.all(color: selected ? Colors.green : kPink, width: 2)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(item.emoji, style: const TextStyle(fontSize: 34)), Text(item.name),
            if (selected) const Icon(Icons.check_circle, color: Colors.green, size: 17),
          ]),
        ));
      }).toList())),
  ]);

  Widget _mix() => Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Text('خمیر کیک را یکدست و سبک کن', style: kHeading),
    const SizedBox(height: 10),
    const Text('انگشتت را روی کاسه حرکت بده تا خمیر آماده شود'),
    const SizedBox(height: 25),
    GestureDetector(onPanUpdate: (d) {
      if (done || step != 1) return;
      setState(() { mix = min(1, mix + d.delta.distance * game.mixSpeed / 1250); if (mix >= 1) step = 2; });
    }, child: Container(width: 225, height: 225, alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: const RadialGradient(colors: [Colors.white, Color(0xFFFFD7A6)]),
        border: Border.all(color: const Color(0xFFB97846), width: 9), boxShadow: [BoxShadow(color: kBrown.withOpacity(.15), blurRadius: 16)]),
      child: Transform.rotate(angle: mix * 28, child: const Text('🥣', style: TextStyle(fontSize: 105))))),
    const SizedBox(height: 22),
    ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: mix, minHeight: 15, color: kPink, backgroundColor: Colors.white)),
    const SizedBox(height: 8), Text(fa((mix * 100).round()) + '٪ آماده‌سازی خمیر'),
  ]);

  Widget _pan() => Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Text('خمیر را داخل قالب بریز', style: kHeading),
    const SizedBox(height: 8), const Text('چند بار روی قالب بزن تا خمیر کامل داخل آن پخش شود'),
    const SizedBox(height: 24),
    GestureDetector(onTap: () => setState(() { batter = min(1, batter + .22); if (batter >= .99) step = 3; }),
      child: Container(width: 245, height: 205, padding: const EdgeInsets.all(16), alignment: Alignment.bottomCenter,
        decoration: BoxDecoration(color: const Color(0xFFE7B978), borderRadius: BorderRadius.circular(32), border: Border.all(color: const Color(0xFF9B633D), width: 8)),
        child: AnimatedContainer(duration: const Duration(milliseconds: 200), height: 165 * batter,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: const LinearGradient(colors: [Color(0xFFFFE6B0), Color(0xFFD99B50)])),
          alignment: Alignment.center, child: Text(batter > .8 ? 'آماده پخت' : '🥄', style: const TextStyle(fontSize: 24, color: kBrown, fontWeight: FontWeight.bold))))),
    const SizedBox(height: 16), Text('پر شدن قالب: ' + fa((batter * 100).round()) + '٪'),
    const SizedBox(height: 10), FilledButton.icon(onPressed: () => setState(() { batter = 1; step = 3; }),
      icon: const Icon(Icons.local_fire_department), label: const Text('قالب آماده است؛ ببر داخل فر')),
  ]);

  Widget _bakeStage() => Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Text('زمان پخت را دقیق کنترل کن', style: kHeading),
    const SizedBox(height: 10), const Text('وقتی نشانگر روی محدوده سبز است، کیک را خارج کن'),
    const SizedBox(height: 22),
    Container(padding: const EdgeInsets.all(17), decoration: BoxDecoration(color: const Color(0xFF473A43), borderRadius: BorderRadius.circular(23)),
      child: Column(children: [
        const Text('🔥 فر قنادی آیلین 🔥', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 18),
        AnimatedBuilder(animation: oven, builder: (context, _) {
          final w = MediaQuery.of(context).size.width - 100;
          return SizedBox(height: 48, width: w, child: Stack(children: [
            Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24))),
            Positioned(left: (center - zone / 2) * w, width: zone * w, top: 0, bottom: 0,
              child: Container(decoration: BoxDecoration(color: Colors.green.shade400, borderRadius: BorderRadius.circular(24)))),
            Positioned(left: oven.value * w - 3, top: 0, bottom: 0, child: Container(width: 6, color: Colors.red.shade700)),
          ]));
        }),
        const SizedBox(height: 14), const Text('🎂', style: TextStyle(fontSize: 80)),
      ])),
    const SizedBox(height: 20),
    SizedBox(width: 230, height: 54, child: FilledButton.icon(onPressed: _bake,
      icon: const Icon(Icons.pan_tool_alt), label: const Text('خارج کردن کیک از فر'))),
  ]);

  Widget _decorate() => Column(children: [
    Text(bakeText, style: kHeading),
    const Text('تزئین را مطابق طرح سفارش مشتری انجام بده'),
    const SizedBox(height: 8),
    Container(width: double.infinity, padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(children: [
        Text(lv.emoji, style: const TextStyle(fontSize: 58)),
        Wrap(spacing: 3, children: lv.toppings.map((t) => Text(t, style: const TextStyle(fontSize: 23))).toList()),
        Text('طرح مورد نظر ' + lv.customer, style: const TextStyle(color: kBrown, fontWeight: FontWeight.bold)),
      ])),
    Expanded(child: Center(child: Stack(alignment: Alignment.center, children: [
      const Text('🎂', style: TextStyle(fontSize: 118)),
      Positioned(top: 12, child: Text(placed.join(' '), style: const TextStyle(fontSize: 29))),
    ]))),
    Text('تزئین انجام‌شده: ' + fa(placed.length) + ' از ' + fa(lv.toppings.length)),
    const SizedBox(height: 7),
    Wrap(spacing: 8, runSpacing: 7, alignment: WrapAlignment.center, children: toppingPalette.map((t) =>
      GestureDetector(onTap: () => _top(t), child: AnimatedContainer(duration: const Duration(milliseconds: 120),
        width: 53, height: 53, alignment: Alignment.center,
        decoration: BoxDecoration(color: wrong == t ? Colors.red.shade100 : Colors.white, shape: BoxShape.circle, border: Border.all(color: kPink, width: 2)),
        child: Text(t, style: const TextStyle(fontSize: 28))))).toList()),
  ]);

  Widget _stage() {
    switch (step) {
      case 0: return _ingredients();
      case 1: return _mix();
      case 2: return _pan();
      case 3: return _bakeStage();
      default: return _decorate();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFFF7F2),
    appBar: AppBar(backgroundColor: kBg, title: Text(lv.title), actions: [
      IconButton(tooltip: music.enabled ? 'قطع موسیقی' : 'پخش موسیقی',
        onPressed: () => setState(() { music.setEnabled(!music.enabled); }),
        icon: Icon(music.enabled ? Icons.music_note : Icons.music_off, color: kBrown)),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Center(child:
        Text('⏱ ' + fa(max(timeLeft, 0)), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: timeLeft <= 10 ? Colors.red : kBrown)))),
    ]),
    body: SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(13, 8, 13, 12),
      child: Column(children: [_customer(), const SizedBox(height: 10), _stages(), const SizedBox(height: 12), Expanded(child: _stage())]))),
  );
}
