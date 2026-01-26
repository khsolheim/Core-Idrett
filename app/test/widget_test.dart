import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:core_idrett/main.dart';

void main() {
  testWidgets('App loads login screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: CoreIdrettApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Core - Idrett'), findsOneWidget);
    expect(find.text('Logg inn'), findsOneWidget);
  });
}
