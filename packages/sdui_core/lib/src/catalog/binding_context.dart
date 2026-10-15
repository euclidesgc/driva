enum BindingContext {
  page('página'),
  component('componente'),
  action('ação');

  const BindingContext(this.label);

  final String label;
}
