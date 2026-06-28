import os
import re

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    new_lines = []
    for line in lines:
        stripped = line.strip()
        if stripped.startswith('//'):
            lower_line = stripped.lower()
            
            # Conditions to keep a comment
            keep = False
            if '──' in stripped:
                keep = True
            elif 'ignore:' in lower_line:
                keep = True
            elif 'TODO' in stripped:
                keep = True
            else:
                # check if it's a structural label (short comment with UI keywords)
                words = stripped[2:].strip().split()
                if len(words) <= 8:
                    keywords = ['widget', 'container', 'button', 'section', 'header', 'step', 'row', 'column', 'card', 'list', 'text', 'icon', 'image', 'appbar', 'body', 'fab', 'floating', 'dialog', 'bottom']
                    if any(kw in lower_line for kw in keywords):
                        keep = True
            
            if keep:
                new_lines.append(line)
            else:
                # drop comment
                pass
        else:
            new_lines.append(line)
            
    # Cleanup consecutive blank lines
    final_lines = []
    blank_count = 0
    for line in new_lines:
        if line.strip() == '':
            blank_count += 1
            if blank_count > 1:
                continue
        else:
            blank_count = 0
        final_lines.append(line)
        
    with open(filepath, 'w', encoding='utf-8') as f:
        f.writelines(final_lines)

for root, dirs, files in os.walk(r'd:\FYP\urbanpulse_flutter_final\urbanpulse\lib'):
    for file in files:
        if file.endswith('.dart'):
            process_file(os.path.join(root, file))
print('Done!')
