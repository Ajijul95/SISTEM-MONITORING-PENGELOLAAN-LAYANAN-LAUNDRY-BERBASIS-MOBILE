part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

extension _HomeAccountsFeature on _HomePageState {
  Widget managementPage() => Column(children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
            child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                    color: const Color(0xFFE4E8F0),
                    borderRadius: BorderRadius.circular(20)),
                child: Row(children: [
                  _managementTab('Akun', Icons.people_alt_outlined, false),
                  _managementTab(
                      'Layanan & Harga', Icons.sell_outlined, true)
                ]))),
        Expanded(child: managementServices ? servicesPage() : usersPage())
      ]);

  Widget _managementTab(String label, IconData icon, bool services) {
    final selected = managementServices == services;
    return Expanded(
        child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => managementServices = services),
            child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                decoration: BoxDecoration(
                    color: selected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: selected
                        ? const [
                            BoxShadow(
                                color: Color(0x160D1B34),
                                blurRadius: 8,
                                offset: Offset(0, 2))
                          ]
                        : null),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon,
                          color: selected ? blue : mutedInk, size: 19),
                      const SizedBox(width: 7),
                      Flexible(
                          child: Text(label,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: selected ? blue : mutedInk,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13)))
                    ]))));
  }

  Future<void> addManagedAccount() async {
    final name = TextEditingController();
    final email = TextEditingController();
    final phone = TextEditingController();
    final password = TextEditingController();
    const role = 'Petugas';
    var busy = false;
    await showDialog<void>(
        context: context,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, setDialog) => AlertDialog(
                    title: const Text('Tambah Akun'),
                    content: SingleChildScrollView(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                      const ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Role'),
                          subtitle: Text('Petugas')),
                      spacedFormField(TextField(
                          controller: name,
                          decoration:
                              const InputDecoration(labelText: 'Nama'))),
                      spacedFormField(TextField(
                          controller: email,
                          keyboardType: TextInputType.emailAddress,
                          decoration:
                              const InputDecoration(labelText: 'Email'))),
                      spacedFormField(TextField(
                          controller: phone,
                          keyboardType: TextInputType.phone,
                          decoration:
                              const InputDecoration(labelText: 'Nomor HP'))),
                      spacedFormField(TextField(
                          controller: password,
                          obscureText: true,
                          decoration: const InputDecoration(
                              labelText: 'Kata sandi awal (min. 6 karakter)'))),
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
                                      email.text.trim().isEmpty ||
                                      phone.text.trim().isEmpty ||
                                      password.text.length < 6) {
                                    notice(
                                        'Lengkapi data dan kata sandi minimal 6 karakter.');
                                    return;
                                  }
                                  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                      .hasMatch(email.text.trim())) {
                                    notice('Format email tidak valid.');
                                    return;
                                  }
                                  setDialog(() => busy = true);
                                  FirebaseApp? secondaryApp;
                                  FirebaseAuth? secondaryAuth;
                                  try {
                                    try {
                                      secondaryApp =
                                          Firebase.app('managedAccountApp');
                                    } on FirebaseException {
                                      secondaryApp =
                                          await Firebase.initializeApp(
                                        name: 'managedAccountApp',
                                        options: Firebase.app().options,
                                      );
                                    }
                                    secondaryAuth = FirebaseAuth.instanceFor(
                                        app: secondaryApp);
                                    await secondaryAuth.signOut();
                                    final credential = await secondaryAuth
                                        .createUserWithEmailAndPassword(
                                      email: email.text.trim(),
                                      password: password.text,
                                    );
                                    final createdUser = credential.user;
                                    if (createdUser == null) {
                                      throw StateError(
                                          'Firebase tidak mengembalikan akun baru.');
                                    }
                                    try {
                                      await db
                                          .collection('users')
                                          .doc(createdUser.uid)
                                          .set({
                                        'uid': createdUser.uid,
                                        'name': name.text.trim(),
                                        'email': email.text.trim(),
                                        'phone': phone.text.trim(),
                                        'role': role,
                                        'isActive': true,
                                        'createdAt':
                                            FieldValue.serverTimestamp(),
                                        'updatedAt':
                                            FieldValue.serverTimestamp(),
                                      });
                                    } catch (_) {
                                      try {
                                        await createdUser.delete();
                                      } catch (_) {
                                        throw StateError(
                                            'Profil gagal disimpan dan akun Auth sementara tidak dapat dibersihkan. Hubungi administrator Firebase.');
                                      }
                                      rethrow;
                                    }
                                    if (ctx.mounted) {
                                      Navigator.pop(ctx);
                                    }
                                    if (mounted) {
                                      notice('Akun $role berhasil dibuat.');
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      notice(
                                          'Gagal membuat akun: ${managedAccountError(e)}');
                                    }
                                    if (ctx.mounted) {
                                      setDialog(() => busy = false);
                                    }
                                  } finally {
                                    if (secondaryAuth != null) {
                                      try {
                                        await secondaryAuth.signOut();
                                      } catch (_) {}
                                    }
                                    if (secondaryApp != null) {
                                      try {
                                        await secondaryApp.delete();
                                      } catch (_) {}
                                    }
                                  }
                                },
                          child: busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Buat Akun'))
                    ])));
  }

  Future<void> editAccountProfile(String id, Map<String, dynamic> user) async {
    final name = TextEditingController(text: '${user['name'] ?? ''}');
    final email = TextEditingController(text: '${user['email'] ?? ''}');
    final phone = TextEditingController(text: '${user['phone'] ?? ''}');
    final address = TextEditingController(text: '${user['address'] ?? ''}');
    var role = '${user['role'] ?? 'Pelanggan'}';
    final originalRole = role;
    var isActive = user['isActive'] != false;
    await showDialog<void>(
        context: context,
        builder: (ctx) {
          final dialogWidth =
              (MediaQuery.sizeOf(ctx).width - 48).clamp(280.0, 480.0);
          return StatefulBuilder(
              builder: (ctx, setDialog) => AlertDialog(
                      scrollable: true,
                      insetPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 24),
                      title: const Text('Edit akun'),
                      content: SizedBox(
                          width: dialogWidth,
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            spacedFormField(TextField(
                                controller: name,
                                decoration:
                                    const InputDecoration(labelText: 'Nama'))),
                            spacedFormField(TextField(
                                controller: email,
                                readOnly: true,
                                decoration:
                                    const InputDecoration(labelText: 'Email'))),
                            spacedFormField(TextField(
                                controller: phone,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                    labelText: 'Nomor HP'))),
                            if (role == 'Pelanggan')
                              spacedFormField(TextField(
                                  controller: address,
                                  decoration: const InputDecoration(
                                      labelText: 'Alamat'))),
                            spacedFormField(DropdownButtonFormField<String>(
                                initialValue: role,
                                decoration:
                                    const InputDecoration(labelText: 'Peran'),
                                items: const ['Petugas', 'Pelanggan']
                                    .map((value) => DropdownMenuItem(
                                        value: value, child: Text(value)))
                                    .toList(),
                                onChanged: (value) =>
                                    setDialog(() => role = value ?? role))),
                            SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Akun aktif'),
                                value: isActive,
                                onChanged: (value) =>
                                    setDialog(() => isActive = value))
                          ])),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Batal')),
                        FilledButton(
                            onPressed: () async {
                              if (name.text.trim().isEmpty) {
                                notice('Nama wajib diisi.');
                                return;
                              }
                              if (role != originalRole) {
                                final confirmed = await showDialog<bool>(
                                    context: ctx,
                                    builder: (confirmCtx) => AlertDialog(
                                            title:
                                                const Text('Ubah peran akun?'),
                                            content: Text(
                                                'Peran akun akan diubah dari $originalRole menjadi $role.'),
                                            actions: [
                                              TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          confirmCtx, false),
                                                  child: const Text('Batal')),
                                              FilledButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          confirmCtx, true),
                                                  child:
                                                      const Text('Ubah peran'))
                                            ]));
                                if (confirmed != true) return;
                              }
                              try {
                                await db.collection('users').doc(id).update({
                                  'name': name.text.trim(),
                                  'phone': phone.text.trim(),
                                  'address': address.text.trim(),
                                  'role': role,
                                  'isActive': isActive,
                                  'updatedAt': FieldValue.serverTimestamp(),
                                });
                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                }
                                if (mounted) {
                                  notice('Akun diperbarui.');
                                }
                              } catch (e) {
                                if (mounted) {
                                  notice(
                                      'Gagal memperbarui akun: ${managedAccountError(e)}');
                                }
                              }
                            },
                            child: const Text('Simpan'))
                      ]));
        });
  }

  Future<void> removeManagedAccount(String id) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text('Hapus akun?'),
                content: const Text(
                    'Profil akan dihapus dari Firestore sehingga akun tidak dapat mengakses aplikasi. Identitas Firebase Authentication tidak dapat dihapus dari aplikasi.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Batal')),
                  FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Hapus'))
                ]));
    if (confirmed != true) return;
    try {
      await db.collection('users').doc(id).delete();
      if (mounted) notice('Profil akun dihapus dari HDP Laundry.');
    } catch (e) {
      if (mounted) {
        notice('Gagal menghapus profil: ${managedAccountError(e)}');
      }
    }
  }

  Future<void> viewAccount(Map<String, dynamic> user) => showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
              title: const Text('Detail akun'),
              content: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFFE4ECFA),
                    child: Icon(
                        user['role'] == 'Owner'
                            ? Icons.admin_panel_settings_outlined
                            : user['role'] == 'Petugas'
                                ? Icons.badge_outlined
                                : Icons.person_outline,
                        color: blue)),
                const SizedBox(height: 12),
                _accountDetail('Nama', '${user['name'] ?? '-'}'),
                _accountDetail('Email', '${user['email'] ?? '-'}'),
                _accountDetail('Nomor HP', '${user['phone'] ?? '-'}'),
                if ('${user['address'] ?? ''}'.isNotEmpty)
                  _accountDetail('Alamat', '${user['address']}'),
                _accountDetail('Peran', '${user['role'] ?? '-'}'),
                _accountDetail(
                    'Status', user['isActive'] == false ? 'Nonaktif' : 'Aktif'),
              ])),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Tutup'))
              ]));

  Widget _accountDetail(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            width: 90,
            child:
                Text(label, style: const TextStyle(color: Color(0xFF64748B)))),
        Expanded(
            child: Text(value,
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w600)))
      ]));

  Widget usersPage() => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: db
          .collection('users')
          .where('role', isEqualTo: accountFilter)
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
              child: Text(
                  'Gagal memuat pengguna: ${managedAccountError(snap.error!)}'));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final search = accountSearch.trim().toLowerCase();
        final users = snap.data!.docs.where((doc) {
          if (search.isEmpty) return true;
          final user = doc.data();
          return [
            user['name'],
            user['email'],
            user['phone'],
            user['address'],
            user['role']
          ].any((value) => '$value'.toLowerCase().contains(search));
        }).toList();
        return ListView(padding: const EdgeInsets.all(18), children: [
          title('Kelola Akun'),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final entry in const {
              'Pelanggan': Icons.person_outline,
              'Petugas': Icons.badge_outlined,
              'Owner': Icons.admin_panel_settings_outlined,
            }.entries)
              ChoiceChip(
                  selected: accountFilter == entry.key,
                  avatar: Icon(entry.value, size: 18),
                  label: Text(entry.key),
                  onSelected: (_) => setState(() {
                        accountFilter = entry.key;
                        accountSearch = '';
                        accountSearchController.clear();
                      })),
            if (accountFilter != 'Owner')
              FilledButton.icon(
                  onPressed: addManagedAccount,
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Tambah Petugas'))
          ]),
          const SizedBox(height: 12),
          TextField(
              controller: accountSearchController,
              onChanged: (value) => setState(() => accountSearch = value),
              decoration: InputDecoration(
                  labelText: 'Cari akun',
                  hintText: 'Nama, email, nomor HP, atau alamat',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: accountSearch.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Hapus pencarian',
                          onPressed: () {
                            accountSearchController.clear();
                            setState(() => accountSearch = '');
                          },
                          icon: const Icon(Icons.close))),
              textInputAction: TextInputAction.search),
          const SizedBox(height: 16),
          if (users.isEmpty)
            Center(
                child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                        search.isEmpty
                            ? 'Belum ada akun ${accountFilter.toLowerCase()}.'
                            : 'Tidak ditemukan akun yang sesuai.',
                        style: const TextStyle(color: Color(0xFF64748B)))))
          else
            ...users.map((d) {
              final u = d.data();
              final isActive = u['isActive'] != false;
              final roleColor = switch (u['role']) {
                'Owner' => const Color(0xFF7C3AED),
                'Petugas' => const Color(0xFF0F766E),
                _ => blue
              };
              return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                          color: const Color(0xFFEDF2FF),
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      child: Icon(
                                          u['role'] == 'Owner'
                                              ? Icons
                                                  .admin_panel_settings_outlined
                                              : u['role'] == 'Petugas'
                                                  ? Icons.badge_outlined
                                                  : Icons.person_outline,
                                          color: roleColor,
                                          size: 24)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                        Text('${u['name'] ?? '-'}',
                                            style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700)),
                                        const SizedBox(height: 4),
                                        Text('${u['email'] ?? ''}',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF64748B))),
                                        const SizedBox(height: 2),
                                        Row(children: [
                                          DecoratedBox(
                                              decoration: BoxDecoration(
                                                  color: isActive
                                                      ? const Color(0xFFDCFCE7)
                                                      : const Color(0xFFFEE2E2),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          999)),
                                              child: Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                                  child: Text(
                                                      isActive
                                                          ? 'Aktif'
                                                          : 'Nonaktif',
                                                      style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: isActive
                                                              ? const Color(
                                                                  0xFF16A34A)
                                                              : const Color(
                                                                  0xFFDC2626))))),
                                          const SizedBox(width: 8),
                                          DecoratedBox(
                                              decoration: BoxDecoration(
                                                  color: roleColor.withValues(
                                                      alpha: 0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          999)),
                                              child: Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                                  child: Text(
                                                      '${u['role'] ?? 'Pelanggan'}',
                                                      style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: roleColor))))
                                        ])
                                      ])),
                                  if (u['role'] != 'Owner')
                                    PopupMenuButton<String>(
                                        tooltip: 'Kelola akun',
                                        onSelected: (action) async {
                                          if (action == 'view') {
                                            viewAccount(u);
                                          } else if (action == 'edit') {
                                            editAccountProfile(d.id, u);
                                          } else if (action == 'toggle') {
                                            final confirmed = await showDialog<
                                                    bool>(
                                                context: context,
                                                builder: (confirmCtx) =>
                                                    AlertDialog(
                                                        title: Text(isActive
                                                            ? 'Nonaktifkan akun?'
                                                            : 'Aktifkan akun?'),
                                                        content: Text(
                                                            'Akun ${u['name'] ?? ''} akan ${isActive ? 'dinonaktifkan' : 'diaktifkan'}.'),
                                                        actions: [
                                                          TextButton(
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                      confirmCtx,
                                                                      false),
                                                              child: const Text(
                                                                  'Batal')),
                                                          FilledButton(
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                      confirmCtx,
                                                                      true),
                                                              child: Text(isActive
                                                                  ? 'Nonaktifkan'
                                                                  : 'Aktifkan'))
                                                        ]));
                                            if (confirmed != true) return;
                                            try {
                                              await db
                                                  .collection('users')
                                                  .doc(d.id)
                                                  .update({
                                                'isActive':
                                                    u['isActive'] == false,
                                                'updatedAt': FieldValue
                                                    .serverTimestamp(),
                                              });
                                              if (mounted) {
                                                notice(
                                                    'Status akun diperbarui.');
                                              }
                                            } catch (e) {
                                              if (mounted) {
                                                notice(
                                                    'Gagal mengubah status: ${managedAccountError(e)}');
                                              }
                                            }
                                          } else if (action == 'delete') {
                                            removeManagedAccount(d.id);
                                          }
                                        },
                                        itemBuilder: (_) => [
                                              const PopupMenuItem(
                                                  value: 'view',
                                                  child: Row(children: [
                                                    Icon(
                                                        Icons
                                                            .visibility_outlined,
                                                        size: 18),
                                                    SizedBox(width: 8),
                                                    Text('Lihat detail')
                                                  ])),
                                              const PopupMenuItem(
                                                  value: 'edit',
                                                  child: Row(children: [
                                                    Icon(Icons.edit, size: 18),
                                                    SizedBox(width: 8),
                                                    Text('Edit akun')
                                                  ])),
                                              PopupMenuItem(
                                                  value: 'toggle',
                                                  child: Row(children: [
                                                    Icon(
                                                        isActive
                                                            ? Icons
                                                                .block_outlined
                                                            : Icons
                                                                .check_circle_outline,
                                                        size: 18),
                                                    const SizedBox(width: 8),
                                                    Text(isActive
                                                        ? 'Nonaktifkan akun'
                                                        : 'Aktifkan akun')
                                                  ])),
                                              const PopupMenuItem(
                                                  value: 'delete',
                                                  child: Row(children: [
                                                    Icon(Icons.delete_outline,
                                                        size: 18,
                                                        color:
                                                            Color(0xFFDC2626)),
                                                    SizedBox(width: 8),
                                                    Text('Hapus akun',
                                                        style: TextStyle(
                                                            color: Color(
                                                                0xFFDC2626)))
                                                  ]))
                                            ])
                                  else
                                    IconButton(
                                        tooltip: 'Lihat detail',
                                        onPressed: () => viewAccount(u),
                                        icon: const Icon(
                                            Icons.visibility_outlined))
                                ])
                          ])));
            })
        ]);
      });
}
