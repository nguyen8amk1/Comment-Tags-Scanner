import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:flutter/animation.dart';
import 'dart:ui';

void main() async {
  // Example 1: File Explorer Data
  //   String jsonData1 = '''
  //     [
  //       {"path": "C:\\\\boot.ini", "dateModified": "2024-01-01T12:00:00Z", "size": 4096},
  //       {"path": "C:\\\\foo.txt", "dateModified": "2024-01-05T15:30:00Z", "size": 1024},
  //       {"path": "C:\\\\bar.txt", "dateModified": "2024-01-10T08:00:00Z", "size": 2048}
  //     ]
  //     ''';

  String jsonData1 = '''
  [
    {
        "file": "imstb_textedit.h",
        "line": 1140,
        "tag": "OPTIMIZE",
        "comment": "the undo/redo buffer should be circular"
    },
    {
        "file": "imstb_textedit.h",
        "line": 1160,
        "tag": "OPTIMIZE",
        "comment": "get rid of char_storage and infer it"
    }
]
  ''';

  // Example 2: Product Inventory
  //   String jsonData2 = '''
  //     [
  //       {"id": 1, "name": "Laptop", "category": "Electronics", "price": 999.99, "stock": 42},
  //       {"id": 2, "name": "Desk Chair", "category": "Furniture", "price": 149.99, "stock": 15},
  //       {"id": 3, "name": "Coffee Mug", "category": "Kitchen", "price": 12.99, "stock": 120}
  //     ]
  //     ''';
  String jsonData2 = '''
  [
    {
        "file": "imstb_rectpack.h",
        "line": 250,
        "tag": "TODO",
        "comment": "a smarter approach would be to only"
    }
]
  
  ''';

  // Example 3: Employee Data
  String jsonData3 = '''
[
    {
        "file": "imgui_tables.cpp",
        "line": 264,
        "tag": "FIXME",
        "comment": "-TABLE: Currently hard-coded because of clipping assumptions with outer borders rendering."
    },
    {
        "file": "imgui_tables.cpp",
        "line": 328,
        "tag": "FIXME",
        "comment": "coarse clipping because access to table data causes two issues:"
    }
]
    ''';

  final initialTabs = [
    DataViewerTab.autoConfigure(
      tabName: "OPTIMIZE",
      data: jsonDecode(jsonData1),
      primaryColumns: ['comment'],
      secondaryColumns: ['file', 'line', 'tag'],
      columnOverrides: {},
      // Optional overrides
      //       primaryColumns: ['path'],
      //       secondaryColumns: ['size', 'dateModified'],
      //       columnOverrides: {
      //         "size": ColumnConfig(
      //           header: "Size (bytes)",
      //           cellAlignment: Alignment.centerRight,
      //           formatter: FileSizeFormatter(),
      //         ),
      //       },
    ),
    DataViewerTab.autoConfigure(
      tabName: "TODO ",
      data: jsonDecode(jsonData2),
      primaryColumns: ['comment'],
      secondaryColumns: ['file', 'line', 'tag'],
      columnOverrides: {},
      //       primaryColumns: ['name', 'category', 'price'],
      //       secondaryColumns: ['stock'],
      //       // Optional overrides
      //       columnOverrides: {
      //         "price": ColumnConfig(
      //           header: "Price (USD)",
      //           formatter: CurrencyFormatter(),
      //           cellStyle:
      //               (value) => TextStyle(
      //                 color:
      //                     (value is num && value > 500) ? Colors.green : Colors.black,
      //                 fontWeight: FontWeight.bold,
      //               ),
      //         ),
      //         "stock": ColumnConfig(
      //           cellStyle:
      //               (value) => TextStyle(
      //                 color: (value is num && value < 20) ? Colors.red : Colors.black,
      //               ),
      //         ),
      //       },
    ),
    DataViewerTab.autoConfigure(
      tabName: "FIXME",
      data: jsonDecode(jsonData3),
      primaryColumns: ['comment'],
      secondaryColumns: ['file', 'line', 'tag'],
      columnOverrides: {},
    ),
  ];

  runApp(
    ChangeNotifierProvider<MultiDataViewerModel>(
      create: (context) => MultiDataViewerModel(tabs: initialTabs),
      builder: (context, child) => const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Data Viewer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        extensions: const [
          DataViewerTheme(
            headerStyle: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            headerBackground: Colors.blue,
            rowHeight: 48.0,
            evenRowColor: Colors.white,
            oddRowColor: Color(0xFFF5F5F5),
            sortIcon: Icons.sort,
            sortAscendingIcon: Icons.arrow_upward,
            sortDescendingIcon: Icons.arrow_downward,
            columnDividerColor: Colors.grey,
            rowHoverColor: Colors.blueGrey,
          ),
        ],
      ),
      home: const MultiDataViewer(),
    );
  }
}

