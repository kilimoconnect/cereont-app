import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import 'dashboard_screen.dart';
import 'chat_screen.dart';
import 'inbox_screen.dart';
import 'tasks_screen.dart';
import 'memory/memory_hub_screen.dart';
import 'search_screen.dart';

/// Root scaffold with the primary bottom navigation.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  final _pages = const [
    DashboardScreen(),
    ChatScreen(),
    InboxScreen(),
    TasksScreen(),
    MemoryHubScreen(),
  ];

  void goToTab(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final unread = context.select<AppState, int>((s) => s.unreadEmails);
    final openTasks = context.select<AppState, int>((s) => s.openTasks.length);

    return HomeNavigation(
      goToTab: goToTab,
      child: Scaffold(
        body: IndexedStack(index: _index, children: _pages),
        floatingActionButton: _index == 0
            ? FloatingActionButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const SearchScreen())),
                child: const Icon(Icons.search),
              )
            : null,
        bottomNavigationBar: NavigationBarTheme(
          data: NavigationBarThemeData(
            labelTextStyle: WidgetStateProperty.all(
                const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          ),
          child: NavigationBar(
            selectedIndex: _index,
            height: 66,
            onDestinationSelected: goToTab,
            destinations: [
              const NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: 'Command'),
              const NavigationDestination(
                  icon: Icon(Icons.auto_awesome_outlined),
                  selectedIcon: Icon(Icons.auto_awesome),
                  label: 'Assistant'),
              NavigationDestination(
                  icon: _Badged(Icons.inbox_outlined, unread),
                  selectedIcon: _Badged(Icons.inbox, unread),
                  label: 'Inbox'),
              NavigationDestination(
                  icon: _Badged(Icons.checklist_outlined, openTasks,
                      neutral: true),
                  selectedIcon: _Badged(Icons.checklist, openTasks,
                      neutral: true),
                  label: 'Tasks'),
              const NavigationDestination(
                  icon: Icon(Icons.hub_outlined),
                  selectedIcon: Icon(Icons.hub),
                  label: 'Memory'),
            ],
          ),
        ),
      ),
    );
  }
}

/// Inherited helper so any descendant can jump to a primary tab.
class HomeNavigation extends InheritedWidget {
  final void Function(int) goToTab;
  const HomeNavigation(
      {super.key, required this.goToTab, required super.child});

  static HomeNavigation? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<HomeNavigation>();

  @override
  bool updateShouldNotify(HomeNavigation oldWidget) => false;
}

class _Badged extends StatelessWidget {
  final IconData icon;
  final int count;
  final bool neutral;
  const _Badged(this.icon, this.count, {this.neutral = false});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return Icon(icon);
    return Badge(
      label: Text('$count'),
      backgroundColor:
          neutral ? Theme.of(context).colorScheme.secondary : null,
      child: Icon(icon),
    );
  }
}
