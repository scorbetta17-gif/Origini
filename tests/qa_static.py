from pathlib import Path
import re, sys
root=Path(__file__).resolve().parents[1]
scripts={p.name:p.read_text(encoding='utf-8') for p in (root/'src').glob('*.gd')}
assert len(scripts)>=6, 'script GDScript mancanti'
main=scripts['main.gd']; cell=scripts['cell_visual.gd']; line=scripts['lineage_view.gd']; joy=scripts['virtual_joystick.gd']
tests=[]
def test(name,ok):
    assert ok, name
    tests.append(name)
for path in (root/'scenes').glob('*.tscn'):
    for target in re.findall(r'path="res://([^"]+)"',path.read_text(encoding='utf-8')):
        test(f'{path.name}: {target}',(root/target).is_file())
for file,code in scripts.items():
    for target in re.findall(r'preload\("res://([^"]+)"\)',code):
        test(f'{file} -> {target}',(root/target).is_file())
    functions=re.findall(r'^func\s+(\w+)\s*\(',code,re.M)
    test(f'funzioni univoche {file}',len(functions)==len(set(functions)))
    test(f'indentazione {file}', all((len(l)-len(l.lstrip(' ')))%4==0 for l in code.splitlines() if l.startswith(' ')))
for symbol in ['CellVisual','MutationTree','LineageView','OriginiJoystick']:
    test(f'class_name {symbol}',sum(f'class_name {symbol}' in code for code in scripts.values())==1)
test('origine RNA senza motori',all(x in main for x in ['"dna": false','"archaella": 0','"flagella": 0']))
test('RNA mono filamento', 'var strands: int = 2 if dna else 1' in cell)
test('protocellula senza nucleo',not any(x in cell.lower() for x in ['mitochondrion','nucleus','golgi']))
test('touch joystick dedicato','func _input(event: InputEvent)' in joy and 'signal direction_changed' in joy)
test('tocco vs mouse sintetico','touch_seen' in joy)
test('scissione su biomassa', 'float(e["biomass"]) >= 64.0' in main and 'float(e["energy"]) >= 28.0' in main)
test('scissione non richiede HP','hp' not in main.split('func _can_divide()')[1].split('func _divide_pressed()')[0])
test('HP individuali NPC','target["hp"] = float(target["hp"])-damage' in main)
test('morte distinta da scissione','"divisa" if cause == "scissione" else "estinta"' in main)
test('genealogia con cause e genitori','"cause":cause' not in main and 'entry["cause"] = cause' in main and '"parent":parent' in main)
test('linee esterne con origine indipendente','_create_entity(new_id,"",0,"bacteria"' in main)
test('cap risorse 110%', 'float(NEED[kind])*1.1' in main and 'float(NEED["biomass"])*1.1' in main)
test('no DNA extracellular iniziale','_create_nutrient("detritus"' in main and '_new_game()' in main)
test('rami con riserve separate','_cache_current()' in main and '_activate_lineage(id: String)' in main)
test('mutazioni e cellule figlie','_mutated_traits(parent["traits"]' in main)
test('genealogia una sola schermata','_layout_branch(' in line and 'func _draw()' in line)
test('salvataggio dati cellulari','"version":67' in main and '"genealogy":genealogy' in main)
test('renderer compatibile',(root/'project.godot').read_text().count('gl_compatibility')>=1)
test('smoke test incluso',(root/'tests/smoke.gd').exists())
print(f'PASS {len(tests)} controlli statici. ATTENZIONE: non e una prova di esecuzione Godot.')
