part of '../../main.dart';

extension _HomeProfileFeature on _HomePageState {
  Future<void> editProfile(Map<String, dynamic> current) async {
    final name = TextEditingController(text: '${current['name'] ?? ''}');
    final email = TextEditingController(text: '${current['email'] ?? ''}');
    final phone = TextEditingController(text: '${current['phone'] ?? ''}');
    final address = TextEditingController(text: '${current['address'] ?? ''}');
    var busy = false;
    await showDialog<void>(
        context: context,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, setDialog) => AlertDialog(
                    title: const Text('Edit Profil'),
                    content: SingleChildScrollView(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                      const CircleAvatar(
                          radius: 38, child: Icon(Icons.person, size: 38)),
                      spacedFormField(TextField(
                          controller: name,
                          decoration:
                              const InputDecoration(labelText: 'Nama'))),
                      spacedFormField(TextField(
                          controller: phone,
                          keyboardType: TextInputType.phone,
                          decoration:
                              const InputDecoration(labelText: 'Nomor HP'))),
                      spacedFormField(TextField(
                          controller: email,
                          keyboardType: TextInputType.emailAddress,
                          decoration:
                              const InputDecoration(labelText: 'Email'))),
                      if (isCustomer)
                        spacedFormField(TextField(
                            controller: address,
                            decoration:
                                const InputDecoration(labelText: 'Alamat'))),
                    ])),
                    actions: [
                      TextButton(
                          onPressed: busy ? null : () => Navigator.pop(ctx),
                          child: const Text('Batal')),
                      FilledButton(
                          onPressed: busy
                              ? null
                              : () async {
                                  if (name.text.trim().isEmpty ||
                                      email.text.trim().isEmpty) {
                                    notice('Nama dan email wajib diisi.');
                                    return;
                                  }
                                  setDialog(() => busy = true);
                                  try {
                                    final emailChanged = email.text.trim() !=
                                        auth.currentUser?.email;
                                    if (emailChanged) {
                                      await auth.currentUser
                                          ?.verifyBeforeUpdateEmail(
                                              email.text.trim());
                                    }
                                    await db
                                        .collection('users')
                                        .doc(widget.uid)
                                        .update({
                                      'name': name.text.trim(),
                                      if (!emailChanged)
                                        'email': email.text.trim(),
                                      if (emailChanged)
                                        'pendingEmail': email.text.trim(),
                                      'phone': phone.text.trim(),
                                      if (isCustomer)
                                        'address': address.text.trim(),
                                      'updatedAt': FieldValue.serverTimestamp()
                                    });
                                    if (ctx.mounted) Navigator.pop(ctx);
                                    if (mounted) {
                                      notice(emailChanged
                                          ? 'Tautan verifikasi email telah dikirim.'
                                          : 'Profil diperbarui.');
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      notice('Gagal memperbarui profil: $e');
                                    }
                                    if (ctx.mounted) {
                                      setDialog(() => busy = false);
                                    }
                                  }
                                },
                          child: busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Simpan'))
                    ])));
  }

  Future<void> syncVerifiedEmail(String pendingEmail) async {
    try {
      await auth.currentUser?.reload();
      if (auth.currentUser?.email != pendingEmail) {
        if (mounted) notice('Email belum diverifikasi.');
        return;
      }
      await db.collection('users').doc(widget.uid).update({
        'email': pendingEmail,
        'pendingEmail': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp()
      });
      if (mounted) notice('Email profil berhasil diperbarui.');
    } catch (e) {
      if (mounted) notice('Gagal memeriksa verifikasi email: $e');
    }
  }

  Widget profilePage() => StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: db.collection('users').doc(widget.uid).snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('Gagal memuat profil: ${snap.error}'));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snap.data!.data() ?? {};
        final displayName = '${data['name'] ?? widget.name}';
        final initials = displayName
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((part) => part[0])
            .join()
            .toUpperCase();
        return ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            children: [
          Card(
              child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 26),
                  child: Column(children: [
                    CircleAvatar(
                        radius: 48,
                        backgroundColor: paleBlue,
                        child: Text(initials,
                            style: const TextStyle(
                                fontSize: 30,
                                color: blue,
                                fontWeight: FontWeight.w800))),
                    const SizedBox(height: 14),
                    Text(displayName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 23,
                            color: ink,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('${data['email'] ?? widget.email}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: mutedInk)),
                    const SizedBox(height: 12),
                    DecoratedBox(
                        decoration: BoxDecoration(
                            color: widget.role == 'Petugas'
                                ? paleTeal
                                : paleBlue,
                            borderRadius: BorderRadius.circular(999)),
                        child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            child: Text(widget.role,
                                style: TextStyle(
                                    color: widget.role == 'Petugas'
                                        ? teal
                                        : blue,
                                    fontWeight: FontWeight.w700))))
                  ]))),
          const SizedBox(height: 16),
          Card(
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(children: [
                    _profileDetail(
                        'Nama lengkap', '${data['name'] ?? widget.name}'),
                    _profileDetail(
                        'Nomor HP', '${data['phone'] ?? widget.phone}'),
                    _profileDetail('Peran', widget.role),
                    if (isCustomer &&
                        '${data['address'] ?? ''}'.trim().isNotEmpty)
                      _profileDetail('Alamat', '${data['address']}'),
                    if (data['pendingEmail'] != null)
                      _profileDetail(
                          'Menunggu verifikasi', '${data['pendingEmail']}')
                  ]))),
          if (data['pendingEmail'] is String) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
                onPressed: () =>
                    syncVerifiedEmail(data['pendingEmail'] as String),
                icon: const Icon(Icons.mark_email_read_outlined),
                label: const Text('Saya sudah verifikasi email'))
          ],
          const SizedBox(height: 14),
          OutlinedButton.icon(
              onPressed: () => editProfile(data),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Ubah Profil'),
              style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                  foregroundColor: ink)),
          const SizedBox(height: 10),
          OutlinedButton.icon(
              onPressed: () => auth.signOut(),
              icon: const Icon(Icons.logout),
              label: const Text('Keluar'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFB42318),
                  side: const BorderSide(color: Color(0xFFE04438)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 18))),
        ]);
      });

  Widget _profileDetail(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: mutedInk, fontSize: 14)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: ink, fontSize: 17, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        const Divider(height: 1, color: outline)
      ]));
}
