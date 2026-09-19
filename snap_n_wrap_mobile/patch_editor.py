def fix_editor(filepath):
    c = open(filepath, 'r', encoding='utf-8').read()
    
    c = c.replace('padding: const EdgeInsets.all(20.0),', 'padding: const EdgeInsets.all(12.0),')
    
    old_dots = """                              Row(
                                children: editorState.photos.asMap().entries.map((e) {
                                  final isActive = e.key == activeIdx;
                                  return Container(
                                    width: isActive ? 16 : 8,
                                    height: 8,
                                    margin: const EdgeInsets.symmetric(horizontal: 2),
                                    decoration: BoxDecoration(
                                      color: isActive ? (isPhotobook ? const Color(0xFF4C1D95) : const Color(0xFF3B82F6)) : Colors.white38,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  );
                                }).toList(),
                              ),"""
    
    new_dots = """                              Builder(builder: (context) {
                                int start = activeIdx - 2;
                                int end = activeIdx + 2;
                                int total = editorState.photos.length;
                                if (start < 0) { end += start.abs(); start = 0; }
                                if (end >= total) { start -= (end - total + 1); end = total - 1; }
                                start = start.clamp(0, total);
                                end = end.clamp(0, total - 1);
                                
                                List<Widget> dotWidgets = [];
                                for (int i = start; i <= end; i++) {
                                  final isActive = i == activeIdx;
                                  dotWidgets.add(Container(
                                    width: isActive ? 16 : 8,
                                    height: 8,
                                    margin: const EdgeInsets.symmetric(horizontal: 2),
                                    decoration: BoxDecoration(
                                      color: isActive ? (isPhotobook ? const Color(0xFF4C1D95) : const Color(0xFF3B82F6)) : Colors.white38,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ));
                                }
                                return Row(children: dotWidgets);
                              }),"""
    
    if old_dots in c:
        c = c.replace(old_dots, new_dots)
        print("Patched dots!")
    else:
        print("Dots pattern not found!")
        
    open(filepath, 'w', encoding='utf-8').write(c)

fix_editor('lib/screens/editor_screen.dart')
