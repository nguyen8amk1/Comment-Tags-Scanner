import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

void main() async {
  // Simulate loading from JSON for the first tab
  String jsonData1 = '''
    [
      {"path": "C:\\\\boot.ini", "dateModified": "2024-01-01T12:00:00Z", "size": 4096},
      {"path": "C:\\\\foo.txt", "dateModified": "2024-01-05T15:30:00Z", "size": 1024},
      {"path": "C:\\\\bar.txt", "dateModified": "2024-01-10T08:00:00Z", "size": 2048}
    ]
    ''';

  List<dynamic> decodedJson1 = jsonDecode(jsonData1);
  List<FileSystemEntity> initialFiles1 = decodedJson1.map<FileSystemEntity>((item) {
    return File(
      item['path'] as String,
      DateTime.parse(item['dateModified'] as String),
      item['size'] as int,
    );
  }).toList();

  // Simulate loading from JSON for the second tab
  String jsonData2 = '''
    [
      {"path": "D:\\\\image.jpg", "dateModified": "2024-02-15T10:00:00Z", "size": 5242880},
      {"path": "D:\\\\document.pdf", "dateModified": "2024-02-20T14:45:00Z", "size": 2097152}
    ]
    ''';

  List<dynamic> decodedJson2 = jsonDecode(jsonData2);
  List<FileSystemEntity> initialFiles2 = decodedJson2.map<FileSystemEntity>((item) {
    return File(
      item['path'] as String,
      DateTime.parse(item['dateModified'] as String),
      item['size'] as int,
    );
  }).toList();

  // Simulate loading from JSON for the third tab
  String jsonData3 = '''
    [
      {"path": "E:\\\\music.mp3", "dateModified": "2024-03-01T16:00:00Z", "size": 10485760},
      {"path": "E:\\\\video.mp4", "dateModified": "2024-03-05T09:15:00Z", "size": 26214400}
    ]
    ''';

  List<dynamic> decodedJson3 = jsonDecode(jsonData3);
  List<FileSystemEntity> initialFiles3 = decodedJson3.map<FileSystemEntity>((item) {
    return File(
      item['path'] as String,
      DateTime.parse(item['dateModified'] as String),
      item['size'] as int,
    );
  }).toList();

  final initialTabs = [
    FileExplorerData(initialFiles: initialFiles1),
    FileExplorerData(initialFiles: initialFiles2),
    FileExplorerData(initialFiles: initialFiles3),
  ];

  runApp(
    ChangeNotifierProvider<MultiFileExplorerData>(
      create: (context) => MultiFileExplorerData(tabs: initialTabs),
      builder: (context, child) => const MyApp(),
    ),
  );
}

class MultiFileExplorerData extends ChangeNotifier {
  List<FileExplorerData> tabs;
  int selectedTabIndex = 0;

  MultiFileExplorerData({required this.tabs});

  void addTab() {
    tabs.add(FileExplorerData(initialFiles: []));
    selectedTabIndex = tabs.length - 1;
    notifyListeners();
  }

  void selectTab(int index) {
    selectedTabIndex = index;
    notifyListeners();
  }

  FileExplorerData get currentTab => tabs[selectedTabIndex];
}

class FileExplorerData extends ChangeNotifier {
  List<FileSystemEntity> currentDirectoryContents = [];
  SortColumn sortColumn = SortColumn.name;
  bool sortAscending = true;

  FileExplorerData({required List<FileSystemEntity> initialFiles})
      : currentDirectoryContents = initialFiles {
    sortDirectoryContents();
  }

  void updateFiles(List<FileSystemEntity> newFiles) {
    currentDirectoryContents = newFiles;
    sortDirectoryContents();
    notifyListeners();
  }

  void sortDirectoryContents() {
    currentDirectoryContents.sort((a, b) {
      int result = 0;
      switch (sortColumn) {
        case SortColumn.name:
          result = a.name.compareTo(b.name);
          break;
        case SortColumn.dateModified:
          result = a.dateModified.compareTo(b.dateModified);
          break;
        case SortColumn.size:
          result = a.size.compareTo(b.size);
          break;
      }
      return sortAscending ? result : -result;
    });
    notifyListeners();
  }

  void setSortColumn(SortColumn column) {
    if (sortColumn == column) {
      // Toggle ascending/descending if the same column is selected
      sortAscending = !sortAscending;
    } else {
      sortColumn = column;
      sortAscending = true; // Default to ascending for a new column
    }
    sortDirectoryContents();
    notifyListeners();
  }
}

enum SortColumn {
  name,
  dateModified,
  size,
}

// Define abstract class for file system entities
abstract class FileSystemEntity {
  final String path;
  final DateTime dateModified;
  final int size;