/// --------------------------
/// Data Model and Configuration
/// --------------------------

class ColumnConfig {
  final String? header;
  final int flex;
  final bool sortable;
  final CellContentFormatter? formatter;
  final TextStyle? Function(dynamic)? cellStyle;
  final Alignment? cellAlignment;

  ColumnConfig({
    this.header,
    this.flex = 1,
    this.sortable = true,
    this.formatter,
    this.cellStyle,
    this.cellAlignment,
  });
}

class DataViewerTab {
  final String tabName;
  final List<dynamic> data;
  final Map<String, ColumnConfig> columnConfigs;
  final List<String> primaryColumns;
  final List<String> secondaryColumns;

  DataViewerTab({
    required this.tabName,
    required this.data,
    required this.columnConfigs,
    required this.primaryColumns,
    required this.secondaryColumns,
  });

  factory DataViewerTab.autoConfigure({
    required String tabName,
    required List<dynamic> data,
    Map<String, ColumnConfig> columnOverrides = const {},
    List<String>? primaryColumns,
    List<String>? secondaryColumns,
  }) {
    if (data.isEmpty) {
      return DataViewerTab(
        tabName: tabName,
        data: data,
        columnConfigs: columnOverrides,
        primaryColumns: primaryColumns ?? [],
        secondaryColumns: secondaryColumns ?? [],
      );
    }

    // Auto-detect columns from first data item
    final firstItem = data.first as Map<String, dynamic>;
    final columnConfigs = <String, ColumnConfig>{};
    final detectedPrimaryColumns = <String>[];
    final detectedSecondaryColumns = <String>[];

    for (final key in firstItem.keys) {
      final value = firstItem[key];
      ColumnConfig config;

      if (columnOverrides.containsKey(key)) {
        config = columnOverrides[key]!;
      } else {
        // Auto-configure based on value type and key name
        config = _autoConfigureColumn(key, value);
      }

      columnConfigs[key] = config;
      if (primaryColumns != null && primaryColumns.contains(key)) {
        detectedPrimaryColumns.add(key);
      } else if (secondaryColumns != null && secondaryColumns.contains(key)) {
        detectedSecondaryColumns.add(key);
      } else if (primaryColumns == null && secondaryColumns == null) {
        detectedPrimaryColumns.add(key);
      }
    }

    return DataViewerTab(
      tabName: tabName,
      data: data,
      columnConfigs: columnConfigs,
      primaryColumns: primaryColumns ?? detectedPrimaryColumns,
      secondaryColumns: secondaryColumns ?? detectedSecondaryColumns,
    );
  }

  static ColumnConfig _autoConfigureColumn(String key, dynamic value) {
    // Detect common patterns from key names
    final lowerKey = key.toLowerCase();

    // File size detection
    if (lowerKey.contains('size') && value is num) {
      return ColumnConfig(
        header: key,
        formatter: FileSizeFormatter(),
        cellAlignment: Alignment.centerRight,
      );
    }

    // Currency detection
    if (lowerKey.contains('price') ||
        lowerKey.contains('salary') ||
        lowerKey.contains('amount')) {
      return ColumnConfig(
        header: key,
        formatter: CurrencyFormatter(),
        cellAlignment: Alignment.centerRight,
      );
    }

    // Date detection
    if (lowerKey.contains('date') ||
        lowerKey.contains('modified') ||
        lowerKey.contains('time')) {
      return ColumnConfig(header: key, formatter: DateFormatter());
    }

    // Numeric values
    if (value is num) {
      return ColumnConfig(header: key, cellAlignment: Alignment.centerRight);
    }

    // Default configuration
    return ColumnConfig(header: key);
  }

