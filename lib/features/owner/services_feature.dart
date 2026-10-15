part of '../../main.dart';

extension _HomeServicesFeature on _HomePageState {
  Widget servicesPage() => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: servicesStream,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('Gagal memuat layanan: ${snap.error}'));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data!.docs;
        return ListView(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
            children: [
          title('Layanan & Harga'),
          Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text('${docs.length} layanan',
                  style: const TextStyle(
                      color: mutedInk, fontWeight: FontWeight.w600))),
          ...docs.map((d) {
            final s = d.data();
            return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 9),
                    leading: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                            color: paleBlue,
                            borderRadius: BorderRadius.circular(18)),
                        child: const Icon(Icons.local_laundry_service_outlined,
                            color: blue)),
                    title: Text('${s['name'] ?? '-'}',
                        style: const TextStyle(
                            fontSize: 17,
                            color: ink,
                            fontWeight: FontWeight.w700)),
                    subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: RichText(
                            text: TextSpan(
                                style: const TextStyle(
                                    color: mutedInk, fontSize: 15),
                                children: [
                              TextSpan(
                                  text: money((s['price'] ?? 0) as num),
                                  style: const TextStyle(
                                      color: Color(0xFF1947AF),
                                      fontWeight: FontWeight.w800)),
                              const TextSpan(text: ' / kg')
                            ]))),
                    trailing: isOwner
                        ? PopupMenuButton<String>(
                            tooltip: 'Kelola layanan',
                            onSelected: (action) {
                              if (action == 'edit') editService(d.id, s);
                              if (action == 'delete') deleteService(d.id);
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Ubah layanan')),
                              PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Hapus layanan'))
                            ],
                            icon: const Icon(Icons.more_horiz, color: blue))
                        : null));
          }),
          if (isOwner) ...[
            const SizedBox(height: 8),
            FilledButton.icon(
                onPressed: () => serviceDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Tambah Layanan'))
          ]
        ]);
      });
  Future<void> editService(String id, Map<String, dynamic> service) =>
      serviceDialog(existingId: id, service: service);
  Future<void> serviceDialog(
      {String? existingId, Map<String, dynamic>? service}) async {
    final n = TextEditingController(text: '${service?['name'] ?? ''}');
    final p = TextEditingController(text: '${service?['price'] ?? ''}');
    await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
                title: Text(
                    existingId == null ? 'Tambah layanan' : 'Edit layanan'),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  spacedFormField(TextField(
                      controller: n,
                      decoration:
                          const InputDecoration(labelText: 'Nama layanan'))),
                  spacedFormField(TextField(
                      controller: p,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Harga per kg')))
                ]),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Batal')),
                  FilledButton(
                      onPressed: () async {
                        final price =
                            double.tryParse(p.text.replaceAll(',', '.'));
                        if (n.text.trim().isEmpty ||
                            price == null ||
                            price <= 0) {
                          notice('Isi nama dan harga yang benar.');
                          return;
                        }
                        try {
                          final payload = {
                            'name': n.text.trim(),
                            'price': price
                          };
                          if (existingId == null) {
                            await db.collection('services').add({
                              ...payload,
                              'createdAt': FieldValue.serverTimestamp()
                            });
                          } else {
                            await db
                                .collection('services')
                                .doc(existingId)
                                .update(payload);
                          }
                          if (ctx.mounted) Navigator.pop(ctx);
                        } catch (e) {
                          notice('Gagal menambah layanan: $e');
                        }
                      },
                      child: const Text('Simpan'))
                ]));
  }

  Future<void> deleteService(String id) async {
    try {
      await db.collection('services').doc(id).delete();
    } catch (e) {
      notice('Gagal menghapus layanan: $e');
    }
  }
}
