part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

extension _StaffPaymentsFeature on _HomePageState {
  Future<void> approvePayment(
      String orderId, Map<String, dynamic> order) async {
    var selectedMethod = paymentMethods.contains(order['paymentMethod'])
        ? order['paymentMethod'] as String
        : 'Cash';
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, setDialog) => AlertDialog(
                    title: const Text('Konfirmasi pembayaran'),
                    content: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(
                          'Pastikan pembayaran sebesar ${money((order['total'] ?? 0) as num)} sudah diterima dan diverifikasi.'),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                          initialValue: selectedMethod,
                          decoration: const InputDecoration(
                              labelText: 'Metode Pembayaran'),
                          items: paymentMethods
                              .map((method) => DropdownMenuItem(
                                  value: method, child: Text(method)))
                              .toList(),
                          onChanged: (method) => setDialog(() {
                                if (method != null) selectedMethod = method;
                              }))
                    ]),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Batal')),
                      FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Konfirmasi Pembayaran'))
                    ])));
    if (confirmed != true) return;
    try {
      final ref = db.collection('orders').doc(orderId);
      await db.runTransaction((transaction) async {
        final snapshot = await transaction.get(ref);
        if (!snapshot.exists) throw StateError('Pesanan tidak ditemukan.');
        final current = snapshot.data()!;
        if (current['paymentStatus'] == 'Lunas') {
          throw StateError(
              'Pembayaran sudah lunas dan tidak dapat disetujui ulang.');
        }
        final method = selectedMethod;
        final amount = current['total'];
        if (!paymentMethods.contains(method) || amount is! num || amount <= 0) {
          throw StateError('Data metode atau total pembayaran tidak valid.');
        }
        transaction.update(ref, {
          'paymentStatus': 'Lunas',
          'amountPaid': amount,
          'paidAt': FieldValue.serverTimestamp(),
          'approvedBy': widget.uid,
          'approvedByName': widget.name,
          'paymentMethod': method
        });
      });
      if (mounted) notice('Pembayaran berhasil disetujui.');
    } catch (e) {
      if (mounted) notice('Pembayaran tidak disetujui: $e');
    }
  }

  Widget paymentsPage() => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: ordersStream,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('Gagal memuat pembayaran: ${snap.error}'));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final pending = snap.data!.docs
            .where((doc) => doc.data()['paymentStatus'] != 'Lunas')
            .toList();
        return ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            children: [
              Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                      color: const Color(0xFF173F9D),
                      borderRadius: BorderRadius.circular(24)),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Menunggu pembayaran',
                            style: TextStyle(
                                color: Color(0xFFD8E3FF),
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 5),
                        Text('${pending.length} pesanan',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w800))
                      ])),
              const SizedBox(height: 18),
              if (pending.isEmpty)
                const Padding(
                    padding: EdgeInsets.symmetric(vertical: 22),
                    child: Center(
                        child: Text('Tidak ada pembayaran yang menunggu.',
                            style: TextStyle(color: mutedInk)))),
              ...pending.map((doc) {
                final data = doc.data();
                return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Expanded(
                                    child: Text(
                                        '${data['customerName'] ?? '-'}',
                                        style: const TextStyle(
                                            color: ink,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 17))),
                                DecoratedBox(
                                    decoration: BoxDecoration(
                                        color: paleAmber,
                                        borderRadius:
                                            BorderRadius.circular(999)),
                                    child: const Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 11, vertical: 7),
                                        child: Text('Belum dibayar',
                                            style: TextStyle(
                                                color: Color(0xFF965200),
                                                fontWeight: FontWeight.w700))))
                              ]),
                              const SizedBox(height: 5),
                              Text(
                                  '${data['orderNumber'] ?? doc.id} · ${data['serviceName'] ?? '-'}',
                                  style: const TextStyle(color: mutedInk)),
                              const SizedBox(height: 8),
                              Text(money((data['total'] ?? 0) as num),
                                  style: const TextStyle(
                                      color: ink,
                                      fontSize: 21,
                                      fontWeight: FontWeight.w800)),
                              const SizedBox(height: 13),
                              SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                      onPressed: () =>
                                          approvePayment(doc.id, data),
                                      icon: const Icon(Icons.check),
                                      label: const Text('Konfirmasi Tunai')))
                            ])));
              })
            ]);
      });

  // ignore: unused_element
  Widget staffReportsPage() => StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
      stream: ordersStream,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('Gagal memuat laporan: ${snap.error}'));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final transactions = _inReportPeriod(snap.data!.docs
            .where((doc) =>
                doc.data()['paymentStatus'] == 'Lunas' &&
                doc.data()['approvedBy'] == widget.uid)
            .toList());
        final cash =
            transactions.where((d) => d.data()['paymentMethod'] == 'Cash');
        final qris =
            transactions.where((d) => d.data()['paymentMethod'] == 'QRIS');
        num sum(Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> rows) =>
            rows.fold<num>(
                0,
                (total, doc) =>
                    total +
                    ((doc.data()['amountPaid'] ?? doc.data()['total'] ?? 0)
                        as num));
        return ListView(padding: const EdgeInsets.all(18), children: [
          title('Laporan Keuangan'),
          _periodFilter(),
          const SizedBox(height: 12),
          Wrap(spacing: 10, runSpacing: 10, children: [
            metric('Cash dikonfirmasi', money(sum(cash)), Icons.money),
            metric('QRIS dikonfirmasi', money(sum(qris)), Icons.qr_code),
            metric(
                'Total dikonfirmasi', money(sum(transactions)), Icons.payments)
          ]),
          const SizedBox(height: 16),
          if (transactions.isEmpty)
            const Text(
                'Belum ada pembayaran yang dikonfirmasi pada periode ini.'),
          ...transactions.map((doc) => _transactionTile(doc))
        ]);
      });

  Widget _transactionTile(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return Card(
        margin: const EdgeInsets.only(bottom: 1),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
            side: const BorderSide(color: outline)),
        child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('${data['customerName'] ?? '-'}',
                        style: const TextStyle(
                            color: ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(
                        '${data['orderNumber'] ?? doc.id} · ${reportDate(orderDate(data, payment: true))}',
                        style: const TextStyle(color: mutedInk, fontSize: 13))
                  ])),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(money((data['amountPaid'] ?? data['total'] ?? 0) as num),
                    style: const TextStyle(
                        color: ink, fontSize: 16, fontWeight: FontWeight.w800)),
                Text('${data['paymentMethod'] ?? '-'}',
                    style: const TextStyle(color: mutedInk, fontSize: 13))
              ])
            ])));
  }
}
