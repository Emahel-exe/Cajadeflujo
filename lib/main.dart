import 'package:flutter/material.dart';
import 'dart:math';
import 'database_helper.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

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
  bool isLoading = true;

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

  List<CashFlowRow> rows = [];

  @override
  void initState() {
    super.initState();
    _loadData(showSpinner: true);
  }

  Future<void> _loadData({bool showSpinner = false}) async {
    if (showSpinner) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final params = await DatabaseHelper.instance.loadParameters();
      final rowMaps = await DatabaseHelper.instance.loadRows();

      final List<CashFlowRow> loadedRows = [];
      for (final map in rowMaps) {
        final List<int> values = [];
        for (var i = 0; i < 12; i++) {
          values.add(map['val_$i'] as int? ?? 0);
        }

        final groupStr = map['group_type'] as String;
        final group = CashFlowGroup.values.firstWhere(
          (g) => g.id == groupStr,
          orElse: () => CashFlowGroup.variableExpense,
        );

        loadedRows.add(
          CashFlowRow(
            id: map['id'] as int,
            label: map['label'] as String,
            group: group,
            values: values,
            controlValue: map['control_value'] as int? ?? 0,
          ),
        );
      }

      setState(() {
        cashValue = params['cash'] ?? 0;
        bankValue = params['bank'] ?? 0;
        objectiveValue = params['objective'] ?? 0;
        rows = loadedRows;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF36D399)),
        ),
      );
    }

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
                onCashChanged: (value) {
                  setState(() => cashValue = value);
                  DatabaseHelper.instance.saveParameter('cash', value);
                },
                onBankChanged: (value) {
                  setState(() => bankValue = value);
                  DatabaseHelper.instance.saveParameter('bank', value);
                },
                onObjectiveChanged: (value) {
                  setState(() => objectiveValue = value);
                  DatabaseHelper.instance.saveParameter('objective', value);
                },
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
                          setState(() {
                            rows[rowIndex].values[monthIndex] = value;
                          });
                          final rowId = rows[rowIndex].id;
                          if (rowId != null) {
                            DatabaseHelper.instance.saveRowMonthValue(
                              rowId,
                              monthIndex,
                              value,
                            );
                          }
                        },
                        onControlValueChanged: (rowIndex, value) {
                          setState(() {
                            rows[rowIndex].controlValue = value;
                          });
                          final rowId = rows[rowIndex].id;
                          if (rowId != null) {
                            DatabaseHelper.instance.saveRowControlValue(
                              rowId,
                              value,
                            );
                          }
                        },
                        onAddRow: _addNewRow,
                        onDeleteRow: _deleteRow,
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

  Future<void> _clearAllData() async {
    await DatabaseHelper.instance.resetAllData();
    await _loadData(showSpinner: false);
    setState(() {
      inputResetVersion++;
    });
  }

  Future<void> _addNewRow(CashFlowGroup group) async {
    final textController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Agregar nuevo ${group.label}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nombre (ej: Sueldo, Comida...)',
            hintStyle: TextStyle(color: Colors.grey),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(textController.text.trim()),
            child: const Text(
              'Agregar',
              style: TextStyle(color: Color(0xFF36D399)),
            ),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      await DatabaseHelper.instance.insertRow(name, group.id);
      await _loadData(showSpinner: false);
    }
  }

  Future<void> _deleteRow(int rowIndex) async {
    final row = rows[rowIndex];
    final rowId = row.id;
    if (rowId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Confirmar eliminación',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Text('¿Estás seguro de que deseas eliminar "${row.label}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deleteRow(rowId);
      await _loadData(showSpinner: false);
    }
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

enum CashFlowGroup {
  income('income', 'Ingreso', Color(0xFFE2F0D9)),
  fixedExpense('fixedExpense', 'Gasto Fijo', Color(0xFFFFF2CC)),
  variableExpense('variableExpense', 'Gasto Variable', Color(0xFFFCE4D6));

  const CashFlowGroup(this.id, this.label, this.color);
  final String id;
  final String label;
  final Color color;
}

class CashFlowRow {
  CashFlowRow({
    this.id,
    required this.label,
    required this.group,
    required this.values,
    this.controlValue = 0,
  });

  final int? id;
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
    return VStack([
          'Parametros'.text
              .titleMedium(context)
              .extraBlack
              .color(const Color(0xFFE5E7EB))
              .make(),
          28.heightBox,
          _ParameterInput(
            label: 'Efectivo',
            value: cashValue,
            resetVersion: inputResetVersion,
            onChanged: onCashChanged,
          ),
          24.heightBox,
          _ParameterInput(
            label: 'Banco',
            value: bankValue,
            resetVersion: inputResetVersion,
            onChanged: onBankChanged,
          ),
          24.heightBox,
          _ReadOnlyMetric(label: 'Total', value: cashValue + bankValue),
          24.heightBox,
          _ParameterInput(
            label: 'Objetivo',
            value: objectiveValue,
            resetVersion: inputResetVersion,
            onChanged: onObjectiveChanged,
          ),
        ], crossAlignment: CrossAxisAlignment.start)
        .p(14)
        .box
        .color(const Color(0xFF111827))
        .border(color: const Color(0xFF334155), width: 2)
        .roundedSM
        .width(150)
        .make();
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
    return VStack([
      label.text.extraBold.make(),
      8.heightBox,
      _MiniInput(
        key: ValueKey('$resetVersion-$label'),
        initialValue: value,
        onChanged: onChanged,
      ),
    ], crossAlignment: CrossAxisAlignment.start);
  }
}

