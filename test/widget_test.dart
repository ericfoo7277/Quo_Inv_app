import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quo_inv_app/app.dart';

void main() {
  testWidgets('App boots without errors', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: QuoInvApp()));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  });
}
