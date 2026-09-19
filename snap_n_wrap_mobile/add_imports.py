import re
c = open('lib/screens/dynamic_configurator_screen.dart', 'r', encoding='utf-8').read()
c = c.replace("import 'edit_profile_screen.dart';", "import 'edit_profile_screen.dart';\nimport 'editor_screen.dart';\nimport '../providers/editor_provider.dart';")
open('lib/screens/dynamic_configurator_screen.dart', 'w', encoding='utf-8').write(c)

c2 = open('lib/screens/polaroid_configurator_screen.dart', 'r', encoding='utf-8').read()
c2 = c2.replace("import 'edit_profile_screen.dart';", "import 'edit_profile_screen.dart';\nimport 'editor_screen.dart';\nimport '../providers/editor_provider.dart';")
open('lib/screens/polaroid_configurator_screen.dart', 'w', encoding='utf-8').write(c2)
