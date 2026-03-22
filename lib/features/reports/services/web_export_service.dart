import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:agricola_core/agricola_core.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:web/web.dart' as web;

/// Handles CSV building, PDF generation, file downloads, and browser printing.
/// All methods are static — no Riverpod dependencies.
class WebExportService {
  WebExportService._();

  static final _dateFormat = DateFormat('yyyy-MM-dd');
  static final _displayDateFormat = DateFormat('dd MMM yyyy');
  static final _filenameDate = DateFormat('yyyyMMdd');
  static final _currencyFormat = NumberFormat.currency(symbol: 'P');

  // ---------------------------------------------------------------------------
  // CSV
  // ---------------------------------------------------------------------------

  static String cropsAsCsv(List<CropModel> crops, AppLanguage lang) {
    final headers = [
      t('crop_type', lang),
      t('field_name', lang),
      t('field_size', lang),
      t('planting_date', lang),
      t('expected_harvest_date', lang),
      t('estimated_yield', lang),
      t('storage_method', lang),
    ];
    final rows = crops.map((c) => [
          c.cropType,
          c.fieldName,
          '${c.fieldSize} ${c.fieldSizeUnit}',
          _dateFormat.format(c.plantingDate),
          _dateFormat.format(c.expectedHarvestDate),
          '${c.estimatedYield} ${c.yieldUnit}',
          c.storageMethod,
        ]);
    return _buildCsv(headers, rows);
  }

  static String inventoryAsCsv(List<InventoryModel> items, AppLanguage lang) {
    final headers = [
      t('crop_type', lang),
      t('quantity', lang),
      t('unit', lang),
      t('storage_date', lang),
      t('storage_location', lang),
      t('condition', lang),
    ];
    final rows = items.map((i) => [
          i.cropType,
          '${i.quantity}',
          i.unit,
          _dateFormat.format(i.storageDate),
          i.storageLocation,
          i.condition,
        ]);
    return _buildCsv(headers, rows);
  }

  static String purchasesAsCsv(List<PurchaseModel> purchases, AppLanguage lang) {
    final headers = [
      t('seller_name', lang),
      t('crop_type', lang),
      t('quantity', lang),
      t('unit', lang),
      t('price_per_unit', lang),
      t('total_amount', lang),
      t('purchase_date', lang),
    ];
    final rows = purchases.map((p) => [
          p.sellerName,
          p.cropType,
          '${p.quantity}',
          p.unit,
          _currencyFormat.format(p.pricePerUnit),
          _currencyFormat.format(p.totalAmount),
          _dateFormat.format(p.purchaseDate),
        ]);
    return _buildCsv(headers, rows);
  }

  static String ordersAsCsv(List<OrderModel> orders, AppLanguage lang) {
    final headers = [
      t('order_id', lang),
      t('status', lang),
      t('total_amount', lang),
      t('created_at', lang),
    ];
    final rows = orders.map((o) => [
          o.id ?? '-',
          o.status,
          _currencyFormat.format(o.totalAmount),
          _dateFormat.format(o.createdAt),
        ]);
    return _buildCsv(headers, rows);
  }

  static String harvestsAsCsv(List<HarvestModel> harvests, AppLanguage lang) {
    final headers = [
      t('harvest_date', lang),
      t('actual_yield', lang),
      t('unit', lang),
      t('quality', lang),
      t('loss_amount', lang),
      t('loss_reason', lang),
      t('storage_location', lang),
    ];
    final rows = harvests.map((h) => [
          _dateFormat.format(h.harvestDate),
          '${h.actualYield}',
          h.yieldUnit,
          h.quality,
          '${h.lossAmount ?? 0}',
          h.lossReason ?? '-',
          h.storageLocation,
        ]);
    return _buildCsv(headers, rows);
  }

  static void downloadCsv(String csvContent, String filename) {
    _downloadBytes(
      utf8.encode(csvContent),
      '$filename.csv',
      'text/csv;charset=utf-8;',
    );
  }

  static String csvFilename(String dataset) =>
      '${dataset}_${_filenameDate.format(DateTime.now())}';

  static String _buildCsv(
    List<String> headers,
    Iterable<List<String>> rows,
  ) {
    final buf = StringBuffer();
    buf.writeln(headers.map(_escapeCsvField).join(','));
    for (final row in rows) {
      buf.writeln(row.map(_escapeCsvField).join(','));
    }
    return buf.toString();
  }