  List<String> get columnKeys => columnConfigs.keys.toList();
}

abstract class CellContentFormatter {
  String format(dynamic value);
  TextAlign get textAlign => TextAlign.left;
}

class FileSizeFormatter extends CellContentFormatter {
  @override
  String format(dynamic size) {
    if (size is! num) return size.toString();

    if (size < 1024) {
      return '$size bytes';
    } else if (size < 1024 * 1024) {
      double kb = size / 1024;
      return '${kb.toStringAsFixed(2)} KB';
    } else {
      double mb = size / (1024 * 1024);
      return '${mb.toStringAsFixed(2)} MB';
    }
  }

  @override
  TextAlign get textAlign => TextAlign.right;
}

class CurrencyFormatter extends CellContentFormatter {
  final bool showCents;
  final String symbol;

  CurrencyFormatter({this.showCents = true, this.symbol = '\$'});

  @override
  String format(dynamic value) {
    if (value is num) {
      return showCents
          ? '$symbol${value.toStringAsFixed(2)}'
          : '$symbol${value.toStringAsFixed(0)}';
    }
    return value.toString();
  }

  @override
  TextAlign get textAlign => TextAlign.right;
}

class DateFormatter extends CellContentFormatter {
  @override
  String format(dynamic value) {
    try {
      if (value is DateTime) {
        return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
      } else if (value is String) {
        final date = DateTime.parse(value);
        return format(date);
      }
      return value.toString();
    } catch (e) {
      return value.toString();
    }
  }
}

class MultiDataViewerModel extends ChangeNotifier {
  List<DataViewerModel> tabs;
  int selectedTabIndex = 0;

  MultiDataViewerModel({required List<DataViewerTab> tabs})
    : tabs = tabs.map((tab) => DataViewerModel(tab: tab)).toList();

  void addTab(DataViewerTab tab) {
    tabs.add(DataViewerModel(tab: tab));
    selectedTabIndex = tabs.length - 1;
    notifyListeners();
  }

  void selectTab(int index) {
    selectedTabIndex = index;
    notifyListeners();
  }

  DataViewerModel get currentTab => tabs[selectedTabIndex];
}

class DataViewerModel extends ChangeNotifier {
  final DataViewerTab tab;

  String? sortColumnKey;
  bool sortAscending = true;

  DataViewerModel({required this.tab});

  List<dynamic> get sortedData {
    if (sortColumnKey == null) return tab.data;

    return List.from(tab.data)..sort((a, b) {
      final columnConfig = tab.columnConfigs[sortColumnKey]!;
      dynamic aValue = a[sortColumnKey];
      dynamic bValue = b[sortColumnKey];

      // Handle null values
      if (aValue == null) return sortAscending ? -1 : 1;
      if (bValue == null) return sortAscending ? 1 : -1;

      // Use formatter for comparison if available
      if (columnConfig.formatter != null) {
        final aStr = columnConfig.formatter!.format(aValue);
        final bStr = columnConfig.formatter!.format(bValue);
        return sortAscending ? aStr.compareTo(bStr) : bStr.compareTo(aStr);
      }

      // Compare based on type
      if (aValue is num && bValue is num) {
        return sortAscending
            ? aValue.compareTo(bValue)
            : bValue.compareTo(aValue);
      } else if (aValue is DateTime && bValue is DateTime) {
        return sortAscending
            ? aValue.compareTo(bValue)
            : bValue.compareTo(aValue);
      } else if (aValue is String && bValue is String) {
        return sortAscending
            ? aValue.compareTo(bValue)
            : bValue.compareTo(aValue);
      }

      return sortAscending
          ? aValue.toString().compareTo(bValue.toString())
          : bValue.toString().compareTo(aValue.toString());
    });
  }

