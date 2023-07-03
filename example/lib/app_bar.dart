import 'package:flutter/material.dart';

class SettingMenu extends StatelessWidget {
  const SettingMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      // action button
      icon: const Icon(Icons.settings),
      onPressed: () {
        debugPrint('Click Menu Setting');
      },
    );
  }
}

class VideoAppBar extends StatelessWidget implements PreferredSizeWidget {
  const VideoAppBar({Key? key, this.title, this.actions}) : super(key: key);

  final String? title;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: preferredSize,
      child: AppBar(
        title: Text(title ?? ''),
        actions: actions,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(45.0);
}
