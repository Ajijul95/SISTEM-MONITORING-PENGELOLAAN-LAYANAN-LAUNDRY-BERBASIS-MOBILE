import 'dart:io';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart' as xlsx;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

part 'features/auth/auth_pages.dart';
part 'features/shared/home_page.dart';
part 'features/shared/dashboard_feature.dart';
part 'features/shared/orders_feature.dart';
part 'features/shared/customer_search_dialog.dart';
part 'features/shared/profile_feature.dart';
part 'features/shared/report_period_feature.dart';
part 'features/customer/customer_home_feature.dart';
part 'features/customer/order_history_feature.dart';
part 'features/owner/finance_feature.dart';
part 'features/owner/services_feature.dart';
part 'features/owner/accounts_feature.dart';
part 'features/owner/reports_feature.dart';
part 'features/staff/payments_feature.dart';
part 'features/staff/receipts_feature.dart';

const blue = Color(0xFF2453D4);
const ink = Color(0xFF14213B);
const mutedInk = Color(0xFF58677F);
const canvas = Color(0xFFF3F5FA);
const outline = Color(0xFFE1E7F1);
const paleBlue = Color(0xFFE7EEFF);
const teal = Color(0xFF0D7474);
const paleTeal = Color(0xFFDDF3F1);
const paleAmber = Color(0xFFFFF1DB);
const statuses = ['Antrean', 'Di Cuci', 'Siap Ambil', 'Selesai'];
String money(num n) =>
    'Rp ${n.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

String weightText(num value) {
  final formatted =
      value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  return '${formatted.replaceAll('.', ',')} kg';
}

String dateNow() {
  final d = DateTime.now();
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

String dateAfter(int days) {
  final d = DateTime.now().add(Duration(days: days));
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

const paymentMethods = ['Cash', 'QRIS'];
const paymentStatuses = ['Belum Dibayar', 'Menunggu Konfirmasi', 'Lunas'];

DateTime? orderDate(Map<String, dynamic> data, {bool payment = false}) {
  final value = payment ? data['paidAt'] : data['createdAt'];
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  final legacy =
      DateTime.tryParse('${data[payment ? 'paidAt' : 'created'] ?? ''}');
  if (legacy != null) return legacy;
  final parts = '${data[payment ? 'paidAt' : 'created'] ?? ''}'.split('/');
  if (parts.length == 3) {
    return DateTime.tryParse('${parts[2]}-${parts[1]}-${parts[0]}');
  }
  return null;
}

String reportDate(DateTime? date) {
  if (date == null) return '-';
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

Widget spacedFormField(Widget child) =>
    Padding(padding: const EdgeInsets.only(bottom: 12), child: child);

Widget statusBadge(String status, {bool compact = false}) {
  final (color, background, icon) = switch (status) {
    'Antrean' => (
        const Color(0xFF965200),
        paleAmber,
        Icons.schedule_outlined
      ),
    'Di Cuci' => (const Color(0xFF1947AF), paleBlue, Icons.water_drop_outlined),
    'Siap Ambil' => (teal, paleTeal, Icons.inventory_2_outlined),
    _ => (const Color(0xFF394A66), const Color(0xFFE6EAF2), Icons.task_alt)
  };
  return DecoratedBox(
      decoration: BoxDecoration(
          color: background, borderRadius: BorderRadius.circular(999)),
      child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: compact ? 11 : 14, vertical: compact ? 7 : 9),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: compact ? 17 : 19, color: color),
            const SizedBox(width: 7),
            Text(status,
                style: TextStyle(
                    color: color,
                    fontSize: compact ? 13 : 14,
                    fontWeight: FontWeight.w700))
          ])));
}

final auth = FirebaseAuth.instance;
final db = FirebaseFirestore.instance;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const HdpApp());
}

class HdpApp extends StatelessWidget {
  const HdpApp({super.key});
  @override
  Widget build(BuildContext context) {
    const surface = Color(0xFFFFFFFF);
    final colors = ColorScheme.fromSeed(seedColor: blue).copyWith(
      primary: blue,
      secondary: teal,
      surface: canvas,
      onSurface: ink,
    );
    return MaterialApp(
      title: 'HDP LAUNDRY',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Roboto',
          colorScheme: colors,
          scaffoldBackgroundColor: canvas,
          appBarTheme: const AppBarTheme(
              backgroundColor: surface,
              foregroundColor: ink,
              elevation: 0,
              scrolledUnderElevation: 0,
              surfaceTintColor: Colors.transparent,
              titleTextStyle: TextStyle(
                  color: ink, fontSize: 20, fontWeight: FontWeight.w700)),
          dialogTheme: DialogThemeData(
              backgroundColor: surface,
              surfaceTintColor: Colors.transparent,
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26))),
          cardTheme: CardThemeData(
              color: surface,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                  side: const BorderSide(color: outline, width: 1.2))),
          inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: canvas,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: outline)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: outline)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: blue, width: 2))),
          filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(18))),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700))),
          outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                  foregroundColor: blue,
                  minimumSize: const Size(48, 48),
                  side: const BorderSide(color: outline, width: 1.4),
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(18))),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700))),
          navigationBarTheme: const NavigationBarThemeData(
              height: 78,
              backgroundColor: surface,
              surfaceTintColor: Colors.transparent,
              indicatorColor: paleBlue,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              labelTextStyle: WidgetStatePropertyAll(
                  TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
          navigationRailTheme: const NavigationRailThemeData(
              backgroundColor: surface, indicatorColor: Color(0xFFE4ECFA))),
      home: const AuthGate(),
    );
  }
}

extension FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