  void setSortColumn(String columnKey) {
    if (tab.columnConfigs[columnKey] == null ||
        !tab.columnConfigs[columnKey]!.sortable)
      return;

    if (sortColumnKey == columnKey) {
      sortAscending = !sortAscending;
    } else {
      sortColumnKey = columnKey;
      sortAscending = true;
    }
    notifyListeners();
  }
}

/// --------------------------
/// Theme Definitions
/// --------------------------

@immutable
class DataViewerTheme extends ThemeExtension<DataViewerTheme> {
  final TextStyle? headerStyle;
  final Color? headerBackground;
  final double? rowHeight;
  final Color? evenRowColor;
  final Color? oddRowColor;
  final IconData? sortIcon;
  final IconData? sortAscendingIcon;
  final IconData? sortDescendingIcon;
  final Color? columnDividerColor;
  final Color? rowHoverColor;

  const DataViewerTheme({
    required this.headerStyle,
    required this.headerBackground,
    required this.rowHeight,
    required this.evenRowColor,
    required this.oddRowColor,
    required this.sortIcon,
    required this.sortAscendingIcon,
    required this.sortDescendingIcon,
    this.columnDividerColor,
    this.rowHoverColor,
  });

  @override
  DataViewerTheme copyWith({
    TextStyle? headerStyle,
    Color? headerBackground,
    double? rowHeight,
    Color? evenRowColor,
    Color? oddRowColor,
    IconData? sortIcon,
    IconData? sortAscendingIcon,
    IconData? sortDescendingIcon,
    Color? columnDividerColor,
    Color? rowHoverColor,
  }) {
    return DataViewerTheme(
      headerStyle: headerStyle ?? this.headerStyle,
      headerBackground: headerBackground ?? this.headerBackground,
      rowHeight: rowHeight ?? this.rowHeight,
      evenRowColor: evenRowColor ?? this.evenRowColor,
      oddRowColor: oddRowColor ?? this.oddRowColor,
      sortIcon: sortIcon ?? this.sortIcon,
      sortAscendingIcon: sortAscendingIcon ?? this.sortAscendingIcon,
      sortDescendingIcon: sortDescendingIcon ?? this.sortDescendingIcon,
      columnDividerColor: columnDividerColor ?? this.columnDividerColor,
      rowHoverColor: rowHoverColor ?? this.rowHoverColor,
    );
  }

  @override
  DataViewerTheme lerp(ThemeExtension<DataViewerTheme>? other, double t) {
    if (other is! DataViewerTheme) {
      return this;
    }
    return DataViewerTheme(
      headerStyle: TextStyle.lerp(headerStyle, other.headerStyle, t),
      headerBackground: Color.lerp(headerBackground, other.headerBackground, t),
      rowHeight: lerpDouble(rowHeight!, other.rowHeight!, t),
      evenRowColor: Color.lerp(evenRowColor, other.evenRowColor, t),
      oddRowColor: Color.lerp(oddRowColor, other.oddRowColor, t),
      sortIcon: t < 0.5 ? sortIcon : other.sortIcon,
      sortAscendingIcon: t < 0.5 ? sortAscendingIcon : other.sortAscendingIcon,
      sortDescendingIcon:
          t < 0.5 ? sortDescendingIcon : other.sortDescendingIcon,
      columnDividerColor: Color.lerp(
        columnDividerColor,
        other.columnDividerColor,
        t,
      ),
      rowHoverColor: Color.lerp(rowHoverColor, other.rowHoverColor, t),
    );
  }
}

/// --------------------------
/// Widget Implementation
/// --------------------------

class MultiDataViewer extends StatefulWidget {
  const MultiDataViewer({super.key});

  @override
  State<MultiDataViewer> createState() => _MultiDataViewerState();
}

