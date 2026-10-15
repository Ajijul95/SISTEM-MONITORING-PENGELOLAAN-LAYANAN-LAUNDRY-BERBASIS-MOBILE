part of '../../main.dart';

extension _CustomerHomeFeature on _HomePageState {
  Widget customerHome() => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: ordersStream,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('Gagal memuat pesanan: ${snap.error}'));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data!.docs;
        final active = docs
            .where((doc) => laundryStatus(doc.data()) != 'Selesai')
            .toList()
          ..sort((a, b) =>
              (orderDate(b.data()) ?? DateTime(0))
                  .compareTo(orderDate(a.data()) ?? DateTime(0)));
        final completed = docs
            .where((doc) => laundryStatus(doc.data()) == 'Selesai')
            .toList()
          ..sort((a, b) =>
              (orderDate(b.data()) ?? DateTime(0))
                  .compareTo(orderDate(a.data()) ?? DateTime(0)));
        final current = active.firstOrNull?.data();
        final totalDue = active.fold<num>(
            0,
            (runningTotal, doc) => doc.data()['paymentStatus'] == 'Lunas'
                ? runningTotal
                : runningTotal + ((doc.data()['total'] ?? 0) as num));
        return ListView(padding: const EdgeInsets.fromLTRB(18, 0, 18, 20), children: [
          _dashboardGreeting(),
          if (current != null) ...[
            Card(
                child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  const Text('Pesanan aktif',
                                      style: TextStyle(
                                          color: mutedInk, fontSize: 14)),
                                  const SizedBox(height: 5),
                                  Text(
                                      '${current['orderNumber'] ?? '-'}',
                                      style: const TextStyle(
                                          fontSize: 25,
                                          fontWeight: FontWeight.w800,
                                          color: ink)),
                                  const SizedBox(height: 4),
                                  Text(
                                      '${current['serviceName'] ?? '-'} · ${weightText((current['kg'] ?? 0) as num)}',
                                      style: const TextStyle(color: mutedInk))
                                ])),
                            statusBadge(laundryStatus(current), compact: true)
                          ]),
                      const SizedBox(height: 22),
                      _customerProgress(laundryStatus(current)),
                      const SizedBox(height: 18),
                      if (laundryStatus(current) == 'Siap Ambil')
                        Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                                color: paleTeal,
                                borderRadius: BorderRadius.circular(18)),
                            child: const Row(children: [
                              Icon(Icons.check_circle_outline, color: teal),
                              SizedBox(width: 10),
                              Expanded(
                                  child: Text(
                                      'Cucian Anda sudah selesai dan siap diambil.',
                                      style: TextStyle(
                                          color: teal,
                                          fontWeight: FontWeight.w600)))
                            ])),
                      if (laundryStatus(current) == 'Siap Ambil')
                        const SizedBox(height: 18),
                      const Divider(color: outline),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              const Text('Total · Tunai',
                                  style: TextStyle(color: mutedInk)),
                              const SizedBox(height: 3),
                              Text(
                                  money((current['total'] ?? 0) as num),
                                  style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      color: ink))
                            ])),
                        OutlinedButton.icon(
                            onPressed: () =>
                                orderDetail(active.first.id, current),
                            icon: const Icon(Icons.receipt_long_outlined),
                            label: const Text('Lihat Nota'))
                      ])
                    ]))),
          ] else
            Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: outline),
                    borderRadius: BorderRadius.circular(24)),
                child: const Text('Belum ada pesanan aktif.',
                    style: TextStyle(color: mutedInk))),
          const SizedBox(height: 22),
          Row(children: [
            const Expanded(
                child: Text('Riwayat pesanan',
                    style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: ink))),
            TextButton(
                onPressed: () => changeTab(2),
                child: const Text('Lihat semua'))
          ]),
          if (completed.isEmpty)
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Text('Belum ada pesanan yang selesai.',
                    style: TextStyle(color: mutedInk)))
          else
            ...completed.take(4).map((doc) => orderTile(doc.id, doc.data())),
          if (totalDue > 0)
            Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Tagihan belum lunas: ${money(totalDue)}',
                    style: const TextStyle(
                        color: mutedInk, fontWeight: FontWeight.w600)))
        ]);
      });

  Widget _customerProgress(String status) {
    const steps = ['Antrean', 'Di Cuci', 'Siap Ambil', 'Selesai'];
    final current = steps.indexOf(status).clamp(0, steps.length - 1);
    return Row(
        children: List.generate(steps.length * 2 - 1, (index) {
      if (index.isOdd) {
        final passed = index ~/ 2 < current;
        return Expanded(
            child: Container(
                height: 3, color: passed ? blue : const Color(0xFFE1E6EF)));
      }
      final step = index ~/ 2;
      final passed = step < current;
      final selected = step == current;
      return Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: passed || selected ? blue : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                    color: passed || selected ? blue : outline, width: 2)),
            child: Icon(
                passed
                    ? Icons.check
                    : switch (steps[step]) {
                        'Antrean' => Icons.schedule,
                        'Di Cuci' => Icons.water_drop_outlined,
                        'Siap Ambil' => Icons.inventory_2_outlined,
                        _ => Icons.check_circle_outline
                      },
                size: 20,
                color: passed || selected ? Colors.white : mutedInk)),
        const SizedBox(height: 6),
        Text(steps[step],
            style: TextStyle(
                fontSize: 11,
                fontWeight:
                    passed || selected ? FontWeight.w700 : FontWeight.w500,
                color: passed || selected ? ink : mutedInk))
      ]);
    }));
  }
}
