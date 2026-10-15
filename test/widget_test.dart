import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hdp_laundry/main.dart';

void main() {
  test('Rupiah amounts use Indonesian thousands separators', () {
    expect(money(1234567), 'Rp 1.234.567');
  });

  test('Laundry weight uses a consistent Indonesian decimal format', () {
    expect(weightText(2), '2 kg');
    expect(weightText(1.25), '1,25 kg');
  });

  test('Customer search matches name, phone, and email case-insensitively', () {
    const customer = {
      'name': 'Siti Aminah',
      'phone': '+62 812-3456-7890',
      'email': 'Siti.Aminah@example.com',
    };

    expect(customerMatchesSearch(customer, '  SITI  '), isTrue);
    expect(customerMatchesSearch(customer, '3456'), isTrue);
    expect(customerMatchesSearch(customer, 'EXAMPLE.COM'), isTrue);
    expect(customerMatchesSearch(customer, 'tidak ditemukan'), isFalse);
    expect(customerMatchesSearch(customer, '   '), isFalse);
  });

  test('Customer role matching follows the canonical Firestore role', () {
    expect(isCustomerProfile({'role': 'Pelanggan'}), isTrue);
    expect(isCustomerProfile({'role': ' pelanggan '}), isFalse);
    expect(isCustomerProfile({'role': 'Petugas'}), isFalse);
    expect(isCustomerProfile({}), isFalse);
  });

  testWidgets('HDP Laundry login page opens', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
    expect(find.text('Belum punya akun?'), findsOneWidget);
    expect(find.text('Registrasi Pelanggan'), findsOneWidget);

    await tester.tap(find.text('Registrasi Pelanggan'));
    await tester.pumpAndSettle();

    expect(find.text('Registrasi Pelanggan'), findsOneWidget);
    expect(find.text('Daftar'), findsOneWidget);
  });
}
