import 'package:sdui_core/src/model/content_spec.dart';
import 'package:sdui_core/src/model/prop_value.dart';
import 'package:sdui_core/src/model/sdui_node.dart';
import 'package:sdui_core/src/schema/spec_version.dart';

int requiredSpecVersion(ContentSpec spec) {
  final root = spec.root;
  final usesTypedForms =
      _hasTypedForm(spec.safeArea) || (root != null && _treeHasTypedForm(root));
  return usesTypedForms ? kTypedPropValuesSpecVersion : kOldestSpecVersion;
}

/// Devolve a mesma instância quando a versão já está certa, para não sujar o
/// undo nem o estado de "salvo" do editor.
ContentSpec withRequiredSpecVersion(ContentSpec spec) {
  final version = requiredSpecVersion(spec);
  if (version == spec.specVersion) return spec;
  return spec.copyWith(specVersion: version);
}

bool _treeHasTypedForm(SduiNode node) {
  if (_hasTypedForm(node.properties)) return true;
  final child = node.child;
  if (child != null && _treeHasTypedForm(child)) return true;
  return node.children.any(_treeHasTypedForm);
}

bool _hasTypedForm(Map<String, dynamic> props) =>
    props.values.any(PropValue.isTypedForm);
