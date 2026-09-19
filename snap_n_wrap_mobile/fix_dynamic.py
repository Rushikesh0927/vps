def fix():
    c = open('lib/screens/dynamic_configurator_screen.dart', 'r', encoding='utf-8').read()
    c = c.replace('widget.config.coverImageUrl', 'widget.config.heroImage')
    
    # Add initialSelection to constructor
    old_const = "  const DynamicConfiguratorScreen({super.key, required this.config});"
    new_const = "  final List<int>? initialSelection;\n  const DynamicConfiguratorScreen({super.key, required this.config, this.initialSelection});"
    c = c.replace(old_const, new_const)
    
    # Init _selectedOptions using initialSelection
    old_init = "_selectedOptions = List.filled(widget.config.steps.length, 0);"
    new_init = "if (widget.initialSelection != null) {\n      _selectedOptions = List.from(widget.initialSelection!);\n    } else {\n      _selectedOptions = List.filled(widget.config.steps.length, 0);\n    }"
    c = c.replace(old_init, new_init)
    
    open('lib/screens/dynamic_configurator_screen.dart', 'w', encoding='utf-8').write(c)

fix()