class _MultiDataViewerState extends State<MultiDataViewer>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final model = Provider.of<MultiDataViewerModel>(context, listen: false);
    _tabController = TabController(length: model.tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        model.selectTab(_tabController.index);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final model = Provider.of<MultiDataViewerModel>(context);
    if (_tabController.length != model.tabs.length) {
      _tabController.dispose();
      _tabController = TabController(length: model.tabs.length, vsync: this);
      _tabController.addListener(() {
        if (_tabController.indexIsChanging) {
          model.selectTab(_tabController.index);
        }
      });
      _tabController.index = model.selectedTabIndex;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<MultiDataViewerModel>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Data Viewer'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: model.tabs.map((tab) => Tab(text: tab.tab.tabName)).toList(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Example of adding a new tab with auto-configuration
              final newTab = DataViewerTab.autoConfigure(
                tabName: "New Tab",
                data: [
                  {"field1": "Value 1", "field2": 42, "date": "2023-01-01"},
                  {"field1": "Value 2", "field2": 123, "date": "2023-02-15"},
                ],
                primaryColumns: ['field1', 'field2'],
                secondaryColumns: ['date'],
              );
              model.addTab(newTab);
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children:
            model.tabs
                .map<Widget>(
                  (tab) => ChangeNotifierProvider<DataViewerModel>.value(
                    value: tab,
                    child: const DataViewerScreen(),
                  ),
                )
                .toList(),
      ),
    );
  }
}

class DataViewerScreen extends StatelessWidget {
  const DataViewerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [DataViewerHeader(), Expanded(child: DataViewerList())],
    );
  }
}

class DataViewerHeader extends StatelessWidget {
  const DataViewerHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<DataViewerModel>(context);
    final theme = Theme.of(context).extension<DataViewerTheme>()!;

