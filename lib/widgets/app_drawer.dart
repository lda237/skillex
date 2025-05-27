import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          // Determine display name and email, handling null cases
          final String displayName = authProvider.user?.displayName ?? 'Guest';
          final String email = authProvider.user?.email ?? 'No email';
          final Widget accountHeader = (authProvider.user?.photoURL != null)
              ? UserAccountsDrawerHeader(
                  accountName: Text(displayName),
                  accountEmail: Text(email),
                  currentAccountPicture: CircleAvatar(
                    backgroundImage: NetworkImage(authProvider.user!.photoURL!),
                    backgroundColor: Colors.transparent,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                  ),
                )
              : UserAccountsDrawerHeader(
                  accountName: Text(displayName),
                  accountEmail: Text(email),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    child: Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'G',
                      style: TextStyle(fontSize: 40.0, color: Colors.white),
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                  ),
                );


          return ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              accountHeader,
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Home'),
                onTap: () {
                  Navigator.pop(context); // Close the drawer
                  Navigator.pushReplacementNamed(context, '/home');
                },
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Profile'),
                onTap: () {
                  Navigator.pop(context); // Close the drawer
                  Navigator.pushNamed(context, '/profile');
                },
              ),
              if (authProvider.isAdmin)
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings),
                  title: const Text('Admin Dashboard'),
                  onTap: () {
                    Navigator.pop(context); // Close the drawer
                    Navigator.pushNamed(context, '/adminAddContent');
                  },
                ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(context); // Close the drawer
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Settings not implemented yet')),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.exit_to_app),
                title: const Text('Logout'),
                onTap: () async {
                  // No need to pop context for the drawer here, 
                  // as the entire route stack below '/welcome' will be removed.
                  // final authProvider = Provider.of<AuthProvider>(context, listen: false); // Already available
                  await authProvider.signOut();
                  // Ensure context is still valid before navigating
                  if (Navigator.of(context).mounted) {
                    Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