  static String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  // ---------------------------------------------------------------------------
  // PDF
  // ---------------------------------------------------------------------------

  static Future<Uint8List> buildFarmSummaryPdf({
    required List<CropModel> crops,
    required List<HarvestModel> harvests,
    required List<InventoryModel> inventory,
    required AnalyticsModel analytics,
    required AppLanguage lang,
    required String periodLabel,
  }) async {
    final doc = pw.Document();
    final now = _displayDateFormat.format(DateTime.now());

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _pdfHeader(t('farm_summary', lang), now, periodLabel, lang),
              pw.SizedBox(height: 16),
              _pdfStatsTable([
                [t('active_crops', lang), '${analytics.crops.active}'],
                [t('harvested', lang), '${analytics.crops.harvested}'],
                [
                  t('total_yield', lang),
                  '${analytics.harvests.totalYield.toStringAsFixed(1)} kg'
                ],
                [
                  t('total_loss', lang),
                  '${analytics.harvests.totalLoss.toStringAsFixed(1)} kg'
                ],
                [t('inventory', lang), '${analytics.inventory.total}'],
                [
                  t('total_field_size', lang),
                  '${analytics.crops.totalFieldSize.toStringAsFixed(1)} ha'
                ],
              ]),
              pw.SizedBox(height: 24),
              pw.Text(
                '${t('generated_on', lang)}: $now',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  static Future<Uint8List> buildBusinessSummaryPdf({
    required List<PurchaseModel> purchases,
    required List<OrderModel> orders,
    required List<InventoryModel> inventory,
    required AnalyticsModel analytics,
    required AppLanguage lang,
    required String periodLabel,
  }) async {
    final doc = pw.Document();
    final now = _displayDateFormat.format(DateTime.now());

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _pdfHeader(t('business_summary', lang), now, periodLabel, lang),
              pw.SizedBox(height: 16),
              _pdfStatsTable([
                [t('active_orders', lang), '${analytics.orders.active}'],
                [
                  t('period_revenue', lang),
                  _currencyFormat.format(analytics.orders.periodRevenue)
                ],
                [
                  t('total_purchases', lang),
                  '${analytics.purchases.total}'
                ],
                [
                  t('inventory', lang),
                  '${analytics.inventory.total}'
                ],
                [
                  t('active_listings', lang),
                  '${analytics.marketplace.activeListings}'
                ],
                [
                  t('unique_suppliers', lang),
                  '${analytics.purchases.uniqueSuppliers}'
                ],
              ]),
              pw.SizedBox(height: 24),
              pw.Text(
                '${t('generated_on', lang)}: $now',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  static Future<void> downloadPdf(Uint8List pdfBytes, String filename) async {
    _downloadBytes(pdfBytes, '$filename.pdf', 'application/pdf');
  }

  static String pdfFilename(String type) =>
      '${type}_summary_${_filenameDate.format(DateTime.now())}';

  static pw.Widget _pdfHeader(
    String title,
    String date,
    String period,
    AppLanguage lang,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          '${t('date_range', lang)}: $period',
          style: const pw.TextStyle(fontSize: 10),
        ),
        pw.SizedBox(height: 8),
        pw.Divider(),
      ],
    );
  }

  static pw.Widget _pdfStatsTable(List<List<String>> rows) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1),
      },
      children: rows.map((row) {
        return pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ),
              child: pw.Text(
                row[0],
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ),
              child: pw.Text(row[1]),
            ),
          ],
        );
      }).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // Print
  // ---------------------------------------------------------------------------

  static void printPage() {
    web.window.print();
  }

  // ---------------------------------------------------------------------------
  // Internal download helper
  // ---------------------------------------------------------------------------

  static void _downloadBytes(
    List<int> bytes,
    String filename,
    String mimeType,
  ) {
    final uint8List = Uint8List.fromList(bytes);
    final blob = web.Blob(
      [uint8List.toJS].toJS,
      web.BlobPropertyBag(type: mimeType),
    );
    final url = web.URL.createObjectURL(blob);
    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..download = filename;
    anchor.click();
    web.URL.revokeObjectURL(url);
  }
}
