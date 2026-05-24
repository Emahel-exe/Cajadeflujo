import 'package:flutter/material.dart';

void main() {
  runApp(const CashFlowApp());
}

class CashFlowApp extends StatelessWidget {
  const CashFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cash Flow Anual',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF36D399),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0B1020),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF111827),
          foregroundColor: Color(0xFFE5E7EB),
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF111827),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          hintStyle: TextStyle(color: Color(0xFF94A3B8)),
        ),
        useMaterial3: true,
      ),
      home: const CashFlowPage(),
    );
  }
}

class CashFlowPage extends StatefulWidget {
  const CashFlowPage({super.key});

  @override
  State<CashFlowPage> createState() => _CashFlowPageState();
}

class _CashFlowPageState extends State<CashFlowPage> {
  static const double categoryColumnWidth = 210;
  static const double monthColumnWidth = 90;
  int selectedMonthIndex = 4;
  int inputResetVersion = 0;
  int cashValue = 0;
  int bankValue = 0;
  int objectiveValue = 0;

  final List<String> months = const [
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic',
  ];

  final List<CashFlowRow> rows = [
    CashFlowRow(
      label: 'Sueldo',
      group: CashFlowGroup.income,
      values: [
        1850000,
        1850000,
        1850000,
        1850000,
        1900000,
        1900000,
        1900000,
        1900000,
        1950000,
        1950000,
        1950000,
        1950000,
      ],
    ),
    CashFlowRow(
      label: 'Freelance / otros',
      group: CashFlowGroup.income,
      values: [
        250000,
        180000,
        300000,
        220000,
        250000,
        280000,
        260000,
        300000,
        320000,
        280000,
        300000,
        350000,
      ],
    ),
    CashFlowRow(
      label: 'Arriendo / dividendo',
      group: CashFlowGroup.fixedExpense,
      values: List.filled(12, 620000),
    ),
    CashFlowRow(
      label: 'Servicios basicos',
      group: CashFlowGroup.fixedExpense,
      values: List.filled(12, 95000),
    ),
    CashFlowRow(
      label: 'Internet y telefono',
      group: CashFlowGroup.fixedExpense,
      values: List.filled(12, 54000),
    ),
    CashFlowRow(
      label: 'Seguros / suscripciones',
      group: CashFlowGroup.fixedExpense,
      values: List.filled(12, 78000),
    ),
    CashFlowRow(
      label: 'Transporte',
      group: CashFlowGroup.variableExpense,
      values: [
        120000,
        115000,
        130000,
        125000,
        110000,
        120000,
        135000,
        140000,
        125000,
        120000,
        130000,
        150000,
      ],
    ),
    CashFlowRow(
      label: 'Comida',
      group: CashFlowGroup.variableExpense,
      values: [
        360000,
        340000,
        380000,
        370000,
        365000,
        390000,
        410000,
        400000,
        380000,
        390000,
        420000,
        460000,
      ],
    ),
    CashFlowRow(
      label: 'Salud',
      group: CashFlowGroup.variableExpense,
      values: [
        40000,
        55000,
        35000,
        80000,
        45000,
        50000,
        65000,
        45000,
        55000,
        70000,
        50000,
        60000,
      ],
    ),
    CashFlowRow(
      label: 'Ocio / regalos',
      group: CashFlowGroup.variableExpense,
      values: [
        90000,
        120000,
        110000,
        95000,
        100000,
        130000,
        150000,
        135000,
        120000,
        125000,
        160000,
        220000,
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final monthlyIncome = _monthlyTotals(CashFlowGroup.income);
    final monthlyFixed = _monthlyTotals(CashFlowGroup.fixedExpense);
    final monthlyVariable = _monthlyTotals(CashFlowGroup.variableExpense);
    final monthlyBalance = List.generate(
      months.length,
      (index) =>
          monthlyIncome[index] - monthlyFixed[index] - monthlyVariable[index],
    );
    final accumulatedBalance = _accumulatedTotals(monthlyBalance);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ParametersPanel(
                cashValue: cashValue,
                bankValue: bankValue,
                objectiveValue: objectiveValue,
                inputResetVersion: inputResetVersion,
                onCashChanged: (value) => setState(() => cashValue = value),
                onBankChanged: (value) => setState(() => bankValue = value),
                onObjectiveChanged: (value) =>
                    setState(() => objectiveValue = value),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    _DashboardHeader(
                      yearlyIncome: monthlyIncome.fold(
                        0,
                        (sum, value) => sum + value,
                      ),
                      yearlyExpenses:
                          monthlyFixed.fold(0, (sum, value) => sum + value) +
                          monthlyVariable.fold(0, (sum, value) => sum + value),
                      projection: accumulatedBalance.last,
                      months: months,
                      selectedMonthIndex: selectedMonthIndex,
                      onMonthChanged: (value) {
                        if (value == null) return;
                        setState(() => selectedMonthIndex = value);
                      },
                      onClear: _clearAllData,
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: _CashFlowTable(
                        months: months,
                        rows: rows,
                        monthlyIncome: monthlyIncome,
                        monthlyFixed: monthlyFixed,
                        monthlyVariable: monthlyVariable,
                        monthlyBalance: monthlyBalance,
                        accumulatedBalance: accumulatedBalance,
                        selectedMonthIndex: selectedMonthIndex,
                        inputResetVersion: inputResetVersion,
                        onValueChanged: (rowIndex, monthIndex, value) {
                          setState(
                            () => rows[rowIndex].values[monthIndex] = value,
                          );
                        },
                        onControlValueChanged: (rowIndex, value) {
                          setState(() => rows[rowIndex].controlValue = value);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _clearAllData() {
    setState(() {
      cashValue = 0;
      bankValue = 0;
      objectiveValue = 0;
      for (final row in rows) {
        for (var i = 0; i < row.values.length; i++) {
          row.values[i] = 0;
        }
        row.controlValue = 0;
      }
      inputResetVersion++;
    });
  }

  List<int> _monthlyTotals(CashFlowGroup group) {
    return List.generate(months.length, (monthIndex) {
      return rows
          .where((row) => row.group == group)
          .fold(0, (sum, row) => sum + _effectiveValue(row, monthIndex));
    });
  }

  int _effectiveValue(CashFlowRow row, int monthIndex) {
    final projectedValue = row.values[monthIndex];
    if (monthIndex != selectedMonthIndex) return projectedValue;
    return projectedValue - row.controlValue;
  }

  List<int> _accumulatedTotals(List<int> values) {
    var runningTotal = 0;
    return values.map((value) {
      runningTotal += value;
      return runningTotal;
    }).toList();
  }
}

enum CashFlowGroup { income, fixedExpense, variableExpense }

class CashFlowRow {
  CashFlowRow({
    required this.label,
    required this.group,
    required this.values,
    this.controlValue = 0,
  });

  final String label;
  final CashFlowGroup group;
  final List<int> values;
  int controlValue;
}

class _ParametersPanel extends StatelessWidget {
  const _ParametersPanel({
    required this.cashValue,
    required this.bankValue,
    required this.objectiveValue,
    required this.inputResetVersion,
    required this.onCashChanged,
    required this.onBankChanged,
    required this.onObjectiveChanged,
  });

  final int cashValue;
  final int bankValue;
  final int objectiveValue;
  final int inputResetVersion;
  final ValueChanged<int> onCashChanged;
  final ValueChanged<int> onBankChanged;
  final ValueChanged<int> onObjectiveChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          border: Border.all(color: const Color(0xFF334155), width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Parametros',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFE5E7EB),
                ),
              ),
              const SizedBox(height: 28),
              _ParameterInput(
                label: 'Efectivo',
                value: cashValue,
                resetVersion: inputResetVersion,
                onChanged: onCashChanged,
              ),
              const SizedBox(height: 24),
              _ParameterInput(
                label: 'Banco',
                value: bankValue,
                resetVersion: inputResetVersion,
                onChanged: onBankChanged,
              ),
              const SizedBox(height: 24),
              _ReadOnlyMetric(label: 'Total', value: cashValue + bankValue),
              const SizedBox(height: 24),
              _ParameterInput(
                label: 'Objetivo',
                value: objectiveValue,
                resetVersion: inputResetVersion,
                onChanged: onObjectiveChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParameterInput extends StatelessWidget {
  const _ParameterInput({
    required this.label,
    required this.value,
    required this.resetVersion,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int resetVersion;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        _MiniInput(
          key: ValueKey('$resetVersion-$label'),
          initialValue: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ReadOnlyMetric extends StatelessWidget {
  const _ReadOnlyMetric({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Container(
          height: 38,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1020),
            border: Border.all(color: const Color(0xFF475569), width: 1.5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            _formatMoney(value),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _MiniInput extends StatelessWidget {
  const _MiniInput({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  final int initialValue;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: TextFormField(
        initialValue: initialValue == 0 ? '' : initialValue.toString(),
        textAlign: TextAlign.right,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFF0B1020),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFF475569), width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFF475569), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFF36D399), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          hintText: '0',
          hintStyle: const TextStyle(
            color: Color(0x6694A3B8),
            fontSize: 12,
          ),
        ),
        style: const TextStyle(fontSize: 12),
        cursorColor: const Color(0xFF36D399),
        onChanged: (value) => onChanged(_parseMoney(value)),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.yearlyIncome,
    required this.yearlyExpenses,
    required this.projection,
    required this.months,
    required this.selectedMonthIndex,
    required this.onMonthChanged,
    required this.onClear,
  });

  final int yearlyIncome;
  final int yearlyExpenses;
  final int projection;
  final List<String> months;
  final int selectedMonthIndex;
  final ValueChanged<int?> onMonthChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 94,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _HeaderMetric(
              title: 'Ingresos total',
              value: _formatMoney(yearlyIncome),
              color: const Color(0xFF36D399),
            ),
            const SizedBox(width: 14),
            _HeaderMetric(
              title: 'Gastos total',
              value: _formatMoney(yearlyExpenses),
              color: const Color(0xFFF87171),
            ),
            const SizedBox(width: 14),
            _HeaderMetric(
              title: 'Proyeccion',
              value: _formatMoney(projection),
              color: projection >= 0
                  ? const Color(0xFF60A5FA)
                  : const Color(0xFFF87171),
            ),
            const SizedBox(width: 64),
            SizedBox(
              width: 170,
              child: DropdownButtonFormField<int>(
                initialValue: selectedMonthIndex,
                decoration: InputDecoration(
                  labelText: 'Mes act.',
                  filled: true,
                  fillColor: const Color(0xFF111827),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                items: List.generate(months.length, (index) {
                  return DropdownMenuItem(
                    value: index,
                    child: Text(months[index]),
                  );
                }),
                onChanged: onMonthChanged,
              ),
            ),
            const SizedBox(width: 18),
            IconButton.filledTonal(
              tooltip: 'Eliminar todos los datos',
              onPressed: onClear,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  const _HeaderMetric({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 78,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          border: Border.all(color: const Color(0xFF334155), width: 2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CashFlowTable extends StatefulWidget {
  const _CashFlowTable({
    required this.months,
    required this.rows,
    required this.monthlyIncome,
    required this.monthlyFixed,
    required this.monthlyVariable,
    required this.monthlyBalance,
    required this.accumulatedBalance,
    required this.selectedMonthIndex,
    required this.inputResetVersion,
    required this.onValueChanged,
    required this.onControlValueChanged,
  });

  final List<String> months;
  final List<CashFlowRow> rows;
  final List<int> monthlyIncome;
  final List<int> monthlyFixed;
  final List<int> monthlyVariable;
  final List<int> monthlyBalance;
  final List<int> accumulatedBalance;
  final int selectedMonthIndex;
  final int inputResetVersion;
  final void Function(int rowIndex, int monthIndex, int value) onValueChanged;
  final void Function(int rowIndex, int value) onControlValueChanged;

  @override
  State<_CashFlowTable> createState() => _CashFlowTableState();
}

class _CashFlowTableState extends State<_CashFlowTable> {
  final ScrollController _horizontalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Scrollbar(
        controller: _horizontalController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _horizontalController,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width:
                _CashFlowPageState.categoryColumnWidth +
                (_CashFlowPageState.monthColumnWidth * 14),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _YearRow(year: '2026'),
                  _HeaderRow(
                    months: widget.months,
                    selectedMonthIndex: widget.selectedMonthIndex,
                  ),
                  const _SectionTitle(
                    title: 'INGRESOS',
                    color: Color(0xFFE2F0D9),
                  ),
                  ..._rowsFor(CashFlowGroup.income),
                  _TotalRow(
                    label: 'TOTAL INGRESO',
                    values: widget.monthlyIncome,
                    controlValue: _controlTotal(CashFlowGroup.income),
                    color: const Color(0xFFDDEBF7),
                    selectedMonthIndex: widget.selectedMonthIndex,
                  ),
                  const _SectionTitle(
                    title: 'GASTOS FIJOS',
                    color: Color(0xFFFFF2CC),
                  ),
                  ..._rowsFor(CashFlowGroup.fixedExpense),
                  _TotalRow(
                    label: 'TOTAL GASTOS FIJOS',
                    values: widget.monthlyFixed,
                    controlValue: _controlTotal(CashFlowGroup.fixedExpense),
                    color: const Color(0xFFDDEBF7),
                    selectedMonthIndex: widget.selectedMonthIndex,
                  ),
                  const _SectionTitle(
                    title: 'GASTOS VARIABLES',
                    color: Color(0xFFFCE4D6),
                  ),
                  ..._rowsFor(CashFlowGroup.variableExpense),
                  _TotalRow(
                    label: 'TOTAL GASTOS VARIABLES',
                    values: widget.monthlyVariable,
                    controlValue: _controlTotal(CashFlowGroup.variableExpense),
                    color: const Color(0xFFDDEBF7),
                    selectedMonthIndex: widget.selectedMonthIndex,
                  ),
                  _TotalRow(
                    label: 'FLUJO MES',
                    values: widget.monthlyBalance,
                    controlValue:
                        _controlTotal(CashFlowGroup.income) -
                        _controlTotal(CashFlowGroup.fixedExpense) -
                        _controlTotal(CashFlowGroup.variableExpense),
                    color: const Color(0xFFDDEBF7),
                    highlightBalance: true,
                    selectedMonthIndex: widget.selectedMonthIndex,
                  ),
                  _TotalRow(
                    label: 'FLUJO ACUMULADO + AHRR',
                    values: widget.accumulatedBalance,
                    color: const Color(0xFFDDEBF7),
                    highlightBalance: true,
                    selectedMonthIndex: widget.selectedMonthIndex,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _rowsFor(CashFlowGroup group) {
    return widget.rows
        .asMap()
        .entries
        .where((entry) => entry.value.group == group)
        .map((entry) {
          return _EditableTableRow(
            rowIndex: entry.key,
            row: entry.value,
            rowColor: _rowColor(group),
            selectedMonthIndex: widget.selectedMonthIndex,
            inputResetVersion: widget.inputResetVersion,
            onValueChanged: widget.onValueChanged,
            onControlValueChanged: widget.onControlValueChanged,
          );
        })
        .toList();
  }

  int _controlTotal(CashFlowGroup group) {
    return widget.rows
        .where((row) => row.group == group)
        .fold(0, (sum, row) => sum + row.controlValue);
  }

  Color _rowColor(CashFlowGroup group) {
    return switch (group) {
      CashFlowGroup.income => const Color(0xFFE2F0D9),
      CashFlowGroup.fixedExpense => const Color(0xFFFFF2CC),
      CashFlowGroup.variableExpense => const Color(0xFFFCE4D6),
    };
  }
}

class _YearRow extends StatelessWidget {
  const _YearRow({required this.year});

  final String year;

  @override
  Widget build(BuildContext context) {
    return Container(
      width:
          _CashFlowPageState.categoryColumnWidth +
          (_CashFlowPageState.monthColumnWidth * 14),
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: Text(
        year,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.months, required this.selectedMonthIndex});

  final List<String> months;
  final int selectedMonthIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _TableCell(
          width: _CashFlowPageState.categoryColumnWidth,
          color: Color(0xFFFFFFFF),
          child: Text('', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
        ...months.asMap().entries.map(
          (entry) => _TableCell(
            width: _CashFlowPageState.monthColumnWidth,
            color: entry.key == selectedMonthIndex
                ? const Color(0xFFFFEB3B)
                : const Color(0xFFFFFFFF),
            child: Text(
              _fullMonthName(entry.value),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: entry.key == selectedMonthIndex
                    ? const Color(0xFF111111)
                    : const Color(0xFF111111),
                fontSize: 11,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const _TableCell(
          width: _CashFlowPageState.monthColumnWidth,
          color: Color(0xFFFFFFFF),
          child: Text(
            'Mes control',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF111111),
              fontSize: 10,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const _TableCell(
          width: _CashFlowPageState.monthColumnWidth,
          color: Color(0xFFFFFFFF),
          child: Text(
            'Total',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF111111),
              fontSize: 11,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.color});

  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      width: double.infinity,
      color: color,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF111111),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EditableTableRow extends StatelessWidget {
  const _EditableTableRow({
    required this.rowIndex,
    required this.row,
    required this.rowColor,
    required this.selectedMonthIndex,
    required this.inputResetVersion,
    required this.onValueChanged,
    required this.onControlValueChanged,
  });

  final int rowIndex;
  final CashFlowRow row;
  final Color rowColor;
  final int selectedMonthIndex;
  final int inputResetVersion;
  final void Function(int rowIndex, int monthIndex, int value) onValueChanged;
  final void Function(int rowIndex, int value) onControlValueChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TableCell(
          width: _CashFlowPageState.categoryColumnWidth,
          color: rowColor,
          child: Text(
            row.label,
            style: const TextStyle(
              color: Color(0xFF111111),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...List.generate(row.values.length, (monthIndex) {
          final isSelectedMonth = monthIndex == selectedMonthIndex;

          return _TableCell(
            width: _CashFlowPageState.monthColumnWidth,
            color: isSelectedMonth ? const Color(0xFFFFEB3B) : rowColor,
            child: TextFormField(
              key: ValueKey('$inputResetVersion-$rowIndex-$monthIndex'),
              initialValue: row.values[monthIndex] == 0
                  ? ''
                  : row.values[monthIndex].toString(),
              textAlign: TextAlign.right,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 8,
                ),
                hintText: '0',
                hintStyle: TextStyle(
                  color: Color(0x66111111),
                  fontSize: 12,
                ),
              ),
              style: TextStyle(
                color: isSelectedMonth
                    ? const Color(0xFF111111)
                    : const Color(0xFF111111),
                fontSize: 12,
                fontWeight: isSelectedMonth ? FontWeight.w800 : FontWeight.w400,
              ),
              cursorColor: const Color(0xFF111111),
              onChanged: (value) {
                final parsed = _parseMoney(value);
                onValueChanged(rowIndex, monthIndex, parsed);
              },
            ),
          );
        }),
        _TableCell(
          width: _CashFlowPageState.monthColumnWidth,
          color: const Color(0xFFD9EAD3),
          child: TextFormField(
            key: ValueKey('$inputResetVersion-$rowIndex-control'),
            initialValue: row.controlValue == 0
                ? ''
                : row.controlValue.toString(),
            textAlign: TextAlign.right,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              hintText: '0',
              hintStyle: TextStyle(
                color: Color(0x66111111),
                fontSize: 12,
              ),
            ),
            style: const TextStyle(
              color: Color(0xFF111111),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            cursorColor: const Color(0xFF111111),
            onChanged: (value) {
              onControlValueChanged(rowIndex, _parseMoney(value));
            },
          ),
        ),
        _TableCell(
          width: _CashFlowPageState.monthColumnWidth,
          color: const Color(0xFFE7E6E6),
          child: Text(
            _formatMoney(
              row.values.asMap().entries.fold(0, (sum, entry) {
                final value = entry.key == selectedMonthIndex
                    ? entry.value - row.controlValue
                    : entry.value;
                return sum + value;
              }),
            ),
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFF111111),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.values,
    required this.color,
    this.controlValue,
    this.highlightBalance = false,
    this.selectedMonthIndex,
  });

  final String label;
  final List<int> values;
  final Color color;
  final int? controlValue;
  final bool highlightBalance;
  final int? selectedMonthIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      child: Row(
        children: [
          _TableCell(
            width: _CashFlowPageState.categoryColumnWidth,
            color: color,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF111111),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          ...values.asMap().entries.map((entry) {
            final value = entry.value;
            final isSelectedMonth = entry.key == selectedMonthIndex;
            final textColor = highlightBalance && value < 0
                ? const Color(0xFFC00000)
                : isSelectedMonth
                ? const Color(0xFF111111)
                : const Color(0xFF111111);
            return _TableCell(
              width: _CashFlowPageState.monthColumnWidth,
              color: isSelectedMonth ? const Color(0xFFFFEB3B) : color,
              child: Text(
                _formatMoney(value),
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: textColor,
                  fontSize: 12,
                ),
              ),
            );
          }),
          _TableCell(
            width: _CashFlowPageState.monthColumnWidth,
            color: color,
            child: Text(
              controlValue == null ? '' : _formatMoney(controlValue!),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: highlightBalance && (controlValue ?? 0) < 0
                    ? const Color(0xFFC00000)
                    : const Color(0xFF111111),
                fontSize: 12,
              ),
            ),
          ),
          _TableCell(
            width: _CashFlowPageState.monthColumnWidth,
            color: color,
            child: Text(
              _formatMoney(values.fold(0, (sum, value) => sum + value)),
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF111111),
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  const _TableCell({required this.width, required this.child, this.color});

  final double width;
  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 24,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 0.7),
        color: color ?? const Color(0xFFFFFFFF),
      ),
      child: child,
    );
  }
}

int _parseMoney(String value) {
  return int.tryParse(value.replaceAll('.', '').replaceAll(',', '')) ?? 0;
}

String _fullMonthName(String shortName) {
  return switch (shortName) {
    'Ene' => 'ENERO',
    'Feb' => 'FEBRERO',
    'Mar' => 'MARZO',
    'Abr' => 'ABRIL',
    'May' => 'MAYO',
    'Jun' => 'JUNIO',
    'Jul' => 'JULIO',
    'Ago' => 'AGOSTO',
    'Sep' => 'SEPTIEMBRE',
    'Oct' => 'OCTUBRE',
    'Nov' => 'NOVIEMBRE',
    'Dic' => 'DICIEMBRE',
    _ => shortName.toUpperCase(),
  };
}

String _formatMoney(int value) {
  final isNegative = value < 0;
  final digits = value.abs().toString();
  final buffer = StringBuffer();

  for (var i = 0; i < digits.length; i++) {
    final positionFromEnd = digits.length - i;
    buffer.write(digits[i]);
    if (positionFromEnd > 1 && positionFromEnd % 3 == 1) {
      buffer.write('.');
    }
  }

  return '${isNegative ? '-' : ''}\$$buffer';
}
