part of '../../main.dart';

class HomePage extends StatefulWidget {
  final String uid, name, email, phone, role;
  const HomePage(
      {super.key,
      required this.uid,
      required this.name,
      required this.email,
      required this.phone,
      required this.role});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int tab = 0;
  bool managementServices = false;
  String accountFilter = 'Pelanggan';
  String accountSearch = '';
  final accountSearchController = TextEditingController();
  String orderSearch = '';
  final orderSearchController = TextEditingController();
  String reportPeriod = 'Bulan ini';
  DateTime? rangeStart, rangeEnd;
  String? _savedOrderFilter = 'Antrean';
  bool get isCustomer => widget.role == 'Pelanggan';
  bool get isOwner => widget.role == 'Owner';
  bool get canOperate => isOwner || widget.role == 'Petugas';
  List<String> get tabs => isOwner
      ? ['Dashboard', 'Pesanan', 'Laporan', 'Kelola', 'Profil']
      : widget.role == 'Petugas'
          ? ['Dashboard', 'Pesanan', 'Pembayaran', 'Nota', 'Profil']
          : ['Beranda', 'Pesanan', 'Riwayat', 'Profil'];
  IconData icon(String s) => switch (s) {
        'Dashboard' || 'Beranda' => Icons.home_outlined,
        'Pesanan' => Icons.inventory_2_outlined,
        'Layanan' => Icons.local_laundry_service_outlined,
        'Kelola Akun' || 'Kelola' => Icons.manage_accounts_outlined,
        'Pengguna' || 'Pelanggan' => Icons.people_alt_outlined,
        'Laporan' || 'Laporan Keuangan' => Icons.analytics_outlined,
        'Pembayaran' => Icons.payments_outlined,
        'Keuangan' => Icons.account_balance_wallet_outlined,
        'Nota' => Icons.receipt_long_outlined,
        'Riwayat' => Icons.history_outlined,
        'Profil' => Icons.person_outlined,
        _ => Icons.circle
      };
  Query<Map<String, dynamic>> get ordersQuery => isCustomer
      ? db.collection('orders').where('customerId', isEqualTo: widget.uid)
      : db.collection('orders');
  Stream<QuerySnapshot<Map<String, dynamic>>> get ordersStream =>
      ordersQuery.snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> get usersStream =>
      db.collection('users').where('role', isEqualTo: 'Pelanggan').snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> get servicesStream =>
      db.collection('services').orderBy('name').snapshots();
  void changeTab(int value) => setState(() => tab = value);
  void changeOrderFilter(String value) =>
      setState(() => _savedOrderFilter = value);
  void notice(String s) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  Widget _pageHeader(String title) => Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: outline))),
      child: Row(children: [
        Image.asset('assets/logo_laundry.png',
            width: 34, height: 34, fit: BoxFit.contain),
        const SizedBox(width: 12),
        Expanded(
            child: Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: ink, fontSize: 20, fontWeight: FontWeight.w800)))
      ]));

  @override
  void dispose() {
    accountSearchController.dispose();
    orderSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = isOwner
        ? [
            dashboard(),
            ordersPage(),
            reportsPage(),
            managementPage(),
            profilePage()
          ]
        : widget.role == 'Petugas'
            ? [
                dashboard(),
                ordersPage(),
                paymentsPage(),
                receiptsPage(),
                profilePage()
              ]
            : [customerHome(), ordersPage(), historyPage(), profilePage()];
    final i = tab.clamp(0, pages.length - 1);
    final useNavigationRail = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
        body: Column(children: [
          _pageHeader(tabs[i]),
          Expanded(
              child: useNavigationRail
                  ? Row(children: [
                      NavigationRail(
                          selectedIndex: i,
                          labelType: NavigationRailLabelType.all,
                          groupAlignment: -1,
                          onDestinationSelected: (value) =>
                              setState(() => tab = value),
                          destinations: tabs
                              .map((label) => NavigationRailDestination(
                                  icon: Icon(icon(label)),
                                  label: Text(label)))
                              .toList()),
                      const VerticalDivider(width: 1, thickness: 1),
                      Expanded(child: pages[i])
                    ])
                  : pages[i])
        ]),
        floatingActionButton: tabs[i] == 'Pesanan' && canOperate
            ? FloatingActionButton.extended(
                backgroundColor: blue,
                foregroundColor: Colors.white,
                onPressed: () => orderDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Buat Pesanan'))
            : null,
        bottomNavigationBar: useNavigationRail
            ? null
            : NavigationBar(
                labelBehavior:
                    NavigationDestinationLabelBehavior.alwaysShow,
                selectedIndex: i,
                onDestinationSelected: (v) => setState(() {
                      tab = v;
                    }),
                destinations: tabs
                    .map((t) =>
                        NavigationDestination(icon: Icon(icon(t)), label: t))
                    .toList()));
  }
}