class _ReadOnlyMetric extends StatelessWidget {
  const _ReadOnlyMetric({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return VStack([
      label.text.extraBold.make(),
      8.heightBox,
      _formatMoney(value).text
          .size(12)
          .extraBold
          .make()
          .pSymmetric(h: 8)
          .box
          .alignCenterRight
          .color(const Color(0xFF0B1020))
          .border(color: const Color(0xFF475569), width: 1.5)
          .roundedSM
          .width(double.infinity)
          .height(38)
          .make(),
    ], crossAlignment: CrossAxisAlignment.start);
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
          hintStyle: const TextStyle(color: Color(0x6694A3B8), fontSize: 12),
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
    return HStack([
      _HeaderMetric(
        title: 'Ingresos total',
        value: _formatMoney(yearlyIncome),
        color: const Color(0xFF36D399),
      ),
      14.widthBox,
      _HeaderMetric(
        title: 'Gastos total',
        value: _formatMoney(yearlyExpenses),
        color: const Color(0xFFF87171),
      ),
      14.widthBox,
      _HeaderMetric(
        title: 'Proyeccion',
        value: _formatMoney(projection),
        color: projection >= 0
            ? const Color(0xFF60A5FA)
            : const Color(0xFFF87171),
      ),
      64.widthBox,
      DropdownButtonFormField<int>(
        initialValue: selectedMonthIndex,
        decoration: InputDecoration(
          labelText: 'Mes act.',
          filled: true,
          fillColor: const Color(0xFF111827),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        items: List.generate(months.length, (index) {
          return DropdownMenuItem(value: index, child: Text(months[index]));
        }),
        onChanged: onMonthChanged,
      ).box.width(170).make(),
      18.widthBox,
      IconButton.filledTonal(
        tooltip: 'Eliminar todos los datos',
        onPressed: onClear,
        icon: const Icon(Icons.delete_outline),
      ),
    ]).h(94).scrollHorizontal();
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
    return VStack(
          [
            title.text.extraBold.make(),
            4.heightBox,
            value.text
                .color(color)
                .size(13)
                .extraBlack
                .ellipsis
                .maxLines(1)
                .make(),
          ],
          alignment: MainAxisAlignment.center,
          crossAlignment: CrossAxisAlignment.start,
        )
        .pSymmetric(h: 14, v: 6)
        .box
        .color(const Color(0xFF111827))
        .border(color: const Color(0xFF334155), width: 2)
        .roundedSM
        .make()
        .wh(200, 78);
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
    required this.onAddRow,
    required this.onDeleteRow,
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
  final void Function(CashFlowGroup group) onAddRow;
  final void Function(int rowIndex) onDeleteRow;

  @override
  State<_CashFlowTable> createState() => _CashFlowTableState();
}

class _CashFlowTableState extends State<_CashFlowTable> {
  final ScrollController _horizontalController = ScrollController();
  int? activeRowIndex;
  int? activeMonthIndex;
  int? dragEndRowIndex;
  int? dragEndMonthIndex;
  int dragFillVersion = 0;
  int? requestedFocusRowIndex;
  int? requestedFocusMonthIndex;

  @override
  void didUpdateWidget(_CashFlowTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.inputResetVersion != widget.inputResetVersion) {
      dragFillVersion = 0;
    }
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  void _handleCellFocused(int rowIndex, int monthIndex) {
    setState(() {
      activeRowIndex = rowIndex;
      activeMonthIndex = monthIndex;
      requestedFocusRowIndex = null;
      requestedFocusMonthIndex = null;
    });
  }

  List<int> get _visualRowIndices {
    final List<int> indices = [];
    for (var i = 0; i < widget.rows.length; i++) {
      if (widget.rows[i].group == CashFlowGroup.income) {
        indices.add(i);
      }
    }
    for (var i = 0; i < widget.rows.length; i++) {
      if (widget.rows[i].group == CashFlowGroup.fixedExpense) {
        indices.add(i);
      }
    }
    for (var i = 0; i < widget.rows.length; i++) {
      if (widget.rows[i].group == CashFlowGroup.variableExpense) {
        indices.add(i);
      }
    }
    return indices;
  }

  void _handleDirectionalKey(int rowIndex, int monthIndex, LogicalKeyboardKey key) {
    final visualIndices = _visualRowIndices;
    final currentVisualRow = visualIndices.indexOf(rowIndex);
    if (currentVisualRow == -1) return;

    int targetRowIndex = rowIndex;
    int targetMonthIndex = monthIndex;

    if (key == LogicalKeyboardKey.arrowUp) {
      if (currentVisualRow > 0) {
        targetRowIndex = visualIndices[currentVisualRow - 1];
      }
    } else if (key == LogicalKeyboardKey.arrowDown) {
      if (currentVisualRow < visualIndices.length - 1) {
        targetRowIndex = visualIndices[currentVisualRow + 1];
      }
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      if (monthIndex > 0) {
        targetMonthIndex = monthIndex - 1;
      }
    } else if (key == LogicalKeyboardKey.arrowRight) {
      if (monthIndex < 11) {
        targetMonthIndex = monthIndex + 1;
      }
    }

    if (targetRowIndex != rowIndex || targetMonthIndex != monthIndex) {
      setState(() {
        requestedFocusRowIndex = targetRowIndex;
        requestedFocusMonthIndex = targetMonthIndex;
      });
    }
  }

  void _handleDragUpdate(double dx, double dy) {
    if (activeRowIndex == null || activeMonthIndex == null) return;

    int colsDragged = (dx / _CashFlowPageState.monthColumnWidth).round();
    int rowsDragged = (dy / 24.0).round();

    int targetMonth = (activeMonthIndex! + colsDragged).clamp(0, 11);
    int targetRow = (activeRowIndex! + rowsDragged).clamp(0, widget.rows.length - 1);

    setState(() {
      if (colsDragged.abs() >= rowsDragged.abs()) {
        dragEndMonthIndex = targetMonth;
        dragEndRowIndex = activeRowIndex;
      } else {
        dragEndRowIndex = targetRow;
        dragEndMonthIndex = activeMonthIndex;
      }
    });
  }

  void _handleDragEnd() {
    if (activeRowIndex == null || activeMonthIndex == null ||
        dragEndRowIndex == null || dragEndMonthIndex == null) {
      return;
    }

    final sourceValue = widget.rows[activeRowIndex!].values[activeMonthIndex!];

    if (dragEndMonthIndex != activeMonthIndex) {
      final start = min(activeMonthIndex!, dragEndMonthIndex!);
      final end = max(activeMonthIndex!, dragEndMonthIndex!);
      for (var col = start; col <= end; col++) {
        widget.onValueChanged(activeRowIndex!, col, sourceValue);
      }
    } else if (dragEndRowIndex != activeRowIndex) {
      final start = min(activeRowIndex!, dragEndRowIndex!);
      final end = max(activeRowIndex!, dragEndRowIndex!);
      for (var r = start; r <= end; r++) {
        widget.onValueChanged(r, activeMonthIndex!, sourceValue);
      }
    }

    setState(() {
      dragEndRowIndex = null;
      dragEndMonthIndex = null;
      dragFillVersion++;
    });
  }

  bool _isCellInDragRange(int r, int c) {
    if (activeRowIndex == null || activeMonthIndex == null ||
        dragEndRowIndex == null || dragEndMonthIndex == null) {
      return false;
    }
    if (dragEndMonthIndex != activeMonthIndex) {
      final start = min(activeMonthIndex!, dragEndMonthIndex!);
      final end = max(activeMonthIndex!, dragEndMonthIndex!);
      return r == activeRowIndex && c >= start && c <= end;
    } else {
      final start = min(activeRowIndex!, dragEndRowIndex!);
      final end = max(activeRowIndex!, dragEndRowIndex!);
      return c == activeMonthIndex && r >= start && r <= end;
    }
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
                  _SectionTitle(
                    title: 'INGRESOS',
                    color: const Color(0xFFE2F0D9),
                    onAddPressed: () => widget.onAddRow(CashFlowGroup.income),
                  ),
                  ..._rowsFor(CashFlowGroup.income),
                  _TotalRow(
                    label: 'TOTAL INGRESO',
                    values: widget.monthlyIncome,
                    controlValue: _controlTotal(CashFlowGroup.income),
                    color: const Color(0xFFDDEBF7),
                    selectedMonthIndex: widget.selectedMonthIndex,
                  ),
                  _SectionTitle(
                    title: 'GASTOS FIJOS',
                    color: const Color(0xFFFFF2CC),
                    onAddPressed: () =>
                        widget.onAddRow(CashFlowGroup.fixedExpense),
                  ),
                  ..._rowsFor(CashFlowGroup.fixedExpense),
                  _TotalRow(
                    label: 'TOTAL GASTOS FIJOS',
                    values: widget.monthlyFixed,
                    controlValue: _controlTotal(CashFlowGroup.fixedExpense),
                    color: const Color(0xFFDDEBF7),
                    isExpense: true,
                    selectedMonthIndex: widget.selectedMonthIndex,
                  ),
                  _SectionTitle(
                    title: 'GASTOS VARIABLES',
                    color: const Color(0xFFFCE4D6),
                    onAddPressed: () =>
                        widget.onAddRow(CashFlowGroup.variableExpense),
                  ),
                  ..._rowsFor(CashFlowGroup.variableExpense),
                  _TotalRow(
                    label: 'TOTAL GASTOS VARIABLES',
                    values: widget.monthlyVariable,
                    controlValue: _controlTotal(CashFlowGroup.variableExpense),
                    color: const Color(0xFFDDEBF7),
                    isExpense: true,
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
          final rowIndex = entry.key;
          return _EditableTableRow(
            rowIndex: rowIndex,
            row: entry.value,
            rowColor: group.color,
            selectedMonthIndex: widget.selectedMonthIndex,
            inputResetVersion: widget.inputResetVersion,
            dragFillVersion: dragFillVersion,
            onValueChanged: widget.onValueChanged,
            onControlValueChanged: widget.onControlValueChanged,
            onDeleteRow: widget.onDeleteRow,
            activeRowIndex: activeRowIndex,
            activeMonthIndex: activeMonthIndex,
            onCellFocused: _handleCellFocused,
            onDragHandle: _handleDragUpdate,
            onDragHandleEnd: _handleDragEnd,
            isCellInDragRange: _isCellInDragRange,
            requestedFocusRowIndex: requestedFocusRowIndex,
            requestedFocusMonthIndex: requestedFocusMonthIndex,
            onDirectionalKey: _handleDirectionalKey,
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

class _YearRow extends StatelessWidget {
  const _YearRow({required this.year});

  final String year;

  @override
  Widget build(BuildContext context) {
    return year.text.white.extraBlack
        .size(12)
        .make()
        .box
        .alignCenter
        .color(const Color(0xFF111111))
        .border(color: Colors.black, width: 1)
        .make()
        .wh(
          _CashFlowPageState.categoryColumnWidth +
              (_CashFlowPageState.monthColumnWidth * 14),
          22,
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
  const _SectionTitle({
    required this.title,
    required this.color,
    required this.onAddPressed,
  });

  final String title;
  final Color color;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.black, width: 0.7),
      ),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onAddPressed,
              child: const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.add, size: 16, color: Color(0xFF111111)),
              ),
            ),
          ),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF111111),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
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
    required this.dragFillVersion,
    required this.onValueChanged,
    required this.onControlValueChanged,
    required this.onDeleteRow,
    required this.activeRowIndex,
    required this.activeMonthIndex,
    required this.onCellFocused,
    required this.onDragHandle,
    required this.onDragHandleEnd,
    required this.isCellInDragRange,
    required this.requestedFocusRowIndex,
    required this.requestedFocusMonthIndex,
    required this.onDirectionalKey,
  });

