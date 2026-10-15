part of '../../main.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
        stream: auth.authStateChanges(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }
          if (snap.data == null) return const LoginPage();
          return ProfileGate(uid: snap.data!.uid);
        },
      );
}

class ProfileGate extends StatelessWidget {
  final String uid;
  const ProfileGate({super.key, required this.uid});
  @override
  Widget build(BuildContext context) =>
      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: db.collection('users').doc(uid).snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return ErrorPage(message: 'Gagal membaca profil: ${snap.error}');
          }
          if (!snap.hasData) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }
          if (!snap.data!.exists) {
            return const ErrorPage(
                message:
                    'Profil akun belum tersedia di Firestore. Hubungi owner untuk menyiapkan role akun.');
          }
          final data = snap.data!.data()!;
          if (data['isActive'] == false) {
            return const ErrorPage(
                message:
                    'Akun Anda sedang dinonaktifkan. Silakan hubungi Owner.');
          }
          final role = (data['role'] ?? 'Pelanggan').toString();
          return HomePage(
              uid: uid,
              name: (data['name'] ?? 'Pengguna').toString(),
              email:
                  (data['email'] ?? auth.currentUser?.email ?? '').toString(),
              phone: (data['phone'] ?? '').toString(),
              role: role);
        },
      );
}

class ErrorPage extends StatelessWidget {
  final String message;
  const ErrorPage({super.key, required this.message});
  @override
  Widget build(BuildContext context) => Scaffold(
      body: Center(
          child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.info_outline, size: 48, color: blue),
                const SizedBox(height: 12),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                    onPressed: () => auth.signOut(),
                    child: const Text('Kembali ke login'))
              ]))));
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController(), password = TextEditingController();
  bool busy = false, hide = true, rememberMe = true;
  Future<void> login() async {
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      msg('Masukkan email dan kata sandi.');
      return;
    }
    setState(() => busy = true);
    try {
      final credential = await auth.signInWithEmailAndPassword(
          email: email.text.trim(), password: password.text);
      final uid = credential.user?.uid;
      if (uid != null) {
        final profile = await db.collection('users').doc(uid).get();
        if (profile.exists && profile.data()?['isActive'] == false) {
          await auth.signOut();
          if (mounted) {
            msg('Akun Anda sedang dinonaktifkan. Silakan hubungi Owner.');
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      msg(authMessage(e));
    } on FirebaseException catch (e) {
      await auth.signOut();
      if (mounted) msg(managedAccountError(e));
    } catch (e) {
      await auth.signOut();
      if (mounted) msg('Login gagal. Periksa koneksi lalu coba lagi.');
    }
    if (mounted) setState(() => busy = false);
  }

  void msg(String s) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: const Color(0xFF2864EF),
      body: LayoutBuilder(builder: (context, constraints) {
        final compact = constraints.maxHeight < 700;
        final heroHeight = compact
            ? constraints.maxHeight * .20
            : (constraints.maxHeight * .30).clamp(210.0, 250.0);
        return Stack(children: [
          Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: heroHeight,
              child: _LoginHero(height: heroHeight, compact: compact)),
          Positioned(
              top: heroHeight - 28,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                  decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(34))),
                  child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                          26, compact ? 16 : 30, 26, compact ? 12 : 20),
                      child: Center(
                          child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 430),
                              child: TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0, end: 1),
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, value, child) => Opacity(
                                      opacity: value,
                                      child: Transform.translate(
                                          offset: Offset(0, (1 - value) * 12),
                                          child: child)),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        const Text('Masuk ke akun Anda',
                                            style: TextStyle(
                                                fontSize: 27,
                                                fontWeight: FontWeight.w800,
                                                color: ink)),
                                        SizedBox(height: compact ? 10 : 24),
                                        const Text('Email',
                                            style: TextStyle(
                                                color: ink,
                                                fontWeight: FontWeight.w600)),
                                        SizedBox(height: compact ? 4 : 7),
                                        TextField(
                                            controller: email,
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            textInputAction:
                                                TextInputAction.next,
                                            autofillHints: const [
                                              AutofillHints.email
                                            ],
                                            decoration: const InputDecoration(
                                                hintText: 'nama@email.com',
                                                prefixIcon:
                                                    Icon(Icons.mail_outline))),
                                        SizedBox(height: compact ? 8 : 16),
                                        const Text('Kata sandi',
                                            style: TextStyle(
                                                color: ink,
                                                fontWeight: FontWeight.w600)),
                                        SizedBox(height: compact ? 4 : 7),
                                        TextField(
                                            controller: password,
                                            obscureText: hide,
                                            textInputAction:
                                                TextInputAction.done,
                                            autofillHints: const [
                                              AutofillHints.password
                                            ],
                                            onSubmitted: (_) =>
                                                busy ? null : login(),
                                            decoration: InputDecoration(
                                                prefixIcon: const Icon(
                                                    Icons.lock_outline),
                                                suffixIcon: IconButton(
                                                    tooltip: hide
                                                        ? 'Tampilkan kata sandi'
                                                        : 'Sembunyikan kata sandi',
                                                    onPressed: () => setState(
                                                        () => hide = !hide),
                                                    icon: Icon(hide
                                                        ? Icons
                                                            .visibility_outlined
                                                        : Icons
                                                            .visibility_off_outlined)))),
                                        SizedBox(height: compact ? 4 : 8),
                                        Row(children: [
                                          Checkbox(
                                              value: rememberMe,
                                              activeColor: blue,
                                              visualDensity:
                                                  VisualDensity.compact,
                                              onChanged: (value) => setState(
                                                  () => rememberMe =
                                                      value ?? false)),
                                          const Text('Ingat saya',
                                              style:
                                                  TextStyle(color: mutedInk)),
                                          const Spacer(),
                                          const Text('Lupa kata sandi?',
                                              style: TextStyle(
                                                  color: blue,
                                                  fontWeight: FontWeight.w700))
                                        ]),
                                        SizedBox(height: compact ? 6 : 12),
                                        FilledButton(
                                            onPressed: busy ? null : login,
                                            style: FilledButton.styleFrom(
                                                backgroundColor: blue,
                                                foregroundColor: Colors.white,
                                                minimumSize:
                                                    Size(48, compact ? 52 : 58),
                                                elevation: 8,
                                                shadowColor:
                                                    blue.withValues(alpha: .3)),
                                            child: busy
                                                ? const SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color:
                                                                Colors.white))
                                                : const Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                        Text('Masuk',
                                                            style: TextStyle(
                                                                fontSize: 18,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700)),
                                                        SizedBox(width: 12),
                                                        Icon(
                                                            Icons.arrow_forward,
                                                            size: 23)
                                                      ])),
                                        SizedBox(height: compact ? 10 : 20),
                                        Row(children: [
                                          const Expanded(
                                              child: Divider(color: outline)),
                                          Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12),
                                              child: Text('Belum punya akun?',
                                                  style: TextStyle(
                                                      color: mutedInk,
                                                      fontSize:
                                                          compact ? 13 : 15))),
                                          const Expanded(
                                              child: Divider(color: outline))
                                        ]),
                                        SizedBox(height: compact ? 8 : 14),
                                        OutlinedButton(
                                            onPressed: busy
                                                ? null
                                                : () => Navigator.push(
                                                      context,
                                                      MaterialPageRoute<void>(
                                                        builder: (_) =>
                                                            const RegisterPage(),
                                                      ),
                                                    ),
                                            style: OutlinedButton.styleFrom(
                                                foregroundColor: blue,
                                                backgroundColor:
                                                    const Color(0xFFF1F6FF),
                                                minimumSize:
                                                    Size(48, compact ? 52 : 60),
                                                side: const BorderSide(
                                                    color: Color(0xFF3D68FF),
                                                    width: 1.4),
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            17))),
                                            child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.person_add_alt_1,
                                                      size: compact ? 20 : 23),
                                                  const SizedBox(width: 10),
                                                  Text('Registrasi Pelanggan',
                                                      style: TextStyle(
                                                          fontSize:
                                                              compact ? 15 : 17,
                                                          fontWeight:
                                                              FontWeight.w700))
                                                ])),
                                        SizedBox(height: compact ? 18 : 28),
                                        const Center(
                                            child: Text(
                                                'HDP Laundry · Bersih, wangi, rapi',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    color: mutedInk,
                                                    fontSize: 14)))
                                      ])))))))
        ]);
      }));
}

