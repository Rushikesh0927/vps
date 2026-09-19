def fix():
    c = open('lib/screens/dynamic_configurator_screen.dart', 'r', encoding='utf-8').read()
    
    old_const = "  final List<int>? initialSelection;\n  const DynamicConfiguratorScreen({super.key, required this.config, this.initialSelection});"
    new_const = "  final Map<int, int>? initialSelection;\n  const DynamicConfiguratorScreen({super.key, required this.config, this.initialSelection});"
    c = c.replace(old_const, new_const)
    
    old_init = "if (widget.initialSelection != null) {\n      _selectedOptions = List.from(widget.initialSelection!);\n    } else {\n      _selectedOptions = List.filled(widget.config.steps.length, 0);\n    }"
    new_init = "_selectedOptions = List.filled(widget.config.steps.length, 0);\n    if (widget.initialSelection != null) {\n      widget.initialSelection!.forEach((key, value) {\n        if (key < _selectedOptions.length) {\n          _selectedOptions[key] = value;\n        }\n      });\n    }"
    c = c.replace(old_init, new_init)
    
    open('lib/screens/dynamic_configurator_screen.dart', 'w', encoding='utf-8').write(c)

fix()
