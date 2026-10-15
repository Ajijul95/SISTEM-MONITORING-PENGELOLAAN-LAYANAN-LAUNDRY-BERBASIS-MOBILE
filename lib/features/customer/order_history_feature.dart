part of '../../main.dart';

extension _CustomerOrderHistoryFeature on _HomePageState {
  Widget historyPage() => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: ordersStream,
      builder: (context, snap) {
        if (snap.hasError) return Text('Gagal memuat riwayat: ${snap.error}');
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final completed = snap.data!.docs
            .where((doc) => laundryStatus(doc.data()) == 'Selesai')
            .toList();
        return ListView(padding: const EdgeInsets.all(18), children: [
          title('Riwayat Pesanan'),
          if (completed.isEmpty)
            const Text('Belum ada pesanan yang selesai.')
          else
            ...completed.map((doc) => orderTile(doc.id, doc.data()))
        ]);
      });
}
