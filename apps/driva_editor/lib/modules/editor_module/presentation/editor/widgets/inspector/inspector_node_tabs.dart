import 'package:driva_editor/core/theme/app_sizes.dart';
import 'package:flutter/material.dart';

/// A aba ativa mora só neste `State`: ele sobrevive à troca de um nó para
/// outro, que é o que se pede; persistir no layout não se paga.
class InspectorNodeTabs extends StatefulWidget {
  const InspectorNodeTabs({
    required this.properties,
    required this.actions,
    super.key,
  });

  final Widget properties;

  final Widget actions;

  @override
  State<InspectorNodeTabs> createState() => _InspectorNodeTabsState();
}

class _InspectorNodeTabsState extends State<InspectorNodeTabs>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 2,
    vsync: this,
  );

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Propriedades', height: AppSizes.panelTabHeight),
            Tab(text: 'Ações', height: AppSizes.panelTabHeight),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [widget.properties, widget.actions],
          ),
        ),
      ],
    );
  }
}
