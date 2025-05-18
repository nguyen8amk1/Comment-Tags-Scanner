import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

void main() async {
  // Example 1: File Explorer Data
  String jsonData1 = '''
    [
      {"path": "C:\\\\boot.ini", "dateModified": "2024-01-01T12:00:00Z", "size": 4096},
      {"path": "C:\\\\foo.txt", "dateModified": "2024-01-05T15:30:00Z", "size": 1024},
      {"path": "C:\\\\bar.txt", "dateModified": "2024-01-10T08:00:00Z", "size": 2048}
    ]
    ''';

  // Example 2: Product Inventory
  String jsonData2 = '''
    [
      {"id": 1, "name": "Laptop", "category": "Electronics", "price": 999.99, "stock": 42},
      {"id": 2, "name": "Desk Chair", "category": "Furniture", "price": 149.99, "stock": 15},
      {"id": 3, "name": "Coffee Mug", "category": "Kitchen", "price": 12.99, "stock": 120}
    ]
    ''';

  // Example 3: Employee Data
  String jsonData3 = '''
    [
      {"employeeId": "E1001", "fullName": "John Smith", "department": "Engineering", "hireDate": "2020-05-15", "salary": 85000},
      {"employeeId": "E1002", "fullName": "Jane Doe", "department": "Marketing", "hireDate": "2019-11-03", "salary": 72000},
      {"employeeId": "E1003", "fullName": "Bob Johnson", "department": "HR", "hireDate": "2021-02-20", "salary": 68000}
    ]
    ''';

  final initialTabs = [
    DataViewerTab(
      tabName: "Files",
      columns: [
        DataColumnInfo("Name", "path", flex: 3),
        DataColumnInfo("Modified", "dateModified", flex: 2),
        DataColumnInfo("Size", "size", flex: 1),
      ],
      data: jsonDecode(jsonData1),
      formatters: {
        "size": (value) => _formatFileSize(value),
        "dateModified": (value) => _formatDate(DateTime.parse(value)),
      },
    ),
    DataViewerTab(
      tabName: "Products",
      columns: [
        DataColumnInfo("ID", "id", flex: 1),
        DataColumnInfo("Product", "name", flex: 2),
        DataColumnInfo("Category", "category", flex: 2),
        DataColumnInfo("Price", "price", flex: 1),
        DataColumnInfo("Stock", "stock", flex: 1),
      ],
      data: jsonDecode(jsonData2),
      formatters: {
        "price": (value) => '\$${value.toStringAsFixed(2)}',
      },
    ),
    DataViewerTab(
      tabName: "Employees",
      columns: [
        DataColumnInfo("ID", "employeeId", flex: 1),
        DataColumnInfo("Name", "fullName", flex: 2),
        DataColumnInfo("Department", "department", flex: 2),
        DataColumnInfo("Hire Date", "hireDate", flex: 1),
        DataColumnInfo("Salary", "salary", flex: 1),
      ],
      data: jsonDecode(jsonData3),
      formatters: {
        "salary": (value) => '\$${value.toStringAsFixed(0)}',
        "hireDate": (value) => _formatDate(DateTime.parse(value)),
      },
    ),
  ];

  runApp(
    ChangeNotifierProvider<MultiDataViewerModel>(
      create: (context) => MultiDataViewerModel(tabs: initialTabs),
      builder: (context, child) => const MyApp(),
    ),
  );
}

String _formatFileSize(dynamic size) {
  if (size is! int) return size.toString();
  
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

String _formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Data Viewer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MultiDataViewer(),
    );
  }
}

class DataColumnInfo {
  final String displayName;
  final String dataKey;
  final int flex;
  final bool sortable;

  DataColumnInfo(this.displayName, this.dataKey, {this.flex = 1, this.sortable = true});
}

class DataViewerTab {
  final String tabName;
  final List<DataColumnInfo> columns;
  final List<dynamic> data;
  final Map<String, String Function(dynamic)> formatters;

  DataViewerTab({
    required this.tabName,
    required this.columns,
    required this.data,
    this.formatters = const {},
  });
}

class MultiDataViewerModel extends ChangeNotifier {
  List<DataViewerModel> tabs;
  int selectedTabIndex = 0;

  MultiDataViewerModel({required List<DataViewerTab> tabs}) 
      : tabs = tabs.map((tab) => DataViewerModel(
          tabName: tab.tabName,
          columns: tab.columns,
          data: tab.data,
          formatters: tab.formatters,
        )).toList();

