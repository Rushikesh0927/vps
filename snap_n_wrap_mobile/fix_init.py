def run():
    c = open('lib/screens/dynamic_configurator_screen.dart', 'r', encoding='utf-8').read()
    
    # Replace List<int?> with List<int> where appropriate, or just fix initialization
    old_init = "List<int?> _selectedOptions = [];"
    new_init = "List<int?> _selectedOptions = [];"
    c = c.replace(old_init, new_init)
    
    old_init_block = """  @override
  void initState() {
    super.initState();
    _selectedOptions = List.filled(widget.config.steps.length, null);
    if (widget.initialSelection != null) {
      widget.initialSelection!.forEach((stepIndex, optionIndex) {
        if (stepIndex >= 0 &&
            stepIndex < _selectedOptions.length &&
            optionIndex >= 0 &&
            optionIndex < widget.config.steps[stepIndex].options.length) {
          _selectedOptions[stepIndex] = optionIndex;
        }
      });
    } else {
      if (widget.config.steps.isNotEmpty) {
        _selectedOptions[0] = 0;
      }
    }
    _calculatePrice();
  }"""
  
    new_init_block = """  @override
  void initState() {
    super.initState();
    _selectedOptions = List.generate(widget.config.steps.length, (index) => 0);
    if (widget.initialSelection != null) {
      widget.initialSelection!.forEach((stepIndex, optionIndex) {
        if (stepIndex >= 0 &&
            stepIndex < _selectedOptions.length &&
            optionIndex >= 0 &&
            optionIndex < widget.config.steps[stepIndex].options.length) {
          _selectedOptions[stepIndex] = optionIndex;
        }
      });
    }
    _calculatePrice();
  }"""
    c = c.replace(old_init_block, new_init_block)
    
    # And fix _isAllSelected
    old_all_selected = """  bool _isAllSelected() {
    for (var opt in _selectedOptions) {
      if (opt == null) return false;
    }
    return true;
  }"""
    new_all_selected = """  bool _isAllSelected() {
    return true;
  }"""
    c = c.replace(old_all_selected, new_all_selected)
    
    open('lib/screens/dynamic_configurator_screen.dart', 'w', encoding='utf-8').write(c)

run()
