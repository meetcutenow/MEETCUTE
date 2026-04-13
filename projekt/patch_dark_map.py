
import sys
import os

OLD = "urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',"
NEW = """urlTemplate: ThemeState.instance.isDark
                    ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                    : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',"""

files = [
    'lib/screens/home_screen.dart',
    'lib/screens/events_nearby.dart',
]

for path in files:
    if not os.path.exists(path):
        print(f"SKIP (not found): {path}")
        continue
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    count = content.count(OLD)
    if count == 0:
        print(f"SKIP (already patched or no match): {path}")
        continue
    patched = content.replace(OLD, NEW)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(patched)
    print(f"OK: {path} — {count} zamjena(e)")

print("Gotovo!")