class _LoginHero extends StatelessWidget {
  final double height;
  final bool compact;
  const _LoginHero({required this.height, required this.compact});

  @override
  Widget build(BuildContext context) => Container(
      decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2864EF), Color(0xFF1D4ED8)])),
      child: Stack(alignment: Alignment.center, children: [
        Positioned(
            right: -55,
            top: -78,
            child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: .18), width: 3),
                    color: Colors.white.withValues(alpha: .06)))),
        Positioned(
            right: -12,
            top: -36,
            child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: .16),
                        width: 1.5)))),
        Positioned(
            left: -45,
            bottom: 35,
            child: Container(
                width: 125,
                height: 125,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: .08)))),
        Positioned(
            left: 48,
            top: height * .23,
            child: const _LoginBubble(size: 28, outlined: true)),
        const Positioned(
            right: 92,
            bottom: 48,
            child: _LoginBubble(size: 18, outlined: false)),
        Positioned(
            right: 68,
            top: height * .34,
            child: Icon(Icons.auto_awesome,
                size: compact ? 19 : 25,
                color: Colors.white.withValues(alpha: .9))),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: compact ? 72 : 112,
              height: compact ? 72 : 112,
              padding: EdgeInsets.all(compact ? 9 : 15),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(compact ? 21 : 30)),
              child:
                  Image.asset('assets/logo_laundry.png', fit: BoxFit.contain)),
          SizedBox(height: compact ? 2 : 24),
          Text('HDP Laundry',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 22 : 31,
                  fontWeight: FontWeight.w800))
        ])
      ]));
}

