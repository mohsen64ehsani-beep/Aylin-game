import 'package:flutter/material.dart';
import 'data.dart';
import 'game.dart';
import 'play.dart';

Widget statChip(String e, String v) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Text('$e $v', style: kHeading),
    );

class BigButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const BigButton(this.text, this.onTap, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SizedBox(
          width: double.infinity,
          height: 58,
          child: FilledButton(onPressed: onTap, child: Text(text, style: const TextStyle(fontSize: 20))),
        ),
      );
}

class Aylin extends StatelessWidget {
  final double size;
  const Aylin({super.key, this.size = 80});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: game,
        builder: (context, _) => Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(height: size * 0.55, child: Text(game.hat, style: TextStyle(fontSize: size * 0.45))),
          Text('👧', style: TextStyle(fontSize: size)),
        ]),
      );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: game,
          builder: (context, _) {
            final decor = shopItems.where((i) => i.group == 'decor' && game.owned.contains(i.id));
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  statChip('🪙', fa(game.coins)),
                  statChip('⭐', fa(game.totalStars)),
                ]),
                const Spacer(),
                const Aylin(size: 100),
                const SizedBox(height: 8),
                const Text('قنادی آیلین', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: kBrown)),
                const SizedBox(height: 6),
                const Text('قنادی کوچیکت رو معروف‌ترین قنادی شهر کن!', textAlign: TextAlign.center, style: TextStyle(color: kBrown)),
                const SizedBox(height: 14),
                Wrap(spacing: 10, children: decor.map((d) => Text(d.emoji, style: const TextStyle(fontSize: 34))).toList()),
                const Spacer(),
                BigButton('شروع بازی 🧁', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LevelMapScreen()))),
                BigButton('فروشگاه 🛍️', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopScreen()))),
              ]),
            );
          },
        ),
      ),
    );
  }
}

class LevelMapScreen extends StatelessWidget {
  const LevelMapScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مرحله‌ها'), backgroundColor: kBg),
      body: ListenableBuilder(
        listenable: game,
        builder: (context, _) => GridView.count(
          padding: const EdgeInsets.all(16),
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.95,
          children: levels.map((l) {
            final open = game.isUnlocked(l);
            final s = game.starsOf(l.id);
            return GestureDetector(
              onTap: () {
                if (open) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => PlayScreen(l)));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('اول مرحله قبلی رو تموم کن و ${fa(l.needStars)} ستاره جمع کن')));
                }
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: open ? Colors.white : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: kPink, width: 2),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(open ? l.emoji : '🔒', style: const TextStyle(fontSize: 46)),
                  const SizedBox(height: 6),
                  Text('${fa(l.id)}. ${l.title}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: kBrown)),
                  const SizedBox(height: 6),
                  Text(open ? ('⭐' * s) + ('☆' * (3 - s)) : 'نیاز: ${fa(l.needStars)} ⭐'),
                ]),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  Widget _tile(ShopItem it) {
    final has = game.owned.contains(it.id);
    final locked = it.requires != null && !game.owned.contains(it.requires);
    Widget action;
    if (has && it.group == 'hat') {
      final on = game.hat == it.emoji;
      action = OutlinedButton(onPressed: () => game.setHat(on ? '' : it.emoji), child: Text(on ? 'درآر' : 'بپوش'));
    } else if (has) {
      action = const Text('✅ داری');
    } else {
      action = FilledButton(
        onPressed: (locked || game.coins < it.price) ? null : () => game.buy(it),
        child: Text('🪙 ${fa(it.price)}'),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Text(it.emoji, style: const TextStyle(fontSize: 34)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(it.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(locked ? 'اول مورد قبلی رو بخر' : it.desc, style: const TextStyle(fontSize: 12)),
            ]),
          ),
          action,
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('فروشگاه'),
        backgroundColor: kBg,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ListenableBuilder(listenable: game, builder: (c, _) => statChip('🪙', fa(game.coins))),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: game,
        builder: (context, _) => ListView(padding: const EdgeInsets.all(16), children: [
          for (final g in shopGroups.entries) ...[
            Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(g.value, style: kHeading)),
            for (final it in shopItems.where((i) => i.group == g.key)) _tile(it),
          ],
        ]),
      ),
    );
  }
}
