import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/savings_card.dart';
import '../services/app_state.dart';

const _ink = Color(0xFF1E2B22);
const _muted = Color(0xFF6B7280);

class SavingsCardsScreen extends StatelessWidget {
  const SavingsCardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cards = context.watch<AppState>().savingsCards;

    return Scaffold(
      appBar: AppBar(title: const Text('Savings cards')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddSavingsCardSheet(context),
        icon: const Icon(Icons.add_card_rounded),
        label: const Text('Add card'),
      ),
      body: cards.isEmpty
          ? const _EmptyCards()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              itemCount: cards.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) => SavingsCardView(
                card: cards[index],
                onTap: () => showSavingsCardBarcode(context, cards[index]),
              ),
            ),
    );
  }
}

class _EmptyCards extends StatelessWidget {
  const _EmptyCards();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wallet_rounded, size: 72, color: Color(0xFFA5D6A7)),
            SizedBox(height: 16),
            Text(
              'No savings cards yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _ink,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Add your Xtra Savings or SPAR Rewards card and show its '
              'barcode at the till.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wallet-style card face.
class SavingsCardView extends StatelessWidget {
  final SavingsCard card;
  final VoidCallback? onTap;
  final bool compact;

  const SavingsCardView({
    super.key,
    required this.card,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = card.program.color;

    return Material(
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, Color.lerp(color, Colors.black, 0.35)!],
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: AspectRatio(
            aspectRatio: compact ? 1.75 : 1.9,
            child: Padding(
              padding: EdgeInsets.all(compact ? 14 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          card.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: compact ? 14 : 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.loyalty_rounded,
                        color: Colors.white70,
                        size: compact ? 18 : 24,
                      ),
                    ],
                  ),
                  if (!compact && card.nickname?.isNotEmpty == true)
                    Text(
                      card.program.label,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  const Spacer(),
                  Text(
                    compact ? card.maskedNumber : card.formattedNumber,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 14 : 20,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: compact ? 4 : 8),
                  Row(
                    children: [
                      Icon(
                        Icons.qr_code_2_rounded,
                        color: Colors.white70,
                        size: compact ? 14 : 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Tap to show barcode',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: compact ? 11 : 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows the card's barcode full-width so it can be scanned at the till.
Future<void> showSavingsCardBarcode(BuildContext context, SavingsCard card) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              card.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _ink,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Show this barcode to the cashier',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: BarcodeWidget(
                barcode: Barcode.code128(),
                data: card.number,
                height: 110,
                drawText: false,
              ),
            ),
            const SizedBox(height: 14),
            SelectableText(
              card.formattedNumber,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: card.number));
                      if (sheetContext.mounted) {
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                          const SnackBar(content: Text('Card number copied')),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Copy number'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                    ),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: sheetContext,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Remove card?'),
                          content: Text(
                            'Remove ${card.title} from this device?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, true),
                              child: const Text('Remove'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true && sheetContext.mounted) {
                        await sheetContext
                            .read<AppState>()
                            .removeSavingsCard(card.id);
                        if (sheetContext.mounted) Navigator.pop(sheetContext);
                      }
                    },
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Remove'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// Form for adding a savings card.
Future<void> showAddSavingsCardSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => const _AddCardSheet(),
  );
}

class _AddCardSheet extends StatefulWidget {
  const _AddCardSheet();

  @override
  State<_AddCardSheet> createState() => _AddCardSheetState();
}

class _AddCardSheetState extends State<_AddCardSheet> {
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  final _nicknameController = TextEditingController();
  var _program = SavingsProgram.shopriteXtraSavings;

  @override
  void dispose() {
    _numberController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await context.read<AppState>().addSavingsCard(
          program: _program,
          number: _numberController.text.replaceAll(' ', ''),
          nickname: _nicknameController.text,
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Add savings card',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: _ink,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Saved only on this device.',
              style: TextStyle(color: _muted),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final program in SavingsProgram.values)
                  ChoiceChip(
                    label: Text(program.label),
                    selected: _program == program,
                    showCheckmark: false,
                    selectedColor: program.color,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _program == program ? Colors.white : _ink,
                    ),
                    onSelected: (_) => setState(() => _program = program),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _numberController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
              ],
              decoration: _decoration('Card number', Icons.credit_card_rounded),
              validator: (value) {
                final digits = (value ?? '').replaceAll(' ', '');
                if (digits.length < 6 || digits.length > 24) {
                  return 'Enter the number printed under the barcode';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _nicknameController,
              textCapitalization: TextCapitalization.words,
              decoration: _decoration(
                'Nickname (optional)',
                Icons.edit_outlined,
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Save card',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xFFF4F5F2),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }
}
