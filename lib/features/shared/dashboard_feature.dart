part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

extension _SharedDashboardFeature on _HomePageState {
  Widget title(String s) => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(s,
          style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w800,
              color: ink)));
  Widget metric(String label, String value, IconData ico, {int columns = 2}) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final iconColor = switch (label) {
      'Antrean' => const Color(0xFF965200),
      'Di Cuci' => const Color(0xFF1947AF),
      'Siap Ambil' => teal,
      'Selesai hari ini' => const Color(0xFF394A66),
      _ => blue
    };
    final iconBackground = switch (label) {
      'Antrean' => paleAmber,
      'Di Cuci' => paleBlue,
      'Siap Ambil' => paleTeal,
      'Selesai hari ini' => const Color(0xFFE6EAF2),
      _ => paleBlue
    };
    final width = screenWidth < 600
        ? (screenWidth - (columns + 1) * 12 - 20) / columns
        : screenWidth < 1100
            ? 250.0
            : 270.0;
    return SizedBox(
        width: width,
        child: Card(
            margin: EdgeInsets.zero,
            child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DecoratedBox(
                          decoration: BoxDecoration(
                              color: iconBackground,
                              borderRadius: BorderRadius.circular(15)),
                          child: SizedBox(
                              width: 44,
                              height: 44,
                              child: Icon(ico, color: iconColor, size: 23))),
                      const SizedBox(height: 10),
                      Text(value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.w800,
                              color: ink)),
                      Text(label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: mutedInk, fontSize: 13))
                    ]))));
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    return hour < 11
        ? 'Selamat pagi'
        : hour < 15
            ? 'Selamat siang'
            : hour < 18
                ? 'Selamat sore'
                : 'Selamat malam';
  }

  String _todayLabel() {
    const days = [
      'Sen',
      'Sel',
      'Rab',
      'Kam',
      'Jum',
      'Sab',
      'Min'
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    final now = DateTime.now();
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  Widget _dashboardGreeting() => Padding(
      padding: const EdgeInsets.fromLTRB(2, 16, 2, 20),
      child: Row(children: [
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text('${_greeting()} · ${_todayLabel()}',
                  style: const TextStyle(fontSize: 15, color: mutedInk)),
              const SizedBox(height: 5),
              Row(children: [
                Flexible(
                    child: Text(widget.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                            color: ink))),
                const SizedBox(width: 10),
                DecoratedBox(
                    decoration: BoxDecoration(
                        color: isOwner ? blue : paleTeal,
                        borderRadius: BorderRadius.circular(999)),
                    child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: Text(widget.role,
                            style: TextStyle(
                                color: isOwner ? Colors.white : teal,
                                fontWeight: FontWeight.w700))))
              ])
            ])),
        const SizedBox(width: 10),
        CircleAvatar(
            radius: 27,
            backgroundColor: paleBlue,
            child: Text(
                widget.name.trim().isEmpty
                    ? '?'
                    : widget.name
                        .trim()
                        .split(RegExp(r'\s+'))
                        .take(2)
                        .map((part) => part[0])
                        .join()
                        .toUpperCase(),
                style: const TextStyle(
                    color: blue, fontWeight: FontWeight.w800, fontSize: 18)))
      ]));

  Widget _revenueCard(String label, num value) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
          color: const Color(0xFF173F9D),
          borderRadius: BorderRadius.circular(26)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                color: Color(0xFFD8E3FF),
                fontSize: 15,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(money(value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w800))
      ]));

  Widget _weeklyRevenueChart(List<Map<String, dynamic>> orders) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));
    final amounts = List<num>.generate(7, (index) {
      final day = start.add(Duration(days: index));
      return orders
          .where((order) {
            final date = orderDate(order, payment: true) ?? orderDate(order);
            return order['paymentStatus'] == 'Lunas' &&
                date != null &&
                date.year == day.year &&
                date.month == day.month &&
                date.day == day.day;
          })
          .fold<num>(
              0,
              (subtotal, order) =>
                  subtotal + ((order['amountPaid'] ?? order['total'] ?? 0) as num));
    });
    final maxAmount = amounts.fold<num>(1, (a, b) => a > b ? a : b);
    const weekdays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              const Text('Pendapatan 7 hari',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800, color: ink)),
              const SizedBox(height: 18),
              SizedBox(
                  height: 132,
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(7, (index) {
                        final date = start.add(Duration(days: index));
                        final selected = index == 6;
                        final height =
                            12 + (amounts[index] / maxAmount * 88).toDouble();
                        return Expanded(
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                              Container(
                                  height: height,
                                  width: 27,
                                  decoration: BoxDecoration(
                                      color: selected
                                          ? blue
                                          : const Color(0xFF8FA9EC),
                                      borderRadius: BorderRadius.circular(7))),
                              const SizedBox(height: 7),
                              Text(weekdays[date.weekday - 1],
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: selected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: selected ? blue : mutedInk))
                            ]));
                      })))
            ])));
  }

  String laundryStatus(Map<String, dynamic> order) {
    final value = '${order['laundryStatus'] ?? order['status'] ?? 'Antrean'}';
    return switch (value) {
      'Antrian' => 'Antrean',
      'Dicuci' || 'Dikeringkan' || 'Disetrika' || 'Dikemas' => 'Di Cuci',
      'Siap Diambil' => 'Siap Ambil',
      _ => value
    };
  }

  Widget dashboard() => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: ordersStream,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('Gagal memuat pesanan: ${snap.error}'));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data!.docs;
        final data = docs.map((d) => d.data()).toList();
        if (isOwner) {
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: usersStream,
              builder: (context, usersSnap) {
                if (usersSnap.hasError) {
                  return Center(
                      child:
                          Text('Gagal memuat pelanggan: ${usersSnap.error}'));
                }
                if (!usersSnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final paid = data
                    .where((order) => order['paymentStatus'] == 'Lunas')
                    .toList();
                num amount(Iterable<Map<String, dynamic>> rows) =>
                    rows.fold<num>(
                        0,
                        (runningTotal, order) =>
                            runningTotal +
                            ((order['amountPaid'] ?? order['total'] ?? 0)
                                as num));
                final now = DateTime.now();
                final todayPaid = paid.where((order) {
                  final date = orderDate(order, payment: true) ?? orderDate(order);
                  return date != null &&
                      date.year == now.year &&
                      date.month == now.month &&
                      date.day == now.day;
                });
                final revenue = amount(todayPaid);
                int countFor(String status) =>
                    data.where((o) => laundryStatus(o) == status).length;
                final completedToday = data.where((order) {
                  final date = orderDate(order);
                  return laundryStatus(order) == 'Selesai' &&
                      date != null &&
                      date.year == now.year &&
                      date.month == now.month &&
                      date.day == now.day;
                }).length;
                return ListView(padding: const EdgeInsets.fromLTRB(18, 0, 18, 20), children: [
                  _dashboardGreeting(),
                  _revenueCard('Pendapatan hari ini', revenue),
                  const SizedBox(height: 16),
                  Wrap(spacing: 12, runSpacing: 12, children: [
                    metric('Antrean', '${countFor('Antrean')}',
                        Icons.schedule_outlined),
                    metric('Di Cuci', '${countFor('Di Cuci')}',
                        Icons.water_drop_outlined),
                    metric('Siap Ambil', '${countFor('Siap Ambil')}',
                        Icons.inventory_2_outlined),
                    metric('Selesai hari ini', '$completedToday',
                        Icons.task_alt_outlined)
                  ]),
                  const SizedBox(height: 16),
                  _weeklyRevenueChart(data),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Pesanan terbaru',
                          style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              color: ink)),
                      TextButton(
                        onPressed: () => setState(() => tab = 1),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Lihat semua',
                          style: TextStyle(
                            color: blue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (docs.isEmpty)
                    const Text('Belum ada pesanan')
                  else
                    ...docs.reversed
                        .take(5)
                        .map((d) => orderTile(d.id, d.data()))
                ]);
              });
        }
        final metricContent = statuses.take(3).map((status) => metric(
            status,
            '${data.where((o) => laundryStatus(o) == status).length}',
            switch (status) {
              'Antrean' => Icons.schedule_outlined,
              'Di Cuci' => Icons.water_drop_outlined,
              _ => Icons.inventory_2_outlined
            },
            columns: 3)).toList();
        final activeOrders = docs
            .where((doc) => laundryStatus(doc.data()) != 'Selesai')
            .toList()
          ..sort((a, b) =>
              (orderDate(b.data()) ?? DateTime(0))
                  .compareTo(orderDate(a.data()) ?? DateTime(0)));
        return ListView(padding: const EdgeInsets.fromLTRB(18, 0, 18, 20), children: [
          _dashboardGreeting(),
          InkWell(
              onTap: orderDialog,
              borderRadius: BorderRadius.circular(26),
              child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: blue, borderRadius: BorderRadius.circular(26)),
                  child: const Row(children: [
                    CircleAvatar(
                        radius: 28,
                        backgroundColor: Color(0xFF4C75DE),
                        child: Icon(Icons.add, color: Colors.white, size: 34)),
                    SizedBox(width: 16),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text('Buat Pesanan',
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white)),
                          SizedBox(height: 3),
                          Text('Pilih pelanggan, layanan, dan berat',
                              style: TextStyle(color: Color(0xFFDCE6FF)))
                        ]))
                  ]))),
          const SizedBox(height: 20),
          const Text('Ringkasan hari ini',
              style: TextStyle(
                  fontSize: 21, fontWeight: FontWeight.w800, color: ink)),
          const SizedBox(height: 12),
          Wrap(spacing: 12, runSpacing: 12, children: metricContent),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Pesanan terbaru',
                  style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: ink)),
              TextButton(
                onPressed: () => setState(() => tab = 1),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Lihat semua',
                  style: TextStyle(
                    color: blue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (activeOrders.isEmpty)
            const Text('Belum ada pesanan')
          else
            ...activeOrders.take(5).map((d) => orderTile(d.id, d.data()))
        ]);
      });
  // ignore: unused_element
}