class _LoginBubble extends StatelessWidget {
  final double size;
  final bool outlined;
  const _LoginBubble({required this.size, required this.outlined});

  @override
  Widget build(BuildContext context) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: outlined
              ? Colors.transparent
              : Colors.white.withValues(alpha: .3),
          border: outlined
              ? Border.all(color: Colors.white.withValues(alpha: .42), width: 2)
              : null));
}

String authMessage(FirebaseAuthException e) => switch (e.code) {
      'invalid-email' => 'Format email tidak valid.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' =>
        'Email atau kata sandi salah.',
      'email-already-in-use' => 'Email sudah terdaftar.',
      'weak-password' => 'Kata sandi terlalu lemah (minimal 6 karakter).',
      'user-disabled' =>
        'Akun Anda sedang dinonaktifkan. Silakan hubungi Owner.',
      'network-request-failed' => 'Koneksi internet bermasalah.',
      _ => 'Login gagal. Periksa email, kata sandi, dan koneksi internet.'
    };

String managedAccountError(Object error) {
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'email-already-in-use' => 'Email sudah digunakan akun lain.',
      'invalid-email' => 'Format email tidak valid.',
      'weak-password' => 'Kata sandi terlalu lemah (minimal 6 karakter).',
      'network-request-failed' => 'Koneksi internet bermasalah.',
      'operation-not-allowed' =>
        'Login Email/Password belum diaktifkan di Firebase Authentication.',
      'too-many-requests' => 'Terlalu banyak percobaan. Coba lagi nanti.',
      _ => 'Firebase Authentication gagal memproses akun.'
    };
  }
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' =>
        'Akses ditolak. Pastikan akun Anda adalah Owner aktif.',
      'not-found' => 'Profil akun tidak ditemukan.',
      'already-exists' => 'Profil akun sudah ada.',
      'unavailable' ||
      'network-request-failed' ||
      'deadline-exceeded' =>
        'Koneksi ke Firebase gagal. Periksa internet lalu coba lagi.',
      'unauthenticated' => 'Sesi berakhir. Silakan login kembali.',
      _ => 'Firebase gagal memproses data akun.'
    };
  }
  if (error is StateError) return error.message.toString();
  return 'Proses akun gagal. Periksa data dan koneksi lalu coba lagi.';
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final name = TextEditingController(),
      email = TextEditingController(),
      phone = TextEditingController(),
      password = TextEditingController(),
      confirm = TextEditingController();
  bool busy = false;
  Future<void> register() async {
    if ([name, email, phone, password, confirm]
        .any((c) => c.text.trim().isEmpty)) {
      msg('Lengkapi semua kolom.');
      return;
    }
    if (password.text != confirm.text) {
      msg('Konfirmasi kata sandi tidak sama.');
      return;
    }
    if (password.text.length < 6) {
      msg('Kata sandi minimal 6 karakter.');
      return;
    }
    setState(() => busy = true);
    try {
      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.text.trim())) {
        msg('Format email tidak valid.');
        return;
      }
      final cred = await auth.createUserWithEmailAndPassword(
          email: email.text.trim(), password: password.text);
      final user = cred.user;
      if (user == null) throw StateError('Akun Firebase tidak ditemukan.');
      try {
        await db.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name.text.trim(),
          'email': email.text.trim(),
          'phone': phone.text.trim(),
          'role': 'Pelanggan',
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {
        try {
          await user.delete();
        } catch (_) {
          await auth.signOut();
        }
        rethrow;
      }
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      msg(authMessage(e));
    } on FirebaseException catch (e) {
      msg(e.code == 'permission-denied'
          ? 'Registrasi ditolak oleh aturan Firebase. Hubungi Owner.'
          : 'Profil gagal disimpan. Periksa koneksi lalu coba lagi.');
    } catch (_) {
      msg('Registrasi gagal. Periksa data dan koneksi lalu coba lagi.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    phone.dispose();
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  void msg(String s) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  Widget field(TextEditingController c, String label,
          {bool obscure = false, TextInputType? type}) =>
      spacedFormField(TextField(
          controller: c,
          obscureText: obscure,
          keyboardType: type,
          decoration: InputDecoration(filled: true, labelText: label)));
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Registrasi Pelanggan')),
      body: ListView(padding: const EdgeInsets.all(22), children: [
        const Text('Buat akun pelanggan',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        field(name, 'Nama lengkap'),
        field(email, 'Email', type: TextInputType.emailAddress),
        field(phone, 'Nomor telepon', type: TextInputType.phone),
        field(password, 'Kata sandi', obscure: true),
        field(confirm, 'Konfirmasi kata sandi', obscure: true),
        FilledButton(
            onPressed: busy ? null : register,
            style: FilledButton.styleFrom(
                backgroundColor: blue, padding: const EdgeInsets.all(16)),
            child:
                busy ? const CircularProgressIndicator() : const Text('Daftar'))
      ]));
}