  FileSystemEntity(this.path, this.dateModified, this.size);

  String get name => path.split('\\').last.isNotEmpty ? path.split('\\').last : path;
}

// Define file class
class File extends FileSystemEntity {
  File(super.path, super.dateModified, super.size);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'File Explorer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MultiFileExplorer(),
    );
  }
}

class MultiFileExplorer extends StatefulWidget {
  const MultiFileExplorer({super.key});

  @override
  State<MultiFileExplorer> createState() => _MultiFileExplorerState();
}

class _MultiFileExplorerState extends State<MultiFileExplorer> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final multiFileExplorerData = Provider.of<MultiFileExplorerData>(context, listen: false);
    _tabController = TabController(length: multiFileExplorerData.tabs.length, vsync: this);
    _tabController.addListener(() {
      Provider.of<MultiFileExplorerData>(context, listen: false).selectTab(_tabController.index);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final multiFileExplorerData = Provider.of<MultiFileExplorerData>(context);
    if (_tabController.length != multiFileExplorerData.tabs.length) {
      // Recreate the TabController when the number of tabs changes.
      _tabController.dispose();
      _tabController = TabController(length: multiFileExplorerData.tabs.length, vsync: this);
      _tabController.addListener(() {
        Provider.of<MultiFileExplorerData>(context, listen: false).selectTab(_tabController.index);
      });
      _tabController.index = multiFileExplorerData.selectedTabIndex;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final multiFileExplorerData = Provider.of<MultiFileExplorerData>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Multi File Explorer'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: List<Widget>.generate(
            multiFileExplorerData.tabs.length,
            (index) => Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tab ${index + 1}'),
                ],
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => multiFileExplorerData.addTab(),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: List<Widget>.generate(
          multiFileExplorerData.tabs.length,
          (index) => ChangeNotifierProvider<FileExplorerData>.value(
            value: multiFileExplorerData.tabs[index],
            child: const FileExplorer(),
          ),
        ),
      ),
    );
  }
}

class FileExplorer extends StatelessWidget {
  const FileExplorer({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Column(
        children: [
          FileListHeader(),
          Expanded(
            child: FileList(),
          ),
        ],
      ),
    );
  }
}

class FileListHeader extends StatelessWidget {
  const FileListHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildHeaderItem(context, 'Name', SortColumn.name, flex: 3),
        const VerticalDivider(width: 1, color: Colors.grey),
        _buildHeaderItem(context, 'Date Modified', SortColumn.dateModified, flex: 2),
        const VerticalDivider(width: 1, color: Colors.grey),
        _buildHeaderItem(context, 'Size', SortColumn.size, flex: 1),
      ],
    );
  }

  Widget _buildHeaderItem(BuildContext context, String title, SortColumn column, {int flex = 1}) {
    final fileExplorerData = Provider.of<FileExplorerData>(context);
    bool isSortedColumn = fileExplorerData.sortColumn == column;
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: () => fileExplorerData.setSortColumn(column),
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
                Icon(fileExplorerData.sortAscending ? Icons.arrow_drop_up : Icons.arrow_drop_down),
            ],
          ),
        ),
      ),
    );
  }
}

class FileList extends StatelessWidget {
  const FileList({super.key});

  @override
  Widget build(BuildContext context) {
    final fileExplorerData = Provider.of<FileExplorerData>(context);

    return ListView.separated(
      itemCount: fileExplorerData.currentDirectoryContents.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final entity = fileExplorerData.currentDirectoryContents[index];
        return FileListItem(entity: entity);
      },
    );
  }
}

class FileListItem extends StatelessWidget {
  const FileListItem({super.key, required this.entity});

  final FileSystemEntity entity;

  @override
  Widget build(BuildContext context) {
    const IconData icon = Icons.insert_drive_file;
    const String type = 'File';
    final String sizeString = _formatSize(entity.size);

    return InkWell(
      onTap: () {
        // Handle file opening (e.g., show a dialog).
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('File Selected'),
            content: Text('You selected: ${entity.path}'),
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
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Icon(icon),
                  const SizedBox(width: 8),
                  Text(entity.name),
                ],
              ),
            ),
          ),
          const VerticalDivider(width: 1, color: Colors.grey),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(_formatDate(entity.dateModified)),
            ),
          ),
          const VerticalDivider(width: 1, color: Colors.grey),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(sizeString),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month}-${date.day} ${date.hour}:${date.minute}';
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes bytes';
    } else if (bytes < 1024 * 1024) {
      double kb = bytes / 1024;
      return '${kb.toStringAsFixed(2)} KB';
    } else {
      double mb = bytes / (1024 * 1024);
      return '${mb.toStringAsFixed(2)} MB';
    }
  }
}
