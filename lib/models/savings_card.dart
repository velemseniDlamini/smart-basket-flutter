import 'package:flutter/material.dart';

/// Loyalty programme a savings card belongs to.
enum SavingsProgram {
  shopriteXtraSavings('Shoprite Xtra Savings', 'shoprite', Color(0xFFD20A0A)),
  sparRewards('SPAR Rewards', 'spar', Color(0xFF00843D)),
  other('Other card', null, Color(0xFF37474F));

  final String label;
  final String? storeId;
  final Color color;

  const SavingsProgram(this.label, this.storeId, this.color);
}

/// A store loyalty card saved on this device so its barcode can be shown at
/// the till.
class SavingsCard {
  final String id;
  final SavingsProgram program;
  final String number;
  final String? nickname;

  const SavingsCard({
    required this.id,
    required this.program,
    required this.number,
    this.nickname,
  });

  String get title => nickname?.isNotEmpty == true ? nickname! : program.label;

  /// Card number grouped in fours for readability.
  String get formattedNumber {
    final buffer = StringBuffer();
    for (var i = 0; i < number.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(number[i]);
    }
    return buffer.toString();
  }

  String get maskedNumber => number.length <= 4
      ? number
      : '•••• ${number.substring(number.length - 4)}';

  factory SavingsCard.fromJson(Map<String, dynamic> json) {
    return SavingsCard(
      id: json['id'] as String,
      program: SavingsProgram.values.firstWhere(
        (program) => program.name == json['program'],
        orElse: () => SavingsProgram.other,
      ),
      number: json['number'] as String,
      nickname: json['nickname'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'program': program.name,
        'number': number,
        'nickname': nickname,
      };
}
