part of '../../main.dart';

class _CustomerSearchDialog extends StatefulWidget {
  const _CustomerSearchDialog();

  @override
  State<_CustomerSearchDialog> createState() => _CustomerSearchDialogState();
}

class _CustomerSearchDialogState extends State<_CustomerSearchDialog> {
  static const _pageSize = 100;
  static const _resultsPerPage = 50;

  final _searchController = TextEditingController();
  Timer? _debounce;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _customers = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _matches = [];
  DocumentSnapshot<Map<String, dynamic>>? _lastDocument;
  String _keyword = '';
  bool _hasMore = true;
  bool _loading = true;
  String? _error;
  QueryDocumentSnapshot<Map<String, dynamic>>? _selectedCustomer;
  int _resultLimit = _resultsPerPage;
  int _searchVersion = 0;

  @override
  void initState() {
    super.initState();
    _loadMatches(_keyword, _searchVersion);
  }

  void _onSearchChanged(String value) {
    final keyword = value.trim().toLowerCase();
    _debounce?.cancel();
    final version = ++_searchVersion;
    setState(() {
      _keyword = keyword;
      _resultLimit = _resultsPerPage;
      _matches = _filterCustomers(keyword);
      _error = null;
      _loading = keyword.isNotEmpty || _customers.isEmpty && _hasMore;
    });
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _loadMatches(keyword, version);
    });
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterCustomers(
          String keyword) =>
      _customers
          .where((doc) =>
              keyword.isEmpty || customerMatchesSearch(doc.data(), keyword))
          .toList();

  Future<QuerySnapshot<Map<String, dynamic>>> _fetchPage() {
    Query<Map<String, dynamic>> query = db
        .collection('users')
        .where('role', isEqualTo: 'Pelanggan')
        .orderBy(FieldPath.documentId)
        .limit(_pageSize);
    if (_lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }
    return query.get();
  }

  Future<void> _loadMatches(String keyword, int version) async {
    try {
      while (mounted &&
          version == _searchVersion &&
          _hasMore &&
          _matches.length < _resultLimit) {
        final page = await _fetchPage();
        if (!mounted || version != _searchVersion) return;

        _lastDocument = page.docs.isEmpty ? _lastDocument : page.docs.last;
        _hasMore = page.docs.length == _pageSize;
        _customers.addAll(page.docs.where((doc) {
          final data = doc.data();
          return isCustomerProfile(data) && data['isActive'] != false;
        }));
        _matches = _filterCustomers(keyword);
        if (page.docs.isEmpty) _hasMore = false;
        setState(() {});
      }
      if (mounted && version == _searchVersion) {
        setState(() => _loading = false);
      }
    } catch (error) {
      if (!mounted || version != _searchVersion) return;
      setState(() {
        _loading = false;
        _error = _searchErrorMessage(error);
      });
    }
  }

  String _searchErrorMessage(Object error) {
    if (error is FirebaseException && error.code == 'permission-denied') {
      return 'Akses daftar pelanggan ditolak. Pastikan akun Petugas aktif dan aturan Firestore mengizinkan Petugas membaca profil.';
    }
    if (error is FirebaseException && error.code == 'unavailable') {
      return 'Firestore tidak dapat dijangkau. Periksa koneksi internet lalu coba lagi.';
    }
    return 'Daftar pelanggan gagal dimuat. ${error is FirebaseException ? 'Kode: ${error.code}.' : 'Periksa koneksi dan konfigurasi Firestore.'}';
  }

  void _retrySearch() {
    final version = ++_searchVersion;
    setState(() {
      _loading = true;
      _error = null;
    });
    _loadMatches(_keyword, version);
  }

  void _loadMore() {
    final version = ++_searchVersion;
    setState(() {
      _resultLimit += _resultsPerPage;
      _loading = _hasMore && _matches.length < _resultLimit;
    });
    _loadMatches(_keyword, version);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _matches.take(_resultLimit).toList();
    final canLoadMore = _matches.length > visible.length || _hasMore;
    final selectedData = _selectedCustomer?.data();
    return Dialog.fullscreen(
        child: Scaffold(
            backgroundColor: canvas,
            appBar: AppBar(
                leading: IconButton(
                    tooltip: 'Kembali',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back)),
                title: const Text('Pilih Pelanggan')),
            body: Column(children: [
              Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
                  child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      onChanged: _onSearchChanged,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                          hintText: 'Cari nama, nomor HP, atau email',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _keyword.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Hapus pencarian',
                                  onPressed: () {
                                    _searchController.clear();
                                    _onSearchChanged('');
                                  },
                                  icon: const Icon(Icons.close))))),
              if (_loading) const LinearProgressIndicator(minHeight: 2),
              Expanded(
                  child: _error != null
                      ? Center(
                          child: Padding(
                              padding: const EdgeInsets.all(28),
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.warning_amber_rounded,
                                        color: Color(0xFFB42318), size: 44),
                                    const SizedBox(height: 12),
                                    const Text('Pelanggan gagal dimuat',
                                        style: TextStyle(
                                            color: ink,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 20)),
                                    const SizedBox(height: 8),
                                    Text(_error!,
                                        textAlign: TextAlign.center,
                                        style:
                                            const TextStyle(color: mutedInk)),
                                    const SizedBox(height: 16),
                                    FilledButton.icon(
                                        onPressed: _retrySearch,
                                        icon: const Icon(Icons.refresh),
                                        label: const Text('Coba Lagi'))
                                  ])))
                      : visible.isEmpty && _loading
                          ? const Center(
                              child: CircularProgressIndicator(color: blue))
                          : visible.isEmpty
                              ? Center(
                                  child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                                Icons.person_search_outlined,
                                                size: 52,
                                                color: blue),
                                            const SizedBox(height: 12),
                                            Text(
                                                _keyword.isEmpty
                                                    ? 'Belum ada pelanggan'
                                                    : 'Pelanggan tidak ditemukan',
                                                style: const TextStyle(
                                                    color: ink,
                                                    fontSize: 19,
                                                    fontWeight:
                                                        FontWeight.w800)),
                                            const SizedBox(height: 8),
                                            Text(
                                                _keyword.isEmpty
                                                    ? 'Belum ada akun pelanggan aktif.'
                                                    : 'Tidak ada hasil untuk “$_keyword”. Periksa ejaan atau coba kata kunci lain.',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                    color: mutedInk)),
                                            if (_keyword.isNotEmpty)
                                              Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 12),
                                                  child: OutlinedButton(
                                                      onPressed: () {
                                                        _searchController
                                                            .clear();
                                                        _onSearchChanged('');
                                                      },
                                                      child: const Text(
                                                          'Hapus Pencarian')))
                                          ])))
                              : ListView(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 14, 16, 20),
                                  children: [
                                      Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 10),
                                          child: Text(
                                              '${_matches.length} hasil pelanggan',
                                              style: const TextStyle(
                                                  color: mutedInk,
                                                  fontWeight:
                                                      FontWeight.w600))),
                                      ...visible.map((customer) {
                                        final data = customer.data();
                                        final phone =
                                            '${data['phone'] ?? ''}'.trim();
                                        final email =
                                            '${data['email'] ?? ''}'.trim();
                                        final selected = customer.id ==
                                            _selectedCustomer?.id;
                                        final initials =
                                            '${data['name'] ?? 'P'}'
                                                .trim()
                                                .split(RegExp(r'\s+'))
                                                .take(2)
                                                .map((part) => part[0])
                                                .join()
                                                .toUpperCase();
                                        return Card(
                                            margin: const EdgeInsets.only(
                                                bottom: 8),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                side: BorderSide(
                                                    color: selected
                                                        ? blue
                                                        : outline,
                                                    width: selected ? 2 : 1)),
                                            child: ListTile(
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 5),
                                                leading: CircleAvatar(
                                                    radius: 25,
                                                    backgroundColor: selected
                                                        ? blue
                                                        : paleBlue,
                                                    child: Text(initials,
                                                        style: TextStyle(
                                                            color: selected
                                                                ? Colors.white
                                                                : blue,
                                                            fontWeight: FontWeight
                                                                .w800))),
                                                title: Text('${data['name'] ?? 'Pelanggan'}',
                                                    style: TextStyle(fontWeight: FontWeight.w700, color: selected ? blue : ink)),
                                                subtitle: Text([if (phone.isNotEmpty) phone, if (email.isNotEmpty) email].join(' · '), maxLines: 2, style: const TextStyle(color: mutedInk)),
                                                trailing: Icon(selected ? Icons.check_circle : Icons.radio_button_unchecked, color: selected ? blue : mutedInk),
                                                onTap: () => setState(() => _selectedCustomer = customer)));
                                      }),
                                      if (canLoadMore && !_loading)
                                        Center(
                                            child: TextButton.icon(
                                                onPressed: _loadMore,
                                                icon: const Icon(
                                                    Icons.expand_more),
                                                label: Text(_matches.length >
                                                        visible.length
                                                    ? 'Tampilkan hasil berikutnya'
                                                    : 'Muat pelanggan lainnya')))
                                    ]))
            ]),
            bottomNavigationBar: Container(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: outline))),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  if (selectedData != null) ...[
                    Row(children: [
                      CircleAvatar(
                          backgroundColor: paleBlue,
                          child: Text(
                              '${selectedData['name'] ?? 'P'}'
                                  .trim()
                                  .split(RegExp(r'\s+'))
                                  .take(2)
                                  .map((part) => part[0])
                                  .join()
                                  .toUpperCase(),
                              style: const TextStyle(
                                  color: blue, fontWeight: FontWeight.w800))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            const Text('Dipilih',
                                style: TextStyle(color: mutedInk)),
                            Text('${selectedData['name'] ?? 'Pelanggan'}',
                                style: const TextStyle(
                                    color: ink, fontWeight: FontWeight.w700))
                          ])),
                      TextButton(
                          onPressed: () =>
                              setState(() => _selectedCustomer = null),
                          child: const Text('Hapus pilihan'))
                    ]),
                    const SizedBox(height: 10)
                  ],
                  SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                          onPressed: _selectedCustomer == null
                              ? null
                              : () => Navigator.pop(context, _selectedCustomer),
                          icon: const Icon(Icons.check),
                          label: const Text('Pilih Pelanggan')))
                ]))));
  }
}
