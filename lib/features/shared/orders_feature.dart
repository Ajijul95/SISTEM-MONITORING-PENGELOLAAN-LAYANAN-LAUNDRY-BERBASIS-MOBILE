part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

bool customerMatchesSearch(Map<String, dynamic> data, String keyword) {
  final search = keyword.trim().toLowerCase();
  if (search.isEmpty) return false;
  return [data['name'], data['phone'], data['email']].any((value) =>
      value != null && value.toString().toLowerCase().contains(search));
}

bool isCustomerProfile(Map<String, dynamic> data) =>
    data['role'] == 'Pelanggan';

extension _SharedOrdersFeature on _HomePageState {
  String get _currentOrderFilter {
    return _savedOrderFilter ?? 'Antrean';
  }

  Widget ordersPage() => ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 96),
          children: [
            TextField(
                controller: orderSearchController,
                onChanged: (value) => setState(() => orderSearch = value),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                    hintText: 'Cari nomor pesanan atau nama',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: orderSearch.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Hapus pencarian',
                            onPressed: () {
                              orderSearchController.clear();
                              setState(() => orderSearch = '');
                            },
                            icon: const Icon(Icons.close)))),
            const SizedBox(height: 14),
            _buildOrderFilter(const {
              'Antrean': Icons.schedule_outlined,
              'Proses': Icons.water_drop_outlined,
              'Selesai': Icons.task_alt_outlined,
            }),
            const SizedBox(height: 12),
            ordersList()
          ]);

  Widget _buildOrderFilter(Map<String, IconData> categories) =>
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: ordersStream,
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];
            final counts = {
              'Antrean': docs
                  .where((doc) => laundryStatus(doc.data()) == 'Antrean')
                  .length,
              'Proses': docs
                  .where((doc) => laundryStatus(doc.data()) == 'Di Cuci')
                  .length,
              'Selesai': docs
                  .where((doc) => ['Siap Ambil', 'Selesai']
                      .contains(laundryStatus(doc.data())))
                  .length,
            };
            return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                    children: categories.entries.map((entry) {
                  final selected = _currentOrderFilter == entry.key;
                  return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                          selected: selected,
                          onSelected: (_) => changeOrderFilter(entry.key),
                          showCheckmark: false,
                          side: BorderSide(
                              color: selected ? blue : outline,
                              width: selected ? 1.5 : 1),
                          selectedColor: paleBlue,
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                              color: selected ? blue : mutedInk,
                              fontWeight: FontWeight.w600),
                          avatar: Icon(entry.value,
                              size: 18,
                              color: selected ? blue : mutedInk),
                          label: Row(mainAxisSize: MainAxisSize.min, children: [
                            Text(entry.key),
                            const SizedBox(width: 8),
                            Text('${counts[entry.key] ?? 0}',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: selected ? blue : Colors.black54))
                          ])));
                }).toList()));
          });

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterOrdersByStatus(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final filter = _currentOrderFilter;
    return docs.where((doc) {
      final status = laundryStatus(doc.data());
      return switch (filter) {
        'Antrean' => status == 'Antrean',
        'Proses' => status == 'Di Cuci',
        'Selesai' => status == 'Siap Ambil' || status == 'Selesai',
        _ => false
      };
    }).toList();
  }

  Widget ordersList() => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: ordersStream,
      builder: (context, snap) {
        if (snap.hasError) return Text('Gagal memuat: ${snap.error}');
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data!.docs;
        final keyword = orderSearch.trim().toLowerCase();
        final filteredDocs = _filterOrdersByStatus(docs).where((doc) {
          if (keyword.isEmpty) return true;
          final order = doc.data();
          return [
            order['orderNumber'],
            order['customerName'],
            order['serviceName']
          ].any((value) =>
              value != null && value.toString().toLowerCase().contains(keyword));
        }).toList()
          ..sort((a, b) =>
              (orderDate(b.data()) ?? DateTime(0))
                  .compareTo(orderDate(a.data()) ?? DateTime(0)));
        if (filteredDocs.isEmpty) {
          return Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Center(
                  child: Text(
                      'Belum ada pesanan ${_currentOrderFilter.toLowerCase()}.',
                      textAlign: TextAlign.center)));
        }
        return Column(
            children: filteredDocs
                .map((doc) => orderTile(doc.id, doc.data()))
                .toList());
      });
  Widget orderTile(String id, Map<String, dynamic> o) {
    final currentLaundryStatus = laundryStatus(o);
    final statusText = switch (currentLaundryStatus) {
      'Antrean' => 'Antrean',
      'Di Cuci' => 'Di Cuci',
      'Siap Ambil' => 'Siap Ambil',
      'Selesai' => 'Selesai',
      _ => currentLaundryStatus,
    };
    final orderCode = '${o['orderNumber'] ?? id}';
    final displayOrderCode =
        orderCode.startsWith('#') ? orderCode : '#$orderCode';

    return InkWell(
      onTap: () => orderDetail(id, o),
      borderRadius: BorderRadius.circular(22),
      child: Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(displayOrderCode,
                          style: const TextStyle(
                              color: Color(0xFF1947AF),
                              fontWeight: FontWeight.w800,
                              fontSize: 15)),
                      const SizedBox(height: 7),
                      Text('${o['customerName'] ?? '-'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: ink,
                              fontWeight: FontWeight.w700,
                              fontSize: 17)),
                      const SizedBox(height: 4),
                      Text(
                          '${o['serviceName'] ?? '-'} · ${weightText((o['kg'] ?? 0) as num)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: mutedInk))
                    ])),
                const SizedBox(width: 10),
                Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      statusBadge(statusText, compact: true),
                      const SizedBox(height: 7),
                      Text(money((o['total'] ?? 0) as num),
                          style: const TextStyle(
                              color: ink,
                              fontSize: 16,
                              fontWeight: FontWeight.w800))
                    ])
              ]))));
  }

  void orderDetail(String id, Map<String, dynamic> o) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
          builder: (ctx, setModal) => Padding(
              padding: const EdgeInsets.all(20),
              child: Wrap(children: [
                Text('${o['orderNumber'] ?? id}',
                    style: const TextStyle(
                        fontSize: 23, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                ...<String, String>{
                  'Pelanggan': '${o['customerName'] ?? '-'}',
                  'Layanan': '${o['serviceName'] ?? '-'}',
                  'Berat': weightText((o['kg'] ?? 0) as num),
                  'Harga/kg': money((o['price'] ?? 0) as num),
                  'Total': money((o['total'] ?? 0) as num),
                  'Tanggal masuk': reportDate(orderDate(o)) == '-'
                      ? '${o['created'] ?? '-'}'
                      : reportDate(orderDate(o)),
                  'Estimasi selesai': '${o['due'] ?? '-'}',
                  'Catatan': '${o['note'] ?? '-'}',
                  'Metode pembayaran': '${o['paymentMethod'] ?? '-'}',
                  'Status cucian':
                      '${o['laundryStatus'] ?? o['status'] ?? '-'}',
                  'Status pembayaran':
                      '${o['paymentStatus'] ?? 'Belum Dibayar'}',
                }.entries.map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(e.key,
                              style: const TextStyle(color: Colors.black54)),
                          Flexible(
                              child: Text(e.value,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)))
                        ]))),
                const SizedBox(height: 12),
                if (canOperate)
                  DropdownButtonFormField<String>(
                      initialValue: statuses.contains(laundryStatus(o))
                          ? laundryStatus(o)
                          : 'Antrean',
                      decoration:
                          const InputDecoration(labelText: 'Status pesanan'),
                      items: statuses
                          .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (s) async {
                        if (s == null) return;
                        try {
                          await db.collection('orders').doc(id).update({
                            'laundryStatus': s,
                            'updatedAt': FieldValue.serverTimestamp()
                          });
                          if (ctx.mounted) setModal(() {});
                          if (mounted) notice('Status diperbarui.');
                        } catch (e) {
                          if (mounted) notice('Gagal mengubah status: $e');
                        }
                      }),
                if (canOperate)
                  Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                          onPressed: () => editOrder(id, o),
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit pesanan'))),
                const SizedBox(height: 10)
              ]))));
  Future<void> editOrder(String id, Map<String, dynamic> old) async {
    Navigator.pop(context);
    await orderDialog(existingId: id, old: old);
  }

  Widget _selectedCustomerField(
      DocumentSnapshot<Map<String, dynamic>>? customer,
      {required bool canChange,
      required Future<void> Function() onChoose,
      required VoidCallback onClear}) {
    final data = customer?.data();
    final details = data == null
        ? null
        : (data['phone']?.toString().trim().isNotEmpty == true
            ? data['phone'].toString()
            : data['email']?.toString() ?? '');
    return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (data == null)
            OutlinedButton.icon(
                onPressed: canChange ? onChoose : null,
                icon: const Icon(Icons.person_search_outlined),
                label: const Text('Pilih pelanggan'))
          else
            Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                    leading:
                        const CircleAvatar(child: Icon(Icons.person_outline)),
                    title: Text('${data['name'] ?? 'Pelanggan'}'),
                    subtitle: Text(details?.isNotEmpty == true
                        ? details!
                        : '${data['email'] ?? 'Informasi kontak tidak tersedia'}'),
                    trailing: canChange
                        ? IconButton(
                            tooltip: 'Hapus pilihan pelanggan',
                            onPressed: onClear,
                            icon: const Icon(Icons.close))
                        : null)),
          if (data != null && canChange)
            Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                    onPressed: onChoose,
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('Ganti pelanggan')))
        ]));
  }

  Widget _priceRow(String label, String value, {bool emphasize = false}) =>
      Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(children: [
            Expanded(
                child: Text(label,
                    style: TextStyle(
                        color: emphasize ? ink : mutedInk,
                        fontSize: emphasize ? 17 : 14,
                        fontWeight:
                            emphasize ? FontWeight.w800 : FontWeight.w500))),
            const SizedBox(width: 12),
            Flexible(
                child: Text(value,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        color: emphasize ? const Color(0xFF1947AF) : ink,
                        fontSize: emphasize ? 22 : 15,
                        fontWeight:
                            emphasize ? FontWeight.w800 : FontWeight.w700)))
          ]));

  Future<void> orderDialog(
      {String? existingId, Map<String, dynamic>? old}) async {
    if (!canOperate) return;
    final services = await db.collection('services').get();
    if (!mounted) return;
    if (services.docs.isEmpty) {
      notice('Tambahkan layanan terlebih dahulu di menu Layanan.');
      return;
    }
    DocumentSnapshot<Map<String, dynamic>>? selectedCustomer;
    final oldCustomerId = old?['customerId'] as String?;
    if (oldCustomerId != null) {
      final snapshot = await db.collection('users').doc(oldCustomerId).get();
      if (snapshot.exists && snapshot.data()?['role'] == 'Pelanggan') {
        selectedCustomer = snapshot;
      }
    }
    if (!mounted) return;

    String? serviceId =
        (old?['serviceId'] as String?) ?? services.docs.first.id;
    final kg =
        TextEditingController(text: old == null ? '' : '${old['kg'] ?? ''}');
    final due = TextEditingController(text: '${old?['due'] ?? dateAfter(1)}');
    final note = TextEditingController(text: '${old?['note'] ?? ''}');
    await showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(builder: (ctx, setD) {
              final service =
                  services.docs.where((d) => d.id == serviceId).firstOrNull;
              final weight = double.tryParse(kg.text.replaceAll(',', '.')) ?? 0;
              final price = (service?.data()['price'] ?? 0) as num;
              Widget section(int number, String label, Widget child) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(children: [
                              CircleAvatar(
                                  radius: 17,
                                  backgroundColor: blue,
                                  child: Text('$number',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800))),
                              const SizedBox(width: 10),
                              Text(label,
                                  style: const TextStyle(
                                      color: ink,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800))
                            ]),
                            const SizedBox(height: 14),
                            child
                          ])));
              Future<void> chooseCustomer() async {
                final customer =
                    await showDialog<DocumentSnapshot<Map<String, dynamic>>>(
                        context: ctx,
                        builder: (_) => const _CustomerSearchDialog());
                if (customer != null) {
                  setD(() => selectedCustomer = customer);
                }
              }

              return AlertDialog(
                  title: Text(
                      existingId == null ? 'Buat Pesanan' : 'Edit Pesanan',
                      style: const TextStyle(
                          color: ink,
                          fontSize: 22,
                          fontWeight: FontWeight.w800)),
                  content: SizedBox(
                      width: 520,
                      child: SingleChildScrollView(
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                        section(
                            1,
                            'Pelanggan',
                            _selectedCustomerField(selectedCustomer,
                                canChange: existingId == null || isOwner,
                                onChoose: chooseCustomer,
                                onClear: () =>
                                    setD(() => selectedCustomer = null))),
                        section(
                            2,
                            'Layanan',
                            Column(children: [
                              ...services.docs.map((doc) {
                                final serviceData = doc.data();
                                final selected = serviceId == doc.id;
                                return Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 8),
                                    child: InkWell(
                                        borderRadius:
                                            BorderRadius.circular(16),
                                        onTap: existingId != null && !isOwner
                                            ? null
                                            : () => setD(
                                                () => serviceId = doc.id),
                                        child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 14),
                                            decoration: BoxDecoration(
                                                color: selected
                                                    ? const Color(0xFFF1F5FF)
                                                    : Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                border: Border.all(
                                                    color: selected
                                                        ? blue
                                                        : outline,
                                                    width: selected ? 2 : 1)),
                                            child: Row(children: [
                                              Icon(
                                                  selected
                                                      ? Icons
                                                          .radio_button_checked
                                                      : Icons
                                                          .radio_button_off,
                                                  color: selected
                                                      ? blue
                                                      : mutedInk),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                  child: Text(
                                                      '${serviceData['name'] ?? '-'}',
                                                      style: TextStyle(
                                                          color: selected
                                                              ? blue
                                                              : ink,
                                                          fontWeight:
                                                              FontWeight.w700))),
                                              Text(
                                                  '${money((serviceData['price'] ?? 0) as num)}/kg',
                                                  style: TextStyle(
                                                      color: selected
                                                          ? blue
                                                          : mutedInk,
                                                      fontWeight:
                                                          FontWeight.w700))
                                            ]))));
                              })
                            ])),
                        section(
                            3,
                            'Berat',
                            TextField(
                                controller: kg,
                                enabled: existingId == null || isOwner,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: ink),
                                decoration: const InputDecoration(
                                    hintText: 'Masukkan berat',
                                    suffixText: 'kg'),
                                onChanged: (_) => setD(() {}))),
                        section(
                            4,
                            'Ringkasan harga',
                            Column(children: [
                              _priceRow(
                                  'Layanan',
                                  '${service?.data()['name'] ?? '-'}'),
                              _priceRow('Harga per kg', money(price)),
                              _priceRow(
                                  'Berat',
                                  weight > 0
                                      ? weightText(weight)
                                      : 'Belum diisi'),
                              _priceRow('Pembayaran', 'Tunai'),
                              const Divider(color: outline),
                              _priceRow('Total', money(weight * price),
                                  emphasize: true)
                            ])),
                        Card(
                            margin: EdgeInsets.zero,
                            child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(children: [
                                  TextField(
                                      controller: due,
                                      decoration: const InputDecoration(
                                          labelText: 'Estimasi selesai')),
                                  const SizedBox(height: 10),
                                  TextField(
                                      controller: note,
                                      maxLines: 2,
                                      decoration: const InputDecoration(
                                          labelText: 'Catatan (opsional)'))
                                ])))
                      ]))),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Batal')),
                    FilledButton(
                        onPressed: () async {
                          final w =
                              double.tryParse(kg.text.replaceAll(',', '.'));
                          final cu = selectedCustomer;
                          final se = services.docs
                              .where((d) => d.id == serviceId)
                              .firstOrNull;
                          final serviceData = se?.data();
                          final rawPrice = serviceData?['price'];
                          if (cu == null ||
                              !cu.exists ||
                              cu.data() == null ||
                              se == null ||
                              w == null ||
                              !w.isFinite ||
                              w <= 0 ||
                              rawPrice is! num ||
                              !rawPrice.isFinite ||
                              rawPrice <= 0) {
                            notice(
                                'Pilih pelanggan dan layanan yang valid, lalu masukkan berat lebih dari 0 kg.');
                            return;
                          }
                          final u = cu.data()!, s = se.data();
                          if (u['role'] != 'Pelanggan') {
                            notice('Akun yang dipilih bukan akun pelanggan.');
                            return;
                          }
                          if (u.containsKey('isActive') &&
                              u['isActive'] != true) {
                            notice(
                                'Akun pelanggan sudah tidak aktif. Pilih pelanggan lain.');
                            return;
                          }
                          final p = rawPrice;
                          final total = w * p;
                          if (!total.isFinite || total <= 0) {
                            notice('Total pesanan tidak valid.');
                            return;
                          }
                          final payload = {
                            'customerId': cu.id,
                            'customerName': u['name'] ?? '',
                            'customerEmail': u['email'] ?? '',
                            'serviceId': se.id,
                            'serviceName': s['name'] ?? '',
                            'kg': w,
                            'price': p,
                            'total': total,
                            'laundryStatus': old?['laundryStatus'] ??
                                old?['status'] ??
                                'Antrean',
                            'created': old?['created'] ?? dateNow(),
                            'due': due.text.trim(),
                            'note': note.text.trim(),
                            if (existingId == null) ...{
                              'createdBy': widget.uid,
                              'createdByName': widget.name,
                              'orderNumber': '',
                              'paymentMethod': null,
                              'paymentStatus': 'Belum Dibayar'
                            },
                            'updatedAt': FieldValue.serverTimestamp()
                          };
                          var firestoreOperation = 'menyiapkan penyimpanan';
                          try {
                            if (existingId == null) {
                              firestoreOperation =
                                  'membaca profil operator users/${widget.uid}';
                              final actorSnapshot = await db
                                  .collection('users')
                                  .doc(widget.uid)
                                  .get();
                              final actor = actorSnapshot.data();
                              if (!actorSnapshot.exists ||
                                  actor == null ||
                                  (actor.containsKey('isActive') &&
                                      actor['isActive'] != true) ||
                                  !['Owner', 'Petugas']
                                      .contains(actor['role']) ||
                                  actor['name'] is! String) {
                                notice(
                                    'Profil petugas tidak valid atau tidak aktif. Silakan masuk kembali atau hubungi Owner.');
                                return;
                              }
                              payload['createdByName'] = actor['name'];
                              final counterRef =
                                  db.collection('counters').doc('orders');

                              await db.runTransaction((transaction) async {
                                firestoreOperation =
                                    'membaca counter counters/orders';
                                final counterSnap =
                                    await transaction.get(counterRef);

                                final lastNumber =
                                    (counterSnap.data()?['lastNumber'] as num?)
                                            ?.toInt() ??
                                        0;

                                var nextNumber = lastNumber + 1;
                                late DocumentReference<Map<String, dynamic>>
                                    orderRef;
                                late String orderNumber;
                                while (true) {
                                  orderNumber =
                                      'HDP-${nextNumber.toString().padLeft(3, '0')}';
                                  final candidate =
                                      db.collection('orders').doc(orderNumber);
                                  firestoreOperation =
                                      'memeriksa nomor pesanan orders/$orderNumber';
                                  final existing =
                                      await transaction.get(candidate);
                                  if (!existing.exists) {
                                    orderRef = candidate;
                                    break;
                                  }
                                  nextNumber++;
                                }

                                payload['createdAt'] =
                                    FieldValue.serverTimestamp();
                                payload['orderNumber'] = orderNumber;

                                debugPrint(
                                    'Membuat pesanan: actorRole=${actor['role']}, actorActiveValid=${!actor.containsKey('isActive') || actor['isActive'] == true}, customerRole=${u['role']}, customerActiveValid=${!u.containsKey('isActive') || u['isActive'] == true}, servicePriceMatches=${s['price'] == p}, counterExists=${counterSnap.exists}, counterHasLastNumber=${counterSnap.data()?.containsKey('lastNumber') ?? false}, counterValue=${counterSnap.data()?['lastNumber']}, counterValueType=${counterSnap.data()?['lastNumber']?.runtimeType}, previousCounter=$lastNumber, nextCounter=$nextNumber, targetOrderExists=false, status=${payload['laundryStatus']}, paymentMethodIsNull=${payload['paymentMethod'] == null}, kgType=${w.runtimeType}, priceType=${p.runtimeType}, totalType=${total.runtimeType}, totalMatches=${total == w * p}');
                                firestoreOperation =
                                    'menyimpan counter dan pesanan $orderNumber dalam satu transaksi';
                                transaction.set(
                                    counterRef,
                                    {'lastNumber': nextNumber},
                                    SetOptions(merge: true));
                                transaction.set(orderRef, payload);
                              });
                            } else {
                              firestoreOperation =
                                  'memperbarui pesanan orders/$existingId';
                              await db
                                  .collection('orders')
                                  .doc(existingId)
                                  .update(payload);
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (mounted) {
                              notice(
                                  'Pesanan berhasil disimpan dan tersinkron.');
                            }
                          } on FirebaseException catch (e) {
                            debugPrint(
                                'Gagal menyimpan pesanan; operasi="$firestoreOperation"; FirebaseException.code=${e.code}; message=${e.message}');
                            if (mounted) {
                              notice(_orderSaveErrorMessage(
                                  e, firestoreOperation));
                            }
                          } catch (e, stackTrace) {
                            debugPrint(
                                'Gagal menyimpan pesanan; operasi="$firestoreOperation"; error=$e\n$stackTrace');
                            if (mounted) {
                              notice(
                                  'Gagal menyimpan pesanan. Periksa data pesanan dan koneksi, lalu coba lagi.');
                            }
                          }
                        },
                        child: const Text('Simpan Pesanan'))
                  ]);
            }));
  }

  String _orderSaveErrorMessage(
      FirebaseException error, String firestoreOperation) {
    return switch (error.code) {
      'permission-denied' =>
        'Firestore menolak operasi "$firestoreOperation". Periksa profil akun dan aturan Firestore yang aktif; tidak ada perubahan yang disimpan.',
      'unauthenticated' =>
        'Sesi login tidak valid. Silakan keluar lalu masuk kembali.',
      'unavailable' ||
      'network-request-failed' =>
        'Firestore tidak dapat dijangkau. Periksa koneksi internet lalu coba lagi.',
      'aborted' =>
        'Penyimpanan bentrok dengan perubahan lain. Coba simpan kembali.',
      'already-exists' =>
        'Nomor pesanan tujuan sudah digunakan. Coba simpan kembali agar nomor berikutnya dipilih.',
      'failed-precondition' =>
        'Firestore menolak prasyarat pada operasi "$firestoreOperation". Periksa konfigurasi database dan coba lagi.',
      'invalid-argument' =>
        'Firestore menolak data pada operasi "$firestoreOperation". Periksa berat, harga layanan, dan total pesanan.',
      _ =>
        'Gagal pada operasi "$firestoreOperation" (${error.code}). ${error.message ?? 'Periksa konfigurasi Firestore dan koneksi.'}'
    };
  }
}
