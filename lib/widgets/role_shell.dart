import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import 'common.dart';

class NavItem {
  final IconData icon;
  final String label;
  final Widget page;
  const NavItem(this.icon, this.label, this.page);
}

/// Lets pages inside the shell switch tabs (e.g. "Post a job" -> "My jobs").
class ShellScope extends InheritedWidget {
  final void Function(int) goTo;
  const ShellScope({super.key, required this.goTo, required super.child});

  static ShellScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellScope>()!;

  @override
  bool updateShouldNotify(ShellScope oldWidget) => false;
}

class RoleShell extends StatefulWidget {
  final Role role;
  final List<NavItem> items;
  const RoleShell({super.key, required this.role, required this.items});

  @override
  State<RoleShell> createState() => _RoleShellState();
}

class _RoleShellState extends State<RoleShell> {
  int index = 0;

  void goTo(int i) => setState(() => index = i);

  void _logout() {
    app.logout();
    Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
  }

  String get _roleLabel => switch (widget.role) {
        Role.user => 'Customer portal',
        Role.worker => 'Worker portal',
        Role.admin => 'Admin console',
      };

  String get _who => switch (widget.role) {
        Role.user => app.userName,
        Role.worker => app.me.name,
        Role.admin => app.adminName,
      };

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 900;
    final page = KeyedSubtree(key: ValueKey(index), child: widget.items[index].page);

    if (!wide) {
      return ShellScope(
        goTo: goTo,
        child: Scaffold(
          body: page,
          bottomNavigationBar: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: goTo,
            destinations: [
              for (final i in widget.items)
                NavigationDestination(icon: Icon(i.icon), label: i.label),
            ],
          ),
        ),
      );
    }

    return ShellScope(
      goTo: goTo,
      child: Scaffold(
        body: Row(
          children: [
            NavigationRail(
              backgroundColor: C.navy,
              extended: true,
              minExtendedWidth: 232,
              selectedIndex: index,
              onDestinationSelected: goTo,
              indicatorColor: C.railSelected,
              selectedIconTheme: const IconThemeData(color: Colors.white),
              unselectedIconTheme: const IconThemeData(color: C.onDarkMuted),
              selectedLabelTextStyle:
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              unselectedLabelTextStyle: const TextStyle(color: C.onDarkMuted),
              leading: Padding(
                padding: const EdgeInsets.fromLTRB(8, 28, 8, 24),
                child: SizedBox(
                  width: 200,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [
                        Icon(Icons.handyman_rounded, color: Colors.white, size: 26),
                        SizedBox(width: 10),
                        Text('FixIt',
                            style: TextStyle(
                                color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                      ]),
                      const SizedBox(height: 4),
                      Text(_roleLabel, style: const TextStyle(color: C.onDarkMuted)),
                    ],
                  ),
                ),
              ),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                    child: SizedBox(
                      width: 208,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(color: C.railSelected),
                          Row(children: [
                            Avatar(_who, radius: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(_who,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white, fontWeight: FontWeight.w600)),
                            ),
                          ]),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _logout,
                            icon: const Icon(Icons.logout_rounded, color: C.onDarkMuted, size: 20),
                            label: const Text('Log out / switch role',
                                style: TextStyle(color: C.onDarkMuted)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              destinations: [
                for (final i in widget.items)
                  NavigationRailDestination(icon: Icon(i.icon), label: Text(i.label)),
              ],
            ),
            Expanded(child: page),
          ],
        ),
      ),
    );
  }
}
