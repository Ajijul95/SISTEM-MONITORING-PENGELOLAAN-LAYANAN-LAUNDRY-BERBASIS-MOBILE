part of '../../main.dart';

extension _OwnerReportsFeature on _HomePageState {
  Widget reportsPage() => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: ordersStream,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('Gagal memuat laporan: ${snap.error}'));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = _inReportPeriod(snap.data!.docs);
        final paid = docs
            .where((doc) => doc.data()['paymentStatus'] == 'Lunas')
            .toList();
        num sum(Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> rows) =>
            rows.fold<num>(
                0,
                (total, doc) =>
                    total +
                    ((doc.data()['amountPaid'] ?? doc.data()['total'] ?? 0)
                        as num));
        final totalWeight = docs.fold<num>(
            0, (total, doc) => total + ((doc.data()['kg'] ?? 0) as num));
        return ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            children: [
              Align(
                  alignment: Alignment.centerRight,
                  child:
                OutlinedButton.icon(
                    onPressed: () => _downloadPdf(paid),
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Ekspor'))),
              const SizedBox(height: 10),
              _periodFilter(),
              const SizedBox(height: 12),
              Text(_reportPeriodLabel,
                  style: const TextStyle(
                      color: mutedInk, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              _revenueCard('Total pendapatan', sum(paid)),
              const SizedBox(height: 12),
              Wrap(spacing: 12, runSpacing: 12, children: [
                metric('Jumlah pesanan', '${docs.length}', Icons.receipt_long),
                metric('Total berat', weightText(totalWeight),
                    Icons.local_laundry_service_outlined)
              ]),
              const SizedBox(height: 14),
              _reportRevenueChart(paid),
              const SizedBox(height: 12),
              Wrap(spacing: 10, runSpacing: 8, children: [
                OutlinedButton.icon(
                    onPressed: () => _downloadPdf(paid),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Unduh PDF')),
                OutlinedButton.icon(
                    onPressed: () => _downloadExcel(paid),
                    icon: const Icon(Icons.table_view_outlined),
                    label: const Text('Unduh Excel'))
              ]),
              const SizedBox(height: 16),
              const Text('Transaksi terbaru',
                  style: TextStyle(
                      fontSize: 21, fontWeight: FontWeight.w800, color: ink)),
              if (paid.isEmpty)
                const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('Belum ada transaksi lunas pada periode ini.',
                        style: TextStyle(color: mutedInk))),
              ...paid.take(8).map(_transactionTile)
            ]);
      });

  Widget _reportRevenueChart(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> paid) {
    final today = DateTime.now();
    final firstDay = DateTime(today.year, today.month, today.day)
        .subtract(const Duration(days: 6));
    final totals = List<num>.generate(7, (index) {
      final day = firstDay.add(Duration(days: index));
      return paid.where((doc) {
        final date =
            orderDate(doc.data(), payment: true) ?? orderDate(doc.data());
        return date != null &&
            date.year == day.year &&
            date.month == day.month &&
            date.day == day.day;
      }).fold<num>(
          0,
          (subtotal, doc) =>
              subtotal +
              ((doc.data()['amountPaid'] ?? doc.data()['total'] ?? 0) as num));
    });
    final maxTotal = totals.fold<num>(1, (a, b) => a > b ? a : b);
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(18),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Pendapatan harian',
                  style: TextStyle(
                      fontSize: 19, fontWeight: FontWeight.w800, color: ink)),
              const SizedBox(height: 14),
              SizedBox(
                  height: 128,
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(7, (index) {
                        final day = firstDay.add(Duration(days: index));
                        final selected = index == 6;
                        return Expanded(
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                              Container(
                                  height: 12 +
                                      (totals[index] / maxTotal * 82)
                                          .toDouble(),
                                  width: 27,
                                  decoration: BoxDecoration(
                                      color: selected
                                          ? blue
                                          : const Color(0xFF8FA9EC),
                                      borderRadius: BorderRadius.circular(7))),
                              const SizedBox(height: 6),
                              Text(days[day.weekday - 1],
                                  style: TextStyle(
                                      color: selected ? blue : mutedInk,
                                      fontSize: 11,
                                      fontWeight: selected
                                          ? FontWeight.w700
                                          : FontWeight.w500))
                            ]));
                      })))
            ])));
  }

  Future<void> _shareReport(List<int> bytes, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles([XFile(file.path)],
        subject: 'Laporan Keuangan HDP LAUNDRY');
  }

  Future<void> _downloadPdf(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> paid) async {
    try {
      final cash = paid.where((doc) => doc.data()['paymentMethod'] == 'Cash');
      final qris = paid.where((doc) => doc.data()['paymentMethod'] == 'QRIS');
      num sum(Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> rows) =>
          rows.fold<num>(
              0,
              (total, doc) =>
                  total +
                  ((doc.data()['amountPaid'] ?? doc.data()['total'] ?? 0)
                      as num));
      final report = pw.Document();
      final rows = paid.map((doc) {
        final data = doc.data();
        return [
          doc.id,
          '${data['customerName'] ?? '-'}',
          reportDate(orderDate(data, payment: true)),
          '${data['paymentMethod'] ?? '-'}',
          money((data['amountPaid'] ?? data['total'] ?? 0) as num),
          '${data['paymentStatus'] ?? '-'}',
          '${data['approvedByName'] ?? '-'}'
        ];
      }).toList();
      report.addPage(pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(28),
          build: (context) => [
                pw.Text('HDP LAUNDRY',
                    style: pw.TextStyle(
                        fontSize: 19, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text('LAPORAN KEUANGAN',
                    style: pw.TextStyle(
                        fontSize: 15, fontWeight: pw.FontWeight.bold)),
                pw.Text(
                    'Periode: $_reportPeriodLabel    •    Dibuat: ${reportDate(DateTime.now())}'),
                pw.SizedBox(height: 14),
                pw.Text('Ringkasan',
                    style: pw.TextStyle(
                        fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.Text(
                    'Cash: ${money(sum(cash))}    QRIS: ${money(sum(qris))}    Total: ${money(sum(paid))}    Transaksi lunas: ${paid.length}'),
                pw.SizedBox(height: 14),
                pw.TableHelper.fromTextArray(
                    headers: const [
                      'Nomor pesanan',
                      'Pelanggan',
                      'Tanggal bayar',
                      'Metode',
                      'Total',
                      'Status',
                      'Petugas'
                    ],
                    data: rows,
                    headerStyle: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                    headerDecoration:
                        const pw.BoxDecoration(color: PdfColors.blueGrey800),
                    cellStyle: const pw.TextStyle(fontSize: 8),
                    cellAlignment: pw.Alignment.centerLeft,
                    cellPadding: const pw.EdgeInsets.all(5)),
                pw.SizedBox(height: 8),
                pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text('TOTAL PEMASUKAN: ${money(sum(paid))}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)))
              ]));
      final bytes = await report.save();
      await _shareReport(
          bytes, 'Laporan_Keuangan_HDP_LAUNDRY_$_reportFilePeriod.pdf');
    } catch (e) {
      if (mounted) notice('Gagal membuat PDF: $e');
    }
  }

  Future<void> _downloadExcel(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> paid) async {
    try {
      final cash = paid.where((doc) => doc.data()['paymentMethod'] == 'Cash');
      final qris = paid.where((doc) => doc.data()['paymentMethod'] == 'QRIS');
      num sum(Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> rows) =>
          rows.fold<num>(
              0,
              (total, doc) =>
                  total +
                  ((doc.data()['amountPaid'] ?? doc.data()['total'] ?? 0)
                      as num));
      final workbook = xlsx.Excel.createExcel();
      workbook.rename('Sheet1', 'RINGKASAN');
      final summary = workbook['RINGKASAN'];
      summary.appendRow([
        xlsx.TextCellValue('HDP LAUNDRY'),
      ]);
      summary.appendRow([xlsx.TextCellValue('LAPORAN KEUANGAN')]);
      summary.appendRow([
        xlsx.TextCellValue('Periode'),
        xlsx.TextCellValue(_reportPeriodLabel)
      ]);
      summary.appendRow([
        xlsx.TextCellValue('Total pemasukan Cash'),
        xlsx.TextCellValue(money(sum(cash)))
      ]);
      summary.appendRow([
        xlsx.TextCellValue('Total pemasukan QRIS'),
        xlsx.TextCellValue(money(sum(qris)))
      ]);
      summary.appendRow([
        xlsx.TextCellValue('Total pemasukan keseluruhan'),
        xlsx.TextCellValue(money(sum(paid)))
      ]);
      summary.appendRow([
        xlsx.TextCellValue('Jumlah transaksi lunas'),
        xlsx.IntCellValue(paid.length)
      ]);
      summary.setColumnWidth(0, 34);
      summary.setColumnWidth(1, 36);

      final detail = workbook['DETAIL TRANSAKSI'];
      detail.appendRow([
        xlsx.TextCellValue('Nomor pesanan'),
        xlsx.TextCellValue('Nama pelanggan'),
        xlsx.TextCellValue('Tanggal pembayaran'),
        xlsx.TextCellValue('Metode pembayaran'),
        xlsx.TextCellValue('Total pembayaran'),
        xlsx.TextCellValue('Status pembayaran'),
        xlsx.TextCellValue('Petugas yang mengonfirmasi')
      ]);
      for (final doc in paid) {
        final data = doc.data();
        detail.appendRow([
          xlsx.TextCellValue(doc.id),
          xlsx.TextCellValue('${data['customerName'] ?? '-'}'),
          xlsx.TextCellValue(reportDate(orderDate(data, payment: true))),
          xlsx.TextCellValue('${data['paymentMethod'] ?? '-'}'),
          xlsx.TextCellValue(
              money((data['amountPaid'] ?? data['total'] ?? 0) as num)),
          xlsx.TextCellValue('${data['paymentStatus'] ?? '-'}'),
          xlsx.TextCellValue('${data['approvedByName'] ?? '-'}')
        ]);
      }
      for (final entry in const <int, double>{
        0: 18,
        1: 28,
        2: 20,
        3: 20,
        4: 23,
        5: 20,
        6: 32
      }.entries) {
        detail.setColumnWidth(entry.key, entry.value);
      }
      final bytes = workbook.encode();
      if (bytes == null) throw StateError('File Excel gagal dibuat.');
      await _shareReport(
          bytes, 'Laporan_Keuangan_HDP_LAUNDRY_$_reportFilePeriod.xlsx');
    } catch (e) {
      if (mounted) notice('Gagal membuat Excel: $e');
    }
  }
}
