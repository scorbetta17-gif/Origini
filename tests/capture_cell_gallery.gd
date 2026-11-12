extends SceneTree

func _initialize() -> void:
    call_deferred("_capture")

func _capture() -> void:
    root.size = Vector2i(1600,1000)
    root.content_scale_size = root.size
    var gallery: Node = load("res://scenes/CellGallery.tscn").instantiate()
    root.add_child(gallery)
    await create_timer(.5).timeout
    await process_frame
    await RenderingServer.frame_post_draw
    var path: String = ProjectSettings.globalize_path("res://build/previews/")+OS.get_environment("ORIGIN_CAPTURE_PREFIX")+"cell-phenotypes-gallery.png"
    DirAccess.make_dir_recursive_absolute(path.get_base_dir())
    assert(root.get_texture().get_image().save_png(path)==OK)
    print("GALLERY_RENDERER=",RenderingServer.get_current_rendering_method()," DRIVER=",RenderingServer.get_current_rendering_driver_name())
    quit(0)