  final int rowIndex;
  final CashFlowRow row;
  final Color rowColor;
  final int selectedMonthIndex;
  final int inputResetVersion;
  final int dragFillVersion;
  final void Function(int rowIndex, int monthIndex, int value) onValueChanged;
  final void Function(int rowIndex, int value) onControlValueChanged;
  final void Function(int rowIndex) onDeleteRow;

  final int? activeRowIndex;
  final int? activeMonthIndex;
  final void Function(int rowIndex, int monthIndex) onCellFocused;
  final void Function(double dx, double dy) onDragHandle;
  final VoidCallback onDragHandleEnd;
  final bool Function(int r, int c) isCellInDragRange;

  final int? requestedFocusRowIndex;
  final int? requestedFocusMonthIndex;
  final void Function(int rowIndex, int monthIndex, LogicalKeyboardKey key) onDirectionalKey;

  @override
  Widget build(BuildContext context) {
    final rowTotal = row.values.asMap().entries.fold(0, (sum, entry) {
      final value = entry.key == selectedMonthIndex
          ? entry.value - row.controlValue
          : entry.value;
      return sum + value;
    });

    return HStack([
      _TableCell(
        width: _CashFlowPageState.categoryColumnWidth,
        color: rowColor,
        child: HStack([
          row.label.text
              .maxLines(1)
              .ellipsis
              .color(const Color(0xFF111111))
              .size(12)
              .semiBold
              .make()
              .expand(),
          InkWell(
            onTap: () => onDeleteRow(rowIndex),
            child: const Icon(
              Icons.close,
              size: 14,
              color: Color(0x99111111),
            ).pSymmetric(h: 4),
          ),
        ]),
      ),
      ...List.generate(row.values.length, (monthIndex) {
        final isSelectedMonth = monthIndex == selectedMonthIndex;
        final isActiveCell = activeRowIndex == rowIndex && activeMonthIndex == monthIndex;
        final isInDragRange = isCellInDragRange(rowIndex, monthIndex);

        final cellColor = isActiveCell
            ? (isSelectedMonth ? const Color(0xFFFFEB3B) : rowColor)
            : isInDragRange
                ? const Color(0xFFC8E6C9)
                : (isSelectedMonth ? const Color(0xFFFFEB3B) : rowColor);

        final cellValueKey = '$inputResetVersion-$dragFillVersion-$rowIndex-$monthIndex';
        final isRequestedFocus = requestedFocusRowIndex == rowIndex && requestedFocusMonthIndex == monthIndex;

        return _TableCell(
          width: _CashFlowPageState.monthColumnWidth,
          color: cellColor,
          isSelected: isActiveCell,
          onDragHandle: isActiveCell ? onDragHandle : null,
          onDragHandleEnd: isActiveCell ? onDragHandleEnd : null,
          child: _EditableCell(
            key: ValueKey(cellValueKey),
            rowIndex: rowIndex,
            monthIndex: monthIndex,
            initialValue: row.values[monthIndex],
            style: TextStyle(
              color: ((row.group == CashFlowGroup.fixedExpense ||
                          row.group == CashFlowGroup.variableExpense) &&
                      row.values[monthIndex] != 0)
                  ? const Color(0xFFC00000)
                  : const Color(0xFF111111),
              fontSize: 12,
              fontWeight: isSelectedMonth ? FontWeight.w800 : FontWeight.w400,
            ),
            onCellFocused: onCellFocused,
            onValueChanged: (val) => onValueChanged(rowIndex, monthIndex, val),
            requestedFocus: isRequestedFocus,
            onDirectionalKey: (key) => onDirectionalKey(rowIndex, monthIndex, key),
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
            hintStyle: TextStyle(color: Color(0x66111111), fontSize: 12),
          ),
          style: TextStyle(
            color: ((row.group == CashFlowGroup.fixedExpense ||
                        row.group == CashFlowGroup.variableExpense) &&
                    row.controlValue != 0)
                ? const Color(0xFFC00000)
                : const Color(0xFF111111),
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
        child: _formatMoney(rowTotal).text
            .align(TextAlign.right)
            .color(
              ((row.group == CashFlowGroup.fixedExpense ||
                          row.group == CashFlowGroup.variableExpense) &&
                      rowTotal != 0)
                  ? const Color(0xFFC00000)
                  : const Color(0xFF111111),
            )
            .semiBold
            .size(12)
            .make()
            .wFull(context),
      ),
    ]);
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.values,
    required this.color,
    this.controlValue,
    this.highlightBalance = false,
    this.isExpense = false,
    this.selectedMonthIndex,
  });

  final String label;
  final List<int> values;
  final Color color;
  final int? controlValue;
  final bool highlightBalance;
  final bool isExpense;
  final int? selectedMonthIndex;

  @override
  Widget build(BuildContext context) {
    final totalSum = values.fold(0, (sum, value) => sum + value);

    return Container(
      color: color,
      child: HStack([
        _TableCell(
          width: _CashFlowPageState.categoryColumnWidth,
          color: color,
          child: label.text
              .color(const Color(0xFF111111))
              .size(11)
              .extraBold
              .make(),
        ),
        ...values.asMap().entries.map((entry) {
          final value = entry.value;
          final isSelectedMonth = entry.key == selectedMonthIndex;
          final textColor =
              (highlightBalance && value < 0) || (isExpense && value != 0)
              ? const Color(0xFFC00000)
              : isSelectedMonth
              ? const Color(0xFF111111)
              : const Color(0xFF111111);
          return _TableCell(
            width: _CashFlowPageState.monthColumnWidth,
            color: isSelectedMonth ? const Color(0xFFFFEB3B) : color,
            child: _formatMoney(value).text
                .align(TextAlign.right)
                .extraBold
                .color(textColor)
                .size(12)
                .make()
                .wFull(context),
          );
        }),
        _TableCell(
          width: _CashFlowPageState.monthColumnWidth,
          color: color,
          child: (controlValue == null ? '' : _formatMoney(controlValue!)).text
              .align(TextAlign.right)
              .extraBold
              .color(
                (highlightBalance && (controlValue ?? 0) < 0) ||
                        (isExpense && (controlValue ?? 0) != 0)
                    ? const Color(0xFFC00000)
                    : const Color(0xFF111111),
              )
              .size(12)
              .make()
              .wFull(context),
        ),
        _TableCell(
          width: _CashFlowPageState.monthColumnWidth,
          color: color,
          child: _formatMoney(totalSum).text
              .align(TextAlign.right)
              .extraBold
              .color(
                (isExpense && totalSum != 0)
                    ? const Color(0xFFC00000)
                    : const Color(0xFF111111),
              )
              .size(12)
              .make()
              .wFull(context),
        ),
      ]),
    );
  }
}

class _TableCell extends StatelessWidget {
  const _TableCell({
    required this.width,
    required this.child,
    this.color,
    this.isSelected = false,
    this.onDragHandle,
    this.onDragHandleEnd,
  });

  final double width;
  final Widget child;
  final Color? color;
  final bool isSelected;
  final void Function(double dx, double dy)? onDragHandle;
  final VoidCallback? onDragHandleEnd;

  @override
  Widget build(BuildContext context) {
    Widget cellWidget = child
        .pSymmetric(h: 4)
        .box
        .alignCenterLeft
        .color(color ?? const Color(0xFFFFFFFF))
        .border(
          color: isSelected ? const Color(0xFF2E7D32) : Colors.black,
          width: isSelected ? 2.0 : 0.7,
        )
        .make()
        .wh(width, 24);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        cellWidget,
        if (isSelected && onDragHandle != null)
          Positioned(
            right: -3,
            bottom: -3,
            child: GestureDetector(
              onPanUpdate: (details) {
                onDragHandle!(details.localPosition.dx, details.localPosition.dy);
              },
              onPanEnd: (_) {
                if (onDragHandleEnd != null) onDragHandleEnd!();
              },
              child: Container(
                width: 8,
                height: 8,
                color: const Color(0xFF2E7D32),
              ),
            ),
          ),
      ],
    );
  }
}

