part of '../../main.dart';

extension _HomeReceiptsFeature on _HomePageState {
  Widget receiptsPage() => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: ordersStream,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('Gagal memuat nota: ${snap.error}'));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data!.docs;
        return ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            children: [
          if (docs.isEmpty)
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('Belum ada pesanan untuk dibuatkan nota.',
                    style: TextStyle(color: mutedInk))),
          ...docs.map((doc) {
            final order = doc.data();
            return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                            color: paleBlue,
                            borderRadius: BorderRadius.circular(16)),
                        child: const Icon(Icons.receipt_long_outlined,
                            color: blue)),
                    title: Text('${order['orderNumber'] ?? doc.id}',
                        style: const TextStyle(
                            color: ink, fontWeight: FontWeight.w800)),
                    subtitle: Text(
                        '${order['customerName'] ?? '-'} · ${money((order['total'] ?? 0) as num)}',
                        style: const TextStyle(color: mutedInk)),
                    trailing: const Icon(Icons.chevron_right, color: mutedInk),
                    onTap: () => receiptPreview(doc.id, order)));
          })
        ]);
      });

  Future<void> receiptPreview(String id, Map<String, dynamic> order) async {
    final createdDate = orderDate(order);
    final fields = <String, String>{
      'Nomor pesanan': '${order['orderNumber'] ?? id}',
      'Nama pelanggan': '${order['customerName'] ?? '-'}',
      'Jenis layanan': '${order['serviceName'] ?? '-'}',
      'Berat cucian': weightText((order['kg'] ?? 0) as num),
      'Harga': '${money((order['price'] ?? 0) as num)}/kg',
      'Tanggal pesanan': createdDate == null
          ? '${order['created'] ?? '-'}'
          : reportDate(createdDate),
      'Nama petugas': '${order['createdByName'] ?? '-'}',
    };
    final total = money((order['total'] ?? 0) as num);
    await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text('Pratinjau nota'),
                content: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: SingleChildScrollView(
                        child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                border:
                                    Border.all(color: const Color(0xFFDCE3EC)),
                                borderRadius: BorderRadius.circular(16)),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Image.asset('assets/logo_laundry.png',
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.contain),
                                        const SizedBox(width: 10),
                                        const Text('HDP LAUNDRY',
                                            style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF172B4D)))
                                      ]),
                                  const SizedBox(height: 16),
                                  const Divider(height: 1),
                                  const SizedBox(height: 12),
                                  ...fields.entries.map((entry) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 7),
                                      child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                                flex: 4,
                                                child: Text(entry.key,
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Color(
                                                            0xFF64748B)))),
                                            const SizedBox(width: 12),
                                            Expanded(
                                                flex: 6,
                                                child: Text(entry.value,
                                                    textAlign: TextAlign.right,
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600)))
                                          ]))),
                                  const SizedBox(height: 8),
                                  const Divider(height: 1),
                                  const SizedBox(height: 12),
                                  Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Expanded(
                                            child: Text('Total pembayaran',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.w700))),
                                        const SizedBox(width: 12),
                                        Flexible(
                                            child: Text(total,
                                                textAlign: TextAlign.right,
                                                style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w800,
                                                    color: blue)))
                                      ]),
                                  const SizedBox(height: 16),
                                  const Text(
                                      'Terima kasih atas kepercayaan Anda.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF64748B),
                                          fontStyle: FontStyle.italic))
                                ])))),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Tutup')),
                  FilledButton.icon(
                      onPressed: () => _shareReceipt(fields, total),
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('PDF / Bagikan'))
                ]));
  }

  Future<void> _shareReceipt(Map<String, String> fields, String total) async {
    try {
      final logoData = await rootBundle.load('assets/logo_laundry.png');
      final logo = pw.MemoryImage(logoData.buffer.asUint8List());
      final document = pw.Document();
      document.addPage(pw.MultiPage(
          pageFormat: PdfPageFormat.a5,
          margin: const pw.EdgeInsets.all(28),
          build: (context) => [
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Image(logo, width: 42, height: 42),
                      pw.SizedBox(width: 10),
                      pw.Text('HDP LAUNDRY',
                          style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blueGrey900))
                    ]),
                pw.SizedBox(height: 6),
                pw.Center(
                    child: pw.Text('NOTA PESANAN',
                        style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blueGrey600))),
                pw.SizedBox(height: 16),
                pw.Divider(color: PdfColors.blueGrey200),
                pw.SizedBox(height: 8),
                ...fields.entries.map((entry) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 7),
                    child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                              flex: 4,
                              child: pw.Text(entry.key,
                                  style: const pw.TextStyle(
                                      fontSize: 10,
                                      color: PdfColors.blueGrey600))),
                          pw.SizedBox(width: 12),
                          pw.Expanded(
                              flex: 6,
                              child: pw.Text(entry.value,
                                  textAlign: pw.TextAlign.right,
                                  style: pw.TextStyle(
                                      fontSize: 10,
                                      fontWeight: pw.FontWeight.bold)))
                        ]))),
                pw.SizedBox(height: 8),
                pw.Divider(color: PdfColors.blueGrey200),
                pw.SizedBox(height: 8),
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('TOTAL PEMBAYARAN',
                          style: pw.TextStyle(
                              fontSize: 11, fontWeight: pw.FontWeight.bold)),
                      pw.Text(total,
                          style: pw.TextStyle(
                              fontSize: 15,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue800))
                    ]),
                pw.SizedBox(height: 20),
                pw.Center(
                    child: pw.Text('Terima kasih atas kepercayaan Anda.',
                        style: const pw.TextStyle(
                            fontSize: 9, color: PdfColors.blueGrey600)))
              ]));
      final directory = await getApplicationDocumentsDirectory();
      final number = (fields['Nomor pesanan'] ?? 'pesanan')
          .replaceAll(RegExp(r'[/\\]'), '-');
      final file =
          File('${directory.path}${Platform.pathSeparator}Nota_$number.pdf');
      await file.writeAsBytes(await document.save(), flush: true);
      await Share.shareXFiles([XFile(file.path)], subject: 'Nota HDP Laundry');
    } catch (e) {
      if (mounted) notice('Gagal membuat nota PDF: $e');
    }
  }
}
