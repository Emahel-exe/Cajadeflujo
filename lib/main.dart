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
      appBar: AppBar(
        title: const Text('Cash Flow Anual'),
        actions: [
          SizedBox(
            width: 150,
            child: DropdownButtonFormField<int>(
              value: selectedMonthIndex,
              decoration: const InputDecoration(
                labelText: 'Mes actual',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
              ),
              items: List.generate(months.length, (index) {
                return DropdownMenuItem(
                  value: index,
                  child: Text(months[index]),
                );
              }),
              onChanged: (value) {
                if (value == null) return;
                setState(() => selectedMonthIndex = value);
              },
            ),
          ),
          IconButton(
            tooltip: 'Eliminar todos los datos',
            onPressed: _clearAllData,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SummaryPanel(
              yearlyIncome: monthlyIncome.fold(0, (sum, value) => sum + value),
              yearlyExpenses:
                  monthlyFixed.fold(0, (sum, value) => sum + value) +
                  monthlyVariable.fold(0, (sum, value) => sum + value),
              bestMonth: _monthPeak(monthlyBalance, true),
              worstMonth: _monthPeak(monthlyBalance, false),
            ),
            const SizedBox(height: 16),
            _CashFlowTable(
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
                setState(() => rows[rowIndex].values[monthIndex] = value);
              },
              onControlValueChanged: (rowIndex, value) {
                setState(() => rows[rowIndex].controlValue = value);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _clearAllData() {
    setState(() {
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

  String _monthPeak(List<int> balances, bool best) {
    final target = balances.reduce(
      best ? (a, b) => a > b ? a : b : (a, b) => a < b ? a : b,
    );
    final index = balances.indexOf(target);
    return '${months[index]} ${_formatMoney(target)}';
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

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({
    required this.yearlyIncome,
    required this.yearlyExpenses,
    required this.bestMonth,
    required this.worstMonth,
  });

  final int yearlyIncome;
  final int yearlyExpenses;
  final String bestMonth;
  final String worstMonth;

  @override
  Widget build(BuildContext context) {
    final balance = yearlyIncome - yearlyExpenses;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _SummaryCard(
          title: 'Ingresos anuales',
          value: _formatMoney(yearlyIncome),
          icon: Icons.trending_up,
          color: const Color(0xFF36D399),
        ),
        _SummaryCard(
          title: 'Gastos anuales',
          value: _formatMoney(yearlyExpenses),
          icon: Icons.receipt_long,
          color: const Color(0xFFF87171),
        ),
        _SummaryCard(
          title: 'Saldo proyectado',
          value: _formatMoney(balance),
          icon: Icons.account_balance_wallet_outlined,
          color: balance >= 0
              ? const Color(0xFF60A5FA)
              : const Color(0xFFF87171),
        ),
        _SummaryCard(
          title: 'Mejor / peor mes',
          value: '$bestMonth / $worstMonth',
          icon: Icons.calendar_month_outlined,
          color: const Color(0xFFC084FC),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: color,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderRow(months: widget.months),
                const _SectionTitle(
                  title: 'Ingresos',
                  color: Color(0xFF064E3B),
                ),
                ..._rowsFor(CashFlowGroup.income),
                _TotalRow(
                  label: 'Total ingresos',
                  values: widget.monthlyIncome,
                  controlValue: _controlTotal(CashFlowGroup.income),
                  color: const Color(0xFF12392F),
                ),
                const _SectionTitle(
                  title: 'Gastos fijos',
                  color: Color(0xFF7F1D1D),
                ),
                ..._rowsFor(CashFlowGroup.fixedExpense),
                _TotalRow(
                  label: 'Total gastos fijos',
                  values: widget.monthlyFixed,
                  controlValue: _controlTotal(CashFlowGroup.fixedExpense),
                  color: const Color(0xFF3B1D22),
                ),
                const _SectionTitle(
                  title: 'Gastos variables',
                  color: Color(0xFF713F12),
                ),
                ..._rowsFor(CashFlowGroup.variableExpense),
                _TotalRow(
                  label: 'Total gastos variables',
                  values: widget.monthlyVariable,
                  controlValue: _controlTotal(CashFlowGroup.variableExpense),
                  color: const Color(0xFF3F2F14),
                ),
                _TotalRow(
                  label: 'Flujo neto del mes',
                  values: widget.monthlyBalance,
                  controlValue:
                      _controlTotal(CashFlowGroup.income) -
                      _controlTotal(CashFlowGroup.fixedExpense) -
                      _controlTotal(CashFlowGroup.variableExpense),
                  color: const Color(0xFF1E3A5F),
                  highlightBalance: true,
                ),
                _TotalRow(
                  label: 'Flujo neto acumulado',
                  values: widget.accumulatedBalance,
                  color: const Color(0xFF312E81),
                  highlightBalance: true,
                ),
              ],
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
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.months});

  final List<String> months;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _TableCell(
          width: _CashFlowPageState.categoryColumnWidth,
          color: Color(0xFF1F2937),
          child: Text(
            'Categoria',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        ...months.map(
          (month) => _TableCell(
            width: _CashFlowPageState.monthColumnWidth,
            color: const Color(0xFF1F2937),
            child: Text(
              month,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const _TableCell(
          width: _CashFlowPageState.monthColumnWidth,
          color: Color(0xFF1F2937),
          child: Text(
            'Mes control',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        const _TableCell(
          width: _CashFlowPageState.monthColumnWidth,
          color: Color(0xFF1F2937),
          child: Text(
            'Total',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w800),
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
      height: 42,
      width: double.infinity,
      color: color,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
    );
  }
}

class _EditableTableRow extends StatelessWidget {
  const _EditableTableRow({
    required this.rowIndex,
    required this.row,
    required this.selectedMonthIndex,
    required this.inputResetVersion,
    required this.onValueChanged,
    required this.onControlValueChanged,
  });

  final int rowIndex;
  final CashFlowRow row;
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
          child: Text(
            row.label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        ...List.generate(row.values.length, (monthIndex) {
          final isSelectedMonth = monthIndex == selectedMonthIndex;

          return _TableCell(
            width: _CashFlowPageState.monthColumnWidth,
            color: isSelectedMonth ? const Color(0xFF172554) : null,
            child: TextFormField(
              key: ValueKey('$inputResetVersion-$rowIndex-$monthIndex'),
              initialValue: row.values[monthIndex].toString(),
              textAlign: TextAlign.right,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 8,
                ),
              ),
              style: TextStyle(
                color: isSelectedMonth
                    ? const Color(0xFFBFDBFE)
                    : const Color(0xFFE5E7EB),
                fontSize: 12,
                fontWeight: isSelectedMonth ? FontWeight.w800 : FontWeight.w400,
              ),
              cursorColor: const Color(0xFF36D399),
              onChanged: (value) {
                final parsed = _parseMoney(value);
                onValueChanged(rowIndex, monthIndex, parsed);
              },
            ),
          );
        }),
        _TableCell(
          width: _CashFlowPageState.monthColumnWidth,
          color: const Color(0xFF0F766E),
          child: TextFormField(
            key: ValueKey('$inputResetVersion-$rowIndex-control'),
            initialValue: row.controlValue.toString(),
            textAlign: TextAlign.right,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            ),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            cursorColor: const Color(0xFF36D399),
            onChanged: (value) {
              onControlValueChanged(rowIndex, _parseMoney(value));
            },
          ),
        ),
        _TableCell(
          width: _CashFlowPageState.monthColumnWidth,
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
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
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
  });

  final String label;
  final List<int> values;
  final Color color;
  final int? controlValue;
  final bool highlightBalance;

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
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          ...values.map((value) {
            final textColor = highlightBalance && value < 0
                ? const Color(0xFFF87171)
                : const Color(0xFFE5E7EB);
            return _TableCell(
              width: _CashFlowPageState.monthColumnWidth,
              color: color,
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
                    ? const Color(0xFFF87171)
                    : const Color(0xFFE5E7EB),
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
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
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
      height: 44,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE0E5E2), width: 0.7),
        color: color ?? const Color(0xFF111827),
      ),
      child: child,
    );
  }
}

int _parseMoney(String value) {
  return int.tryParse(value.replaceAll('.', '').replaceAll(',', '')) ?? 0;
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
