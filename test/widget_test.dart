import 'package:flutter_test/flutter_test.dart';

import 'package:hello_world/main.dart';

void main() {
  testWidgets('muestra la tabla de cash flow anual', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CashFlowApp());

    expect(find.text('Parametros'), findsOneWidget);
    expect(find.text('Ingresos total'), findsOneWidget);
    expect(find.text('Mes act.'), findsOneWidget);
    expect(find.text('INGRESOS'), findsOneWidget);
    expect(find.text('GASTOS FIJOS'), findsOneWidget);
    expect(find.text('GASTOS VARIABLES'), findsOneWidget);
    expect(find.text('FLUJO MES'), findsOneWidget);
  });
}
