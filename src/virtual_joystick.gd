extends Control
class_name OriginiJoystick
## Joystick touch indipendente dalla gerarchia UI. Mantiene il dito catturato anche
## quando il trascinamento esce dai limiti visuali. Ignora il mouse sintetico Android.
signal direction_changed(value: Vector2)

var direction: Vector2 = Vector2.ZERO
var finger_id: int = -1
var mouse_active: bool = false
var touch_seen: bool = false
var controls_enabled: bool = true
var deadzone: float = 0.12
var radius: float = 49.0

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    custom_minimum_size = Vector2(116,116)
    set_process_input(true)

func _point(screen_position: Vector2) -> void:
    var local_pos: Vector2 = screen_position-global_position
    var raw: Vector2 = ((local_pos-size*.5)/radius).limit_length(1.0)
    direction = Vector2.ZERO if raw.length() < deadzone else raw
    direction_changed.emit(direction)
    queue_redraw()

func reset_input() -> void:
    finger_id = -1
    mouse_active = false
    direction = Vector2.ZERO
    direction_changed.emit(direction)
    queue_redraw()

func set_controls_enabled(enabled: bool) -> void:
    controls_enabled = enabled
    if not controls_enabled:
        reset_input()

func _exit_tree() -> void:
    reset_input()

func _input(event: InputEvent) -> void:
    if not controls_enabled or not visible or not is_visible_in_tree():
        return
    if event is InputEventScreenTouch:
        touch_seen = true
        if event.pressed and finger_id < 0 and get_global_rect().has_point(event.position):
            finger_id = event.index
            _point(event.position)
        elif not event.pressed and event.index == finger_id:
            reset_input()
    elif event is InputEventScreenDrag and event.index == finger_id:
        _point(event.position)
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not touch_seen:
        if event.pressed and get_global_rect().has_point(event.position):
            mouse_active = true
            _point(event.position)
        elif not event.pressed and mouse_active:
            reset_input()
    elif event is InputEventMouseMotion and mouse_active and not touch_seen:
        _point(event.position)

func _draw() -> void:
    var center: Vector2 = size*.5
    draw_circle(center,radius+9.0,Color(.01,.08,.11,.55))
    draw_arc(center,radius+9.0,0,TAU,64,Color(.35,.76,.81,.75),2.0,true)
    draw_circle(center,radius,Color(.05,.19,.25,.64))
    draw_circle(center+direction*radius*.72,23.0,Color(.42,.79,.83,.93))
    draw_arc(center+direction*radius*.72,23.0,0,TAU,32,Color(.84,1.0,.97,.85),1.8,true)
