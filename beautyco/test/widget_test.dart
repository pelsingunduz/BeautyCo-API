import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beautyco/main.dart';
import 'package:beautyco/services/api_service.dart';

// Basit bir sahte ApiService (mock)
class FakeApiService extends ApiService {
  @override
  Future<void> fetchSomething() async {
    // Gerçek API çağrısı yerine boş çalışır
    return;
  }
}

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // FakeApiService kullanarak MyApp başlat
    await tester.pumpWidget(MyApp(apiService: FakeApiService()));

    // Bu test örneği varsayılan sayacı test ediyor
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
