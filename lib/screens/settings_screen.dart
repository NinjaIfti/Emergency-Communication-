import 'package:flutter/material.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _usernameController = TextEditingController();
  bool _autoConnect = true;

  @override
  void initState() {
    super.initState();
    _usernameController.text = 'User';
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  void _clearHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Message History?'),
        content: const Text(
          'This will permanently delete all messages. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Message history cleared'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.white,
      ),
      body: ListView(
        children: [
          // Profile Section
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingLarge),
            color: AppColors.lightGrey,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.secondary,
                  child: Icon(
                    Icons.person,
                    size: 50,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingMedium),
                Text(
                  _usernameController.text,
                  style: AppTextStyles.heading2,
                ),
              ],
            ),
          ),

          // Account Section
          _SectionHeader(title: 'Account'),
          ListTile(
            leading: Icon(Icons.person_outline, color: AppColors.secondary),
            title: const Text('Username'),
            subtitle: Text(_usernameController.text),
            trailing: const Icon(Icons.edit),
            onTap: () {
              _showEditUsernameDialog();
            },
          ),
          const Divider(),

          // Connection Settings
          _SectionHeader(title: 'Connection'),
          SwitchListTile(
            secondary: Icon(Icons.bluetooth, color: AppColors.secondary),
            title: const Text('Auto-connect'),
            subtitle: const Text('Automatically connect to nearby devices'),
            value: _autoConnect,
            onChanged: (value) {
              setState(() {
                _autoConnect = value;
              });
            },
            activeColor: AppColors.success,
          ),
          ListTile(
            leading: Icon(Icons.wifi, color: AppColors.secondary),
            title: const Text('WiFi Direct'),
            subtitle: const Text('Enable WiFi Direct mesh networking'),
            trailing: Switch(
              value: true,
              onChanged: (value) {},
              activeColor: AppColors.success,
            ),
          ),
          const Divider(),

          // Data Section
          _SectionHeader(title: 'Data & Storage'),
          ListTile(
            leading: Icon(Icons.delete_outline, color: AppColors.primary),
            title: const Text('Clear Message History'),
            subtitle: const Text('Delete all messages'),
            onTap: _clearHistory,
          ),
          ListTile(
            leading: Icon(Icons.storage, color: AppColors.secondary),
            title: const Text('Storage Usage'),
            subtitle: const Text('2.3 MB used'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          ),
          const Divider(),

          // About Section
          _SectionHeader(title: 'About'),
          ListTile(
            leading: Icon(Icons.info_outline, color: AppColors.secondary),
            title: const Text('Version'),
            subtitle: const Text('1.0.0'),
          ),
          ListTile(
            leading: Icon(Icons.bug_report, color: AppColors.warning),
            title: const Text('Debug & Monitoring'),
            subtitle: const Text('View logs, network stats, and debug info'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.debug);
            },
          ),
          ListTile(
            leading: Icon(Icons.description_outlined, color: AppColors.secondary),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.gavel, color: AppColors.secondary),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          AboutListTile(
            icon: Icon(Icons.help_outline, color: AppColors.secondary),
            applicationName: 'Emergency Comm',
            applicationVersion: '1.0.0',
            applicationLegalese: '© 2025 Emergency Communication System',
            child: const Text('About App'),
          ),
        ],
      ),
    );
  }

  void _showEditUsernameDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Username'),
        content: TextField(
          controller: _usernameController,
          decoration: const InputDecoration(
            labelText: 'Username',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {});
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Username updated'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.paddingMedium,
        AppSizes.paddingLarge,
        AppSizes.paddingMedium,
        AppSizes.paddingSmall,
      ),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.caption.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.secondary,
        ),
      ),
    );
  }
}


