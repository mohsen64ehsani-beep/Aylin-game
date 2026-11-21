import 'package:flutter/material.dart';

const kPink = Color(0xFFFF7FA8);
const kBg = Color(0xFFFFF0F5);
const kBrown = Color(0xFF6D4C41);
const kHeading = TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kBrown);

String fa(int n) => n.toString().replaceAllMapped(RegExp(r'\d'), (m) => '۰۱۲۳۴۵۶۷۸۹'[int.parse(m[0]!)]);

class Ingredient {
  final String id, emoji, name;
  const Ingredient(this.id, this.emoji, this.name);
}

const allIngredients = [
  Ingredient('flour', '🌾', 'آرد'),
  Ingredient('egg', '🥚', 'تخم‌مرغ'),
  Ingredient('milk', '🥛', 'شیر'),
  Ingredient('sugar', '🍬', 'شکر'),
  Ingredient('butter', '🧈', 'کره'),
  Ingredient('choco', '🍫', 'شکلات'),
  Ingredient('vanilla', '🌼', 'وانیل'),
  Ingredient('cream', '🍦', 'خامه'),
  Ingredient('lemon', '🍋', 'لیمو'),
  Ingredient('carrot', '🥕', 'هویج'),
  Ingredient('nuts', '🥜', 'گردو'),
  Ingredient('salt', '🧂', 'نمک'),
];

Ingredient byId(String id) => allIngredients.firstWhere((i) => i.id == id);

const toppingPalette = ['🍓', '🍒', '🍫', '🍬', '⭐', '🌸', '🍋', '🍇'];

class LevelDef {
  final int id, seconds, needStars;
  final String title, customer, emoji;
  final List<String> ingredients, toppings;
  final double zone;
  const LevelDef(this.id, this.title, this.customer, this.emoji, this.ingredients,
      this.toppings, this.seconds, this.zone, this.needStars);
}

const levels = [
  LevelDef(1, 'کیک اسفنجی', 'خانم مریم', '🍰', ['flour', 'egg', 'sugar'], ['🍓', '🍓'], 90, 0.30, 0),
  LevelDef(2, 'کاپ‌کیک وانیلی', 'آقا رضا', '🧁', ['flour', 'egg', 'milk', 'vanilla'], ['🍒', '🍓', '🍒'], 90, 0.27, 2),
  LevelDef(3, 'کیک شکلاتی', 'سارا خانم', '🍫', ['flour', 'egg', 'choco', 'butter'], ['🍫', '🍓', '🍒', '🍫'], 85, 0.25, 4),
  LevelDef(4, 'کیک هویج', 'مامان‌بزرگ', '🥕', ['flour', 'egg', 'carrot', 'nuts', 'sugar'], ['⭐', '🍋', '⭐', '🍋'], 85, 0.23, 7),
  LevelDef(5, 'تارت لیمو', 'دکتر نیلوفر', '🍋', ['flour', 'butter', 'lemon', 'sugar', 'egg'], ['🍋', '🍋', '🍓', '🌸', '🍋'], 80, 0.21, 10),
  LevelDef(6, 'کیک تولد', 'کوچولوی تولدی', '🎂', ['flour', 'egg', 'milk', 'sugar', 'vanilla', 'cream'], ['🍓', '🍒', '🍬', '⭐', '🍬', '🍒'], 80, 0.19, 13),
  LevelDef(7, 'کیک عروسی', 'عروس خانم', '👰', ['flour', 'egg', 'butter', 'sugar', 'vanilla', 'cream', 'milk'], ['🌸', '🍓', '🌸', '⭐', '🌸', '🍇', '🌸'], 75, 0.17, 16),
  LevelDef(8, 'کیک ویژه (مشتری سخت‌گیر)', 'سرآشپز مشهور', '👨‍🍳', ['flour', 'egg', 'choco', 'butter', 'cream', 'nuts', 'sugar'], ['🍫', '🍇', '🍒', '🍫', '⭐', '🍓', '🍇', '⭐'], 75, 0.15, 19),
];

class ShopItem {
  final String id, name, emoji, group, desc;
  final int price;
  final String? requires;
  const ShopItem(this.id, this.name, this.emoji, this.group, this.price, this.desc, [this.requires]);
}

const shopGroups = {'upgrade': 'ارتقاها', 'hat': 'ظاهر آیلین', 'decor': 'دکور قنادی'};

const shopItems = [
  ShopItem('oven1', 'فر نقره‌ای', '🔥', 'upgrade', 120, 'ناحیه پخت عریض‌تر می‌شه'),
  ShopItem('oven2', 'فر طلایی', '🌟', 'upgrade', 300, 'ناحیه پخت خیلی عریض‌تر', 'oven1'),
  ShopItem('mixer1', 'همزن برقی', '🌀', 'upgrade', 100, 'مخلوط کردن سریع‌تر'),
  ShopItem('mixer2', 'همزن حرفه‌ای', '⚡', 'upgrade', 280, 'مخلوط کردن خیلی سریع‌تر', 'mixer1'),
  ShopItem('clock', 'ساعت قنادی', '⏰', 'upgrade', 250, '۱۵ ثانیه وقت بیشتر در هر مرحله'),
  ShopItem('bow', 'پاپیون', '🎀', 'hat', 60, 'پاپیون صورتی'),
  ShopItem('flower', 'گل سر', '🌸', 'hat', 90, 'گل سر قشنگ'),
  ShopItem('hatc', 'کلاه حصیری', '👒', 'hat', 140, 'کلاه تابستونی'),
  ShopItem('crown', 'تاج', '👑', 'hat', 300, 'تاج ملکه قنادی'),
  ShopItem('tulip', 'گل لاله', '🌷', 'decor', 70, 'برای میز قنادی'),
  ShopItem('balloon', 'بادکنک', '🎈', 'decor', 90, 'فضا رو شاد می‌کنه'),
  ShopItem('bouquet', 'دسته گل', '💐', 'decor', 110, 'دسته گل تازه'),
  ShopItem('cat', 'گربه ناز', '🐈', 'decor', 200, 'مهمون همیشگی قنادی'),
  ShopItem('sparkle', 'چراغ‌های برّاق', '✨', 'decor', 150, 'قنادی رو می‌درخشونه'),
];
