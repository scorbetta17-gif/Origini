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
test('regressione runtime RNA e DNA presente', (root/'tests/cell_phenotype_smoke.gd').exists() and (root/'tests/blender_asset_smoke.gd').exists())
test('protocellula senza nucleo',not any(x in cell.lower() for x in ['mitochondrion','nucleus','golgi']))
test('touch joystick dedicato','func _input(event: InputEvent)' in joy and 'signal direction_changed' in joy)
test('tocco vs mouse sintetico','touch_seen' in joy)
test('scissione autonoma biologicamente regolata', 'float(e["biomass"]) >= 57.0' in main and 'float(e["energy"]) >= 23.0' in main and 'npc_population_cap' in main)
test('scissione richiede cellula viva, non HP pieni','if hp<=0.0:' in main.split('func _can_divide()')[1].split('func _divide_pressed()')[0])
test('HP individuali NPC','target["hp"] = float(target["hp"])-damage' in main)
test('morte distinta da scissione','"divisa" if cause == "scissione" else "estinta"' in main)
test('genealogia con cause e genitori','"cause":cause' not in main and 'entry["cause"] = cause' in main and '"parent":parent' in main)
test('linee esterne con origine indipendente','_create_entity(new_id,"",0,"bacteria"' in main)
test('cap risorse 112%', 'Physiology.reserve_cap(float(NEED[kind]))' in main and 'Physiology.reserve_cap(float(NEED["biomass"]))' in main)
test('no DNA extracellular iniziale','_create_nutrient("detritus"' in main and '_new_game()' in main)
test('rami con riserve separate','_cache_current()' in main and '_activate_lineage(id: String)' in main)
test('mutazioni e cellule figlie','_mutated_traits(parent["traits"]' in main)
test('genealogia una sola schermata','_layout_branch(' in line and 'func _draw()' in line)
test('salvataggio dati cellulari versionato','"version":71' in main and '"genealogy":genealogy' in main and '"phase1_progress":phase1_progress' in main and '"phase2_progress":phase2_progress' in main)
test('caricamento retrocompatibile','[67,70,71]' in main)
test('Fase 2 controller presente',(root/'src/phase_two_progress.gd').exists() and '_advance_phase_two(delta)' in main)
test('Fase 2 obiettivi completi','PhaseScript.objective_lines(phase2_progress)' in main and 'PhaseScript.inherit(' in main)
test('Fase 2 end-to-end test',(root/'tests/phase_two_smoke.gd').exists())
test('shaders visivi attivi',(root/'shaders/cell_membrane.gdshader').exists() and (root/'shaders/seafloor.gdshader').exists())
test('ambiente oceanico dedicato',(root/'src/primordial_ocean.gd').exists() and 'biome.call("setup",rng)' in main)
test('renderer compatibile',(root/'project.godot').read_text().count('gl_compatibility')>=1)
test('smoke test incluso',(root/'tests/smoke.gd').exists())

test('fase 1 popolazioni e campionamento',(root/'src/phase_one_progress.gd').exists() and 'PhaseOneScript.advance(' in main)
test('energia e motilita biologica',(root/'src/cell_physiology.gd').exists() and '_update_npc_motion(delta)' in main and 'Physiology.energy_step(' in main)
test('limiti crescita', 'Physiology.growth_scale(' in main)
test('albero con geni grandi e icone','major_locus(node_id:' in scripts['mutation_tree.gd'] and '_draw_major_icon(' in scripts['mutation_tree.gd'])
test('fasi visuali separate', '_open_phase_intro(1)' in main and '_open_phase_intro(2)' in main)
print(f'PASS {len(tests)} controlli statici. ATTENZIONE: non e una prova di esecuzione Godot.')