int _parseMoney(String value) {
  return int.tryParse(value.replaceAll('.', '').replaceAll(',', '')) ?? 0;
}

const _monthsMap = {
  'Ene': 'ENERO',
  'Feb': 'FEBRERO',
  'Mar': 'MARZO',
  'Abr': 'ABRIL',
  'May': 'MAYO',
  'Jun': 'JUNIO',
  'Jul': 'JULIO',
  'Ago': 'AGOSTO',
  'Sep': 'SEPTIEMBRE',
  'Oct': 'OCTUBRE',
  'Nov': 'NOVIEMBRE',
  'Dic': 'DICIEMBRE',
};

String _fullMonthName(String short) => _monthsMap[short] ?? short.toUpperCase();

String _formatMoney(int value) =>
    '${value < 0 ? '-' : ''}\$${NumberFormat('#,###').format(value.abs()).replaceAll(',', '.')}';

class _EditableCell extends StatefulWidget {
  const _EditableCell({
    super.key,
    required this.rowIndex,
    required this.monthIndex,
    required this.initialValue,
    required this.style,
    required this.onCellFocused,
    required this.onValueChanged,
    required this.requestedFocus,
    required this.onDirectionalKey,
  });

  final int rowIndex;
  final int monthIndex;
  final int initialValue;
  final TextStyle style;
  final void Function(int rowIndex, int monthIndex) onCellFocused;
  final void Function(int value) onValueChanged;
  final bool requestedFocus;
  final void Function(LogicalKeyboardKey key) onDirectionalKey;

  @override
  State<_EditableCell> createState() => _EditableCellState();
}

class _EditableCellState extends State<_EditableCell> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.arrowUp ||
              key == LogicalKeyboardKey.arrowDown ||
              key == LogicalKeyboardKey.arrowLeft ||
              key == LogicalKeyboardKey.arrowRight) {
            widget.onDirectionalKey(key);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
    );
    _focusNode.addListener(_onFocusChange);
    if (widget.requestedFocus) {
      _requestMyFocus();
    }
  }

  @override
  void didUpdateWidget(_EditableCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.requestedFocus && !oldWidget.requestedFocus) {
      _requestMyFocus();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      widget.onCellFocused(widget.rowIndex, widget.monthIndex);
    }
  }

  void _requestMyFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_focusNode.hasFocus) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      focusNode: _focusNode,
      initialValue: widget.initialValue == 0 ? '' : widget.initialValue.toString(),
      textAlign: TextAlign.right,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        hintText: '0',
        hintStyle: TextStyle(color: Color(0x66111111), fontSize: 12),
      ),
      style: widget.style,
      cursorColor: const Color(0xFF111111),
      onChanged: (value) {
        widget.onValueChanged(_parseMoney(value));
      },
    );
  }
}
