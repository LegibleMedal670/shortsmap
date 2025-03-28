import 'package:flutter/material.dart';

class PlanAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showAddButton;
  final VoidCallback? onAddPressed;
  final List<Widget>? actions;
  final bool centerTitle;
  final PreferredSizeWidget? bottom;
  final Widget? leading;

  const PlanAppBar({
    Key? key,
    required this.title,
    this.showAddButton = false,
    this.onAddPressed,
    this.actions,
    this.centerTitle = true,
    this.bottom,
    this.leading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> finalActions = actions ?? [];
    
    if (showAddButton) {
      finalActions.add(
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: onAddPressed,
        ),
      );
    }

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Text(
        title,
        style: const TextStyle(color: Colors.black),
      ),
      centerTitle: centerTitle,
      iconTheme: const IconThemeData(color: Colors.black),
      actions: finalActions,
      bottom: bottom,
      leading: leading,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );
}