    return Container(
      color: theme.headerBackground,
      height: theme.rowHeight,
      child: Row(children: _buildHeaderChildren(context, model, theme)),
    );
  }

  List<Widget> _buildHeaderChildren(
    BuildContext context,
    DataViewerModel model,
    DataViewerTheme theme,
  ) {
    List<Widget> children = [];

    // Primary Columns
    for (final key in model.tab.primaryColumns) {
      final config = model.tab.columnConfigs[key] ?? ColumnConfig(header: key);
      children.add(
        Expanded(
          flex: config.flex * 2, // Primary columns get double flex
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: _buildHeaderItem(
              context,
              config.header ?? key,
              key,
              config.flex * 2,
              config.sortable,
            ),
          ),
        ),
      );

      // Add divider if not the last primary column
      if (key != model.tab.primaryColumns.last &&
          theme.columnDividerColor != null) {
        children.add(
          VerticalDivider(color: theme.columnDividerColor, width: 1.0),
        );
      }
    }

    // Secondary Columns
    for (final key in model.tab.secondaryColumns) {
      final config = model.tab.columnConfigs[key] ?? ColumnConfig(header: key);
      children.add(
        Expanded(
          flex: config.flex,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: _buildHeaderItem(
              context,
              config.header ?? key,
              key,
              config.flex,
              config.sortable,
            ),
          ),
        ),
      );

      // Add divider if not the last secondary column
      if (key != model.tab.secondaryColumns.last &&
          theme.columnDividerColor != null) {
        children.add(
          VerticalDivider(color: theme.columnDividerColor, width: 1.0),
        );
      }
    }

    return children;
  }

  Widget _buildHeaderItem(
    BuildContext context,
    String title,
    String dataKey,
    int flex,
    bool sortable,
  ) {
    final model = Provider.of<DataViewerModel>(context);
    final theme = Theme.of(context).extension<DataViewerTheme>()!;

    bool isSortedColumn = model.sortColumnKey == dataKey;

    return InkWell(
      onTap: sortable ? () => model.setSortColumn(dataKey) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.headerStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (sortable) ...[
              const SizedBox(width: 4),
              if (!isSortedColumn && theme.sortIcon != null)
                Icon(theme.sortIcon, size: 16, color: theme.headerStyle?.color),
              if (isSortedColumn &&
                  model.sortAscending &&
                  theme.sortAscendingIcon != null)
                Icon(
                  theme.sortAscendingIcon,
                  size: 16,
                  color: theme.headerStyle?.color,
                ),
              if (isSortedColumn &&
                  !model.sortAscending &&
                  theme.sortDescendingIcon != null)
                Icon(
                  theme.sortDescendingIcon,
                  size: 16,
                  color: theme.headerStyle?.color,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class DataViewerList extends StatelessWidget {
  const DataViewerList({super.key});

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<DataViewerModel>(context);
    final theme = Theme.of(context).extension<DataViewerTheme>()!;

    return ListView.separated(
      itemCount: model.sortedData.length,
      separatorBuilder:
          (context, index) => Divider(height: 1, color: Colors.grey[300]),
      itemBuilder: (context, index) {
        final item = model.sortedData[index];
        return DataViewerListItem(item: item, index: index);
      },
    );
  }
}

class DataViewerListItem extends StatefulWidget {
  final dynamic item;
  final int index;

  const DataViewerListItem({
    super.key,
    required this.item,
    required this.index,
  });

  @override
  State<DataViewerListItem> createState() => _DataViewerListItemState();
}

class _DataViewerListItemState extends State<DataViewerListItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<DataViewerModel>(context);
    final theme = Theme.of(context).extension<DataViewerTheme>()!;
    final rowColor =
        widget.index.isEven ? theme.evenRowColor : theme.oddRowColor;

    return MouseRegion(
      onEnter: (event) => setState(() => _isHovering = true),
      onExit: (event) => setState(() => _isHovering = false),
      child: InkWell(
        onTap: () => _showItemDetails(context, widget.item),
        child: Container(
          color: _isHovering ? theme.rowHoverColor : rowColor,
          height: theme.rowHeight,
          child: Row(
            children: _buildListRowChildren(context, model, theme, widget.item),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildListRowChildren(
    BuildContext context,
    DataViewerModel model,
    DataViewerTheme theme,
    dynamic item,
  ) {
    List<Widget> children = [];

    // Primary Columns
    for (final key in model.tab.primaryColumns) {
      final config = model.tab.columnConfigs[key] ?? ColumnConfig(header: key);
      final value = item[key];
      final formatter = config.formatter;
      final displayValue = formatter?.format(value) ?? value.toString();

      children.add(
        Expanded(
          flex: config.flex * 2, // Primary columns get double flex
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Align(
              alignment: config.cellAlignment ?? Alignment.centerLeft,
              child: Text(
                displayValue,
                style: config.cellStyle?.call(value),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      );

      // Add divider if not the last column
      if (key != model.tab.primaryColumns.last &&
          theme.columnDividerColor != null) {
        children.add(
          VerticalDivider(color: theme.columnDividerColor, width: 1.0),
        );
      }
    }

    // Secondary Columns
    for (final key in model.tab.secondaryColumns) {
      final config = model.tab.columnConfigs[key] ?? ColumnConfig(header: key);
      final value = item[key];
      final formatter = config.formatter;
      final displayValue = formatter?.format(value) ?? value.toString();

      children.add(
        Expanded(
          flex: config.flex,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Align(
              alignment: config.cellAlignment ?? Alignment.centerLeft,
              child: Text(
                displayValue,
                style: config.cellStyle?.call(value),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      );

      // Add divider if not the last column
      if (key != model.tab.secondaryColumns.last &&
          theme.columnDividerColor != null) {
        children.add(
          VerticalDivider(color: theme.columnDividerColor, width: 1.0),
        );
      }
    }

    return children;
  }

  void _showItemDetails(BuildContext context, dynamic item) {
    final model = Provider.of<DataViewerModel>(context, listen: false);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Item Details'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children:
                    model.tab.columnKeys.map((key) {
                      final config =
                          model.tab.columnConfigs[key] ??
                          ColumnConfig(header: key);
                      final value = item[key];
                      final formatter = config.formatter;
                      final displayValue =
                          formatter?.format(value) ?? value.toString();

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 120,
                              child: Text(
                                config.header ?? key,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                displayValue,
                                style: config.cellStyle?.call(value),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }
}

