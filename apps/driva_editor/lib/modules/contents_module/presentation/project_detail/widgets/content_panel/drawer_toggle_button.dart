import 'package:flutter/material.dart';

class DrawerToggleButton extends StatelessWidget {
  const DrawerToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Abrir categorias',
      onPressed: () => Scaffold.of(context).openDrawer(),
      icon: const Icon(Icons.menu),
    );
  }
}
