part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member, unused_element

extension _OwnerFinanceFeature on _HomePageState {
  Widget financePage() => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: ordersStream,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('Gagal memuat keuangan: ${snap.error}'));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data!.docs;
        final paid = docs
            .where((doc) => doc.data()['paymentStatus'] == 'Lunas')
            .toList();
        final unpaid = docs
            .where((doc) => doc.data()['paymentStatus'] != 'Lunas')
            .toList();
        num amount(
                Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> rows) =>
            rows.fold<num>(
                0,
                (runningTotal, doc) =>
                    runningTotal +
                    ((doc.data()['amountPaid'] ?? doc.data()['total'] ?? 0)
                        as num));
        final cash = paid.where((doc) => doc.data()['paymentMethod'] == 'Cash');
        final qris = paid.where((doc) => doc.data()['paymentMethod'] == 'QRIS');
        return ListView(padding: const EdgeInsets.all(18), children: [
          title('Keuangan'),
          Wrap(spacing: 10, runSpacing: 10, children: [
            metric('Total omzet', money(amount(paid)), Icons.payments),
            metric('Total Cash', money(amount(cash)), Icons.money),
            metric('Total QRIS', money(amount(qris)), Icons.qr_code),
            metric('Jumlah transaksi', '${docs.length}', Icons.receipt_long),
            metric('Transaksi lunas', '${paid.length}', Icons.check_circle),
            metric('Belum lunas', '${unpaid.length}', Icons.pending_actions)
          ]),
          const SizedBox(height: 18),
          title('Pembayaran terbaru'),
          if (paid.isEmpty)
            const Text('Belum ada pembayaran lunas.')
          else
            ...paid.reversed.take(8).map(_transactionTile)
        ]);
      });
}
