extends SceneTree
const G=preload("res://src/cell_genome.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
    root.size=Vector2i(720,1280);root.content_scale_size=root.size
    var g=load("res://scenes/Main.tscn").instantiate();root.add_child(g)
    await process_frame;g.set_process(false);g.journey.skip();g._layout_ui();g._refresh_hud()
    # Staged fixtures rendered by the real game, not human playtest evidence.
    g.player.position=Vector3(0,0,5);g._advance_niches(0)
    for ingredient in g.NEED: g.resources[ingredient]=g.NEED[ingredient]
    g.atp=90;g.cycle_age=35;g._divide_pressed();await create_timer(2.7).timeout
    for i in range(5):
        for id in g.entities.keys():
            if id!=g.player_id and not g.entities[id].external:
                g._divide_npc(id);break
    g.campaign.advance(20)
    g.camera.position=g.player.position+g.camera_offset;g.camera.look_at(g.player.position+Vector3(0,.55,0))
    g.campaign.open_map();await frame("map")
    g._close_overlay()
    var tr: Dictionary=g._base_traits()
    tr["evolution_capabilities"]={"bacteria":true,"prokaryotic_groups":true,"differentiated_groups":true}
    g.entities[g.player_id].branch="bacteria";g.entities[g.player_id].traits=tr
    var children: Array=[g.player_id]
    for i in range(3):
        var id: String="FIL-"+str(i)
        g._create_entity(id,g.player_id,2,"bacteria",tr,Vector3((i+1)*1.65,0,0),false);children.append(id)
    g.collectives.division("fixture",children);g.collectives.advance(1)
    g._notice("FILAMENTO · ⊥ adesione / ⋮ assorbimento · giunzioni clonali")
    g.camera.position=g.collectives.focus_position()+g.camera_offset
    g.camera.look_at(g.collectives.focus_position()+Vector3(0,.55,0))
    g._refresh_hud();await frame("filament")
    g.collectives.reset()
    g.entities[g.player_id].branch="archaea"
    tr=G.grant(g._base_traits(),"surface_recognition",30,"fixture","archaea")
    tr=G.grant(tr,"membrane_transport",30,"fixture","archaea")
    g.entities[g.player_id].traits=tr
    g.player.setup(tr,"archaea",true)
    g.entities["DONOR-1"].node.position=g.player.position+Vector3(2,0,0)
    g._on_cooperate();g.resources.carbon=24
    for i in range(30): g._advance_phase_two(1)
    g._on_phase_two();await frame("consortium")
    g.battle.start(2);g.battle.state.elapsed=180;g.battle.advance(.01)
    g._refresh_hud();g._layout_ui();await frame("front")
    g.battle.state.elapsed=1200;g.battle.advance(0);await frame("result")
    print("CAPTURE 084 PASS");quit()
func frame(label: String) -> void:
    await process_frame;await process_frame;await RenderingServer.frame_post_draw
    var path: String=ProjectSettings.globalize_path("res://build/previews/084-"+label+".png")
    DirAccess.make_dir_recursive_absolute(path.get_base_dir())
    assert(root.get_texture().get_image().save_png(path)==OK)
    print("SCREENSHOT_GODOT=",path)
