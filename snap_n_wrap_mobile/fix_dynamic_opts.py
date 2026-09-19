def fix():
    c = open('lib/screens/dynamic_configurator_screen.dart', 'r', encoding='utf-8').read()
    
    old_loop = "final option = step.options[optIndex];"
    new_loop = "final optionsList = step.dynamicOptions != null ? step.dynamicOptions!(_selectedOptions) : step.options;\n                                    final option = optionsList[optIndex];"
    c = c.replace(old_loop, new_loop)
    
    old_len = "children: List.generate(step.options.length, (optIndex) {"
    new_len = "children: List.generate(step.dynamicOptions != null ? step.dynamicOptions!(_selectedOptions).length : step.options.length, (optIndex) {"
    c = c.replace(old_len, new_len)
    
    old_price = "price += widget.config.steps[i].options[_selectedOptions[i]!].priceDelta;"
    new_price = "final optionsList = widget.config.steps[i].dynamicOptions != null ? widget.config.steps[i].dynamicOptions!(_selectedOptions) : widget.config.steps[i].options;\n          price += optionsList[_selectedOptions[i]!].priceDelta;"
    c = c.replace(old_price, new_price)
    
    old_price2 = "price += widget.config.steps[i].options[0].priceDelta;"
    new_price2 = "final optionsList = widget.config.steps[i].dynamicOptions != null ? widget.config.steps[i].dynamicOptions!(_selectedOptions) : widget.config.steps[i].options;\n           price += optionsList[0].priceDelta;"
    c = c.replace(old_price2, new_price2)

    open('lib/screens/dynamic_configurator_screen.dart', 'w', encoding='utf-8').write(c)

fix()
