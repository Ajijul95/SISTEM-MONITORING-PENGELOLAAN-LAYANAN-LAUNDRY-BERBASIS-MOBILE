part of '../../main.dart';

// ignore_for_file: invalid_use_of_protected_member

extension _SharedReportPeriodFeature on _HomePageState {
  DateTimeRange _periodBounds() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (reportPeriod == 'Hari ini') {
      return DateTimeRange(
          start: today, end: today.add(const Duration(days: 1)));
    }
    if (reportPeriod == 'Minggu ini') {
      final start = today.subtract(Duration(days: today.weekday - 1));
      return DateTimeRange(
          start: start, end: start.add(const Duration(days: 7)));
    }
    if (reportPeriod == 'Tahun ini') {
      final start = DateTime(now.year);
      return DateTimeRange(start: start, end: DateTime(now.year + 1));
    }
    if (reportPeriod == 'Rentang tanggal' &&
        rangeStart != null &&
        rangeEnd != null) {
      final start =
          DateTime(rangeStart!.year, rangeStart!.month, rangeStart!.day);
      final end = DateTime(rangeEnd!.year, rangeEnd!.month, rangeEnd!.day)
          .add(const Duration(days: 1));
      return DateTimeRange(start: start, end: end);
    }
    final start = DateTime(now.year, now.month);
    return DateTimeRange(start: start, end: DateTime(now.year, now.month + 1));
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _inReportPeriod(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final bounds = _periodBounds();
    return docs.where((doc) {
      final data = doc.data();
      final date = orderDate(data, payment: data['paymentStatus'] == 'Lunas') ??
          orderDate(data);
      return date != null &&
          !date.isBefore(bounds.start) &&
          date.isBefore(bounds.end);
    }).toList()
      ..sort((a, b) => (orderDate(b.data(), payment: true) ??
              orderDate(b.data()) ??
              DateTime(0))
          .compareTo(orderDate(a.data(), payment: true) ??
              orderDate(a.data()) ??
              DateTime(0)));
  }

  String get _reportPeriodLabel {
    if (reportPeriod == 'Rentang tanggal' &&
        rangeStart != null &&
        rangeEnd != null) {
      return '${reportDate(rangeStart)} - ${reportDate(rangeEnd)}';
    }
    return reportPeriod;
  }

  String get _reportFilePeriod {
    final bounds = _periodBounds();
    final lastDate = bounds.end.subtract(const Duration(days: 1));
    String pad(int value) => value.toString().padLeft(2, '0');
    final start =
        '${bounds.start.year}-${pad(bounds.start.month)}-${pad(bounds.start.day)}';
    final end = '${lastDate.year}-${pad(lastDate.month)}-${pad(lastDate.day)}';
    return start == end ? start : '${start}_to_$end';
  }

  Widget _periodFilter() => Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 8,
          children: [
            SizedBox(
                width: 190,
                child: DropdownButtonFormField<String>(
                    initialValue: reportPeriod,
                    decoration:
                        const InputDecoration(labelText: 'Periode laporan'),
                    items: const [
                      'Hari ini',
                      'Minggu ini',
                      'Bulan ini',
                      'Tahun ini',
                      'Rentang tanggal'
                    ]
                        .map((value) =>
                            DropdownMenuItem(value: value, child: Text(value)))
                        .toList(),
                    onChanged: (value) async {
                      if (value == null) return;
                      if (value == 'Rentang tanggal') {
                        final selected = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                            initialDateRange:
                                rangeStart != null && rangeEnd != null
                                    ? DateTimeRange(
                                        start: rangeStart!, end: rangeEnd!)
                                    : null);
                        if (selected == null) return;
                        setState(() {
                          rangeStart = selected.start;
                          rangeEnd = selected.end;
                          reportPeriod = value;
                        });
                      } else {
                        setState(() => reportPeriod = value);
                      }
                    })),
            if (reportPeriod == 'Rentang tanggal')
              Text(_reportPeriodLabel,
                  style: const TextStyle(color: Colors.black54))
          ]);
}