  void addTab(DataViewerTab tab) {
    tabs.add(DataViewerModel(
      tabName: tab.tabName,
      columns: tab.columns,
      data: tab.data,
      formatters: tab.formatters,
    ));
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
  final String tabName;
  final List<DataColumnInfo> columns;
  final List<dynamic> data;
  final Map<String, String Function(dynamic)> formatters;
  
  String? sortColumnKey;
  bool sortAscending = true;

  DataViewerModel({
    required this.tabName,
    required this.columns,
    required this.data,
    required this.formatters,
  });

  List<dynamic> get sortedData {
    if (sortColumnKey == null) return data;
    
    return List.from(data)..sort((a, b) {
      dynamic aValue = a[sortColumnKey];
      dynamic bValue = b[sortColumnKey];
      
      // Handle null values
      if (aValue == null) return sortAscending ? -1 : 1;
      if (bValue == null) return sortAscending ? 1 : -1;
      
      // Compare based on type
      if (aValue is num && bValue is num) {
        return sortAscending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
      } else if (aValue is DateTime && bValue is DateTime) {
        return sortAscending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
      } else {
        return sortAscending 
            ? aValue.toString().compareTo(bValue.toString())
            : bValue.toString().compareTo(aValue.toString());
      }
    });
  }

  void setSortColumn(String columnKey) {
    if (sortColumnKey == columnKey) {
      // Toggle direction if same column
      sortAscending = !sortAscending;
    } else {
      sortColumnKey = columnKey;
      sortAscending = true;
    }
    notifyListeners();
  }
}

class MultiDataViewer extends StatefulWidget {
  const MultiDataViewer({super.key});

  @override
  State<MultiDataViewer> createState() => _MultiDataViewerState();
}

class _MultiDataViewerState extends State<MultiDataViewer> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final model = Provider.of<MultiDataViewerModel>(context, listen: false);
    _tabController = TabController(length: model.tabs.length, vsync: this);
    _tabController.addListener(() {
      model.selectTab(_tabController.index);
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
        model.selectTab(_tabController.index);
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
        title: const Text('Data Viewer'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: model.tabs.map((tab) => Tab(text: tab.tabName)).toList(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Example of adding a new tab
              final newTab = DataViewerTab(
                tabName: "New Tab",
                columns: [
                  DataColumnInfo("Field 1", "field1"),
                  DataColumnInfo("Field 2", "field2"),
                ],
                data: [
                  {"field1": "Value 1", "field2": "Value A"},
                  {"field1": "Value 2", "field2": "Value B"},
                ],
              );
              model.addTab(newTab);
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: model.tabs.map((tab) => 
          ChangeNotifierProvider<DataViewerModel>.value(
            value: tab,
            child: const DataViewer(),
          ),
        ).toList(),
      ),
    );
  }
}

class DataViewer extends StatelessWidget {
  const DataViewer({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Column(
        children: [
          DataViewerHeader(),
          Expanded(
            child: DataViewerList(),
          ),
        ],
      ),
    );
  }
}

class DataViewerHeader extends StatelessWidget {
  const DataViewerHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<DataViewerModel>(context);
    
    return Row(
      children: model.columns.map((column) {
        return _buildHeaderItem(
          context, 
          column.displayName, 
          column.dataKey,
          column.flex,
          column.sortable,
        );
      }).toList(),
    );
  }

  Widget _buildHeaderItem(
    BuildContext context, 
    String title, 
    String dataKey,
    int flex,
    bool sortable,
  ) {
    final model = Provider.of<DataViewerModel>(context);
    bool isSortedColumn = model.sortColumnKey == dataKey;
    
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: sortable ? () => model.setSortColumn(dataKey) : null,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey),
            ),
          ),
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Text(title),
              if (isSortedColumn)
                Icon(model.sortAscending ? Icons.arrow_drop_up : Icons.arrow_drop_down),
            ],
          ),
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

    return ListView.separated(
      itemCount: model.sortedData.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = model.sortedData[index];
        return DataViewerListItem(item: item);
      },
    );
  }
}

class DataViewerListItem extends StatelessWidget {
  final dynamic item;
  
  const DataViewerListItem({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<DataViewerModel>(context);

    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Item Details'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: model.columns.map((column) {
                  final value = item[column.dataKey];
                  final displayValue = model.formatters[column.dataKey]?.call(value) ?? value.toString();
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text('${column.displayName}: $displayValue'),
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      },
      child: Row(
        children: model.columns.map((column) {
          final value = item[column.dataKey];
          final displayValue = model.formatters[column.dataKey]?.call(value) ?? value.toString();
          
          return Expanded(
            flex: column.flex,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(displayValue),
            ),
          );
        }).toList(),
      ),
    );
  }
}
