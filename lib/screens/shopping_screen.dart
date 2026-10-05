import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/app_state.dart';
import '../widgets/camera_scanner.dart';
import '../widgets/web_camera_scanner.dart';
import '../models/detected_product.dart';
import '../utils/currency.dart';

class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key});

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  bool _showScanner = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(appState.selectedStore?.name ?? 'Shopping'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                appState.clearStoreSelection();
              },
            ),
            actions: [
              if (appState.basketItemCount > 0)
                IconButton(
                  icon: Badge(
                    label: Text('${appState.basketItemCount}'),
                    child: const Icon(Icons.shopping_cart),
                  ),
                  onPressed: () {
                    _showBasketBottomSheet(context, appState);
                  },
                ),
            ],
          ),
          body: _showScanner
              ? (kIsWeb
                  ? WebCameraScanner(
                      onProductDetected: (product) {
                        appState.addProductToBasket(product);
                        _showProductAddedSnackBar(context, product);
                      },
                      onClose: () {
                        setState(() {
                          _showScanner = false;
                        });
                      },
                    )
                  : CameraScanner(
                      onProductDetected: (product) {
                        appState.addProductToBasket(product);
                        _showProductAddedSnackBar(context, product);
                      },
                      onClose: () {
                        setState(() {
                          _showScanner = false;
                        });
                      },
                    ))
              : _buildShoppingDashboard(context, appState),
          floatingActionButton: _showScanner
              ? null
              : FloatingActionButton.extended(
                  onPressed: () {
                    setState(() {
                      _showScanner = true;
                    });
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Scan Products'),
                  backgroundColor: const Color(0xFF667eea),
                ),
        );
      },
    );
  }

  Widget _buildShoppingDashboard(BuildContext context, AppState appState) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF8FAFC),
            Color(0xFFE2E8F0),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Store info
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFF667eea).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Center(
                        child: Text(
                          appState.selectedStore?.icon ?? '🛒',
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appState.selectedStore?.name ?? 'Store',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2d3748),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            appState.selectedStore?.description ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF718096),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Shopping stats
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Items',
                      '${appState.basketItemCount}',
                      Icons.shopping_basket,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Total',
                      formatZar(appState.basketTotal),
                      Icons.payments_outlined,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Instructions or basket preview
              if (appState.basketItemCount == 0)
                _buildInstructions()
              else
                _buildBasketPreview(context, appState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2d3748),
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF718096),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            const Text(
              'Ready to Scan!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2d3748),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tap the camera button to start scanning products with AI-powered text recognition',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF718096),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasketPreview(BuildContext context, AppState appState) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your Basket',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2d3748),
                ),
              ),
              TextButton(
                onPressed: () {
                  _showBasketBottomSheet(context, appState);
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: appState.shoppingBasket.length.clamp(0, 3),
              itemBuilder: (context, index) {
                final product = appState.shoppingBasket[index];
                return _buildBasketItem(product);
              },
            ),
          ),
          if (appState.basketItemCount > 3)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '... and ${appState.basketItemCount - 3} more items',
                style: const TextStyle(
                  color: Color(0xFF718096),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBasketItem(DetectedProduct product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2d3748),
                  ),
                ),
                Text(
                  'Qty: ${product.quantity}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF718096),
                  ),
                ),
              ],
            ),
          ),
          Text(
            formatZar(product.lineTotal),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2d3748),
            ),
          ),
        ],
      ),
    );
  }

  void _showBasketBottomSheet(BuildContext context, AppState appState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Shopping Basket',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (appState.basketItemCount > 0)
                        TextButton(
                          onPressed: () {
                            appState.clearBasket();
                            Navigator.pop(context);
                          },
                          child: const Text('Clear All'),
                        ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: appState.basketItemCount == 0
                      ? const Center(
                          child: Text(
                            'Your basket is empty\nStart scanning products!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF718096),
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: appState.shoppingBasket.length,
                          itemBuilder: (context, index) {
                            final product = appState.shoppingBasket[index];
                            return _buildFullBasketItem(
                                context, appState, product, index);
                          },
                        ),
                ),
                if (appState.basketItemCount > 0) ...[
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              formatZar(appState.basketTotal),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF667eea),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _showCheckoutDialog(context, appState);
                            },
                            child: const Text('Generate Receipt'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFullBasketItem(BuildContext context, AppState appState,
      DetectedProduct product, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatZar(product.price)} each',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF718096),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  appState.updateProductQuantity(index, product.quantity - 1);
                },
                icon: const Icon(Icons.remove_circle_outline),
                iconSize: 20,
              ),
              Text(
                '${product.quantity}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              IconButton(
                onPressed: () {
                  appState.updateProductQuantity(index, product.quantity + 1);
                },
                icon: const Icon(Icons.add_circle_outline),
                iconSize: 20,
              ),
              const SizedBox(width: 8),
              Text(
                formatZar(product.lineTotal),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showProductAddedSnackBar(
      BuildContext context, DetectedProduct product) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${product.productName} to basket'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            _showBasketBottomSheet(context, context.read<AppState>());
          },
        ),
      ),
    );
  }

  void _showCheckoutDialog(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        var isSaving = false;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            title: const Text('Generate Receipt'),
            content: Text(
              'Save a receipt for ${appState.basketItemCount} items totaling ${formatZar(appState.basketTotal)}?',
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        setDialogState(() => isSaving = true);
                        try {
                          final receipt = await appState.completeCheckout();
                          if (!dialogContext.mounted || !mounted) return;
                          Navigator.pop(dialogContext);
                          _showReceiptDialog(context, receipt);
                        } catch (error) {
                          if (!dialogContext.mounted) return;
                          setDialogState(() => isSaving = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Could not save receipt: $error'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Receipt'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showReceiptDialog(BuildContext context, Map<String, dynamic> receipt) {
    final items = (receipt['items'] as List).cast<Map<String, dynamic>>();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Receipt saved'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${receipt['store_name']}  |  ${receipt['created_at']}'),
                const Divider(height: 24),
                for (final item in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            '${item['name']}  x${item['quantity']}',
                          ),
                        ),
                        Text(formatZar((item['line_total'] as num).toDouble())),
                      ],
                    ),
                  ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      formatZar((receipt['total'] as num).toDouble()),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () => _printReceipt(context, receipt),
            icon: const Icon(Icons.print),
            label: const Text('Print / Save PDF'),
          ),
        ],
      ),
    );
  }

  Future<void> _printReceipt(
    BuildContext context,
    Map<String, dynamic> receipt,
  ) async {
    try {
      final document = pw.Document();
      final items = (receipt['items'] as List).cast<Map<String, dynamic>>();
      document.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.roll80,
          margin: const pw.EdgeInsets.all(16),
          build: (context) => [
            pw.Center(
              child: pw.Text(
                'SMART BASKET',
                style: const pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text('${receipt['store_name']}'),
            pw.Text('Receipt: ${receipt['id']}'),
            pw.Text('Date: ${receipt['created_at']}'),
            pw.Divider(),
            for (final item in items) ...[
              pw.Text('${item['name']} x${item['quantity']}'),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    '${formatZar((item['unit_price'] as num).toDouble())} each',
                  ),
                  pw.Text(
                    formatZar((item['line_total'] as num).toDouble()),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
            ],
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'TOTAL',
                  style: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  formatZar((receipt['total'] as num).toDouble()),
                  style: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
            pw.SizedBox(height: 14),
            pw.Center(child: pw.Text('Thank you for shopping')),
          ],
        ),
      );

      await Printing.layoutPdf(onLayout: (_) => document.save());
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not print receipt: $error')),
      );
    }
  }
}
