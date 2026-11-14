extends SceneTree
const Symbols=preload("res://src/biological_symbols.gd")
class Sheet extends Control:
    func _draw() -> void:
        draw_rect(Rect2(Vector2.ZERO,size),Color(.025,.065,.09))
        draw_string(ThemeDB.fallback_font,Vector2(24,42),"ORIGINI · ATLANTE DELLE MUTAZIONI",HORIZONTAL_ALIGNMENT_LEFT,-1,25,Color.WHITE)
        for i in range(Symbols.IDS.size()):
            var at:=Vector2(125+(i%4)*260,105+(i/4)*115)
            Symbols.draw(self,Symbols.IDS[i],at,29,Color(.65,.91,.90))
            draw_string(ThemeDB.fallback_font,at+Vector2(-115,53),Symbols.IDS[i],HORIZONTAL_ALIGNMENT_CENTER,230,16,Color.WHITE)
func _initialize() -> void: call_deferred("run")
func run() -> void:
    root.size=Vector2i(1060,1240)
    var sheet:=Sheet.new();sheet.size=Vector2(root.size);root.add_child(sheet)
    await process_frame;await process_frame;await RenderingServer.frame_post_draw
    var path:=ProjectSettings.globalize_path("res://build/previews/085-mutation-atlas.png")
    DirAccess.make_dir_recursive_absolute(path.get_base_dir())
    assert(root.get_texture().get_image().save_png(path)==OK)
    print("CAPTURE PASS ",path);quit()
