import re
c = open('lib/screens/products_screen.dart', 'r', encoding='utf-8').read()
c = c.replace("import 'dynamic_configurator_screen.dart';", "import 'dynamic_configurator_screen.dart';\nimport 'polaroid_configurator_screen.dart';")

old_nav = """          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DynamicConfiguratorScreen(
                config: productConfigs[categoryKey]!,
                initialSelection: initialSelection,
              ),
            ),
          );"""

new_nav = """          if (categoryKey == 'polaroid_prints') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PolaroidConfiguratorScreen(),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DynamicConfiguratorScreen(
                  config: productConfigs[categoryKey]!,
                  initialSelection: initialSelection,
                ),
              ),
            );
          }"""

c = c.replace(old_nav, new_nav)
open('lib/screens/products_screen.dart', 'w', encoding='utf-8').write(c)
