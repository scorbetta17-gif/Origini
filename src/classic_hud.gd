extends Control
class_name OriginiClassicHud
## Visual language reconstructed from ORIGINI 0.56–0.62 web screenshots.
## Native Godot CanvasItem: no WebView, no HTTP, no emulator.
const PAPER = Color(.91,.97,.97)
const MUTED = Color(.64,.81,.84)
const CYAN = Color(.44,.89,.89)
const MINT = Color(.43,.89,.77)
const GOLD = Color(.99,.76,.38)
const PINK = Color(1.00,.57,.69)
const LAVENDER = Color(.73,.61,.99)
const DEEP = Color(.014,.071,.095,.98)
const PANEL = Color(.022,.145,.182,.92)
const EDGE = Color(.20,.46,.50,.75)

var state: Dictionary = {}
var portrait: bool = true
var ui_scale: float = 1.0
var back: StyleBoxFlat
var card: StyleBoxFlat
var strip: StyleBoxFlat
var progress_card: StyleBoxFlat
var progress_back: StyleBoxFlat

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    back = _style(Color(.008,.058,.074,.98),Color(.11,.29,.32,.85),0)
    card = _style(Color(.018,.119,.151,.95),Color(.21,.47,.50,.85),14)
    strip = _style(Color(.018,.108,.141,.95),Color(.19,.42,.47,.82),13)
    progress_card = _style(Color(.021,.136,.164,.95),Color(.23,.62,.63,.78),17)
    progress_back = _style(Color(.10,.22,.27,.9),Color(.16,.38,.43,.60),8)

func _style(fill: Color, border: Color, radius: int) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = fill
    s.border_color = border
    s.set_border_width_all(1)
    s.set_corner_radius_all(radius)
    return s

func set_viewport(wh: Vector2) -> void:
    size = wh
    portrait = wh.y >= wh.x
    ui_scale = clampf(wh.x/720.0,.62,1.65) if portrait else 1.0
    queue_redraw()

func configure(values: Dictionary) -> void:
    state = values.duplicate(true)
    queue_redraw()

func _tx(at: Vector2, value: String, pixels: int, tint: Color = PAPER, max_width: float = -1) -> void:
    draw_string(ThemeDB.fallback_font,at,value,HORIZONTAL_ALIGNMENT_LEFT,max_width,pixels,tint)

func _box(x: float, y: float, w: float, h: float, style: StyleBoxFlat) -> void:
    draw_style_box(style,Rect2(x,y,w,h))

func _fillbar(x: float, y: float, w: float, h: float, fraction: float, color: Color) -> void:
    _box(x,y,w,h,progress_back)
    var length: float = maxf(0.0,(w-4)*clampf(fraction,0.0,1.0))
    if length >= 1:
        draw_rect(Rect2(x+2,y+2,length,maxf(1,h-4)),color)

func _draw() -> void:
    if not portrait:
        return
    var scale_factor: float = ui_scale
    draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE*scale_factor)
    var w: float = size.x/scale_factor
    var h: float = size.y/scale_factor
    var compact: bool = h < 1120
    var top_height: float = 412.0 if not compact else 386.0
    _box(0,0,w,top_height,back)
    draw_rect(Rect2(0,top_height-2,w,2),Color(.22,.59,.60,.54))

    # Header: title, version and lineage at a glance.
    _tx(Vector2(22,47),"O R I G I N I",30,PAPER)
    _tx(Vector2(24,71),str(state.get("phase_title","FASE 1 · CONQUISTA DELLA NICCHIA")),13,Color(.43,.83,.78))
    _tx(Vector2(w*.55,37),"GEN %d  ·  %s" % [int(state.get("gen",0)),str(state.get("branch","PRIMORDIALE"))],17,PAPER,w*.42)
    _tx(Vector2(w*.55,62),"TEMPO %s  ·  %.0f°C" % [str(state.get("elapsed","00:00")),float(state.get("temp",29.0))],12,MUTED,w*.43)

    # ATP/HP cards: former web game's wide, friendly full-width bars.
    for i in range(2):
        var y: float = 91.0+float(i)*52.0
        _box(18,y,w-36,46,strip)
        var energy: bool = i == 0
        var value: float = float(state.get("atp" if energy else "hp",100.0))
        var maximum: float = 100.0
        var c: Color = GOLD if energy else PINK
        _tx(Vector2(32,y+30),"⚡ ATP" if energy else "♥ HP",18,c,97)
        _fillbar(126,y+18,w-290,13,value/maximum,c)
        _tx(Vector2(w-139,y+30),"%d/100" % int(round(value)),18,PAPER,112)
        if energy and value < .01:
            var remains: int = maxi(0,15-int(floor(float(state.get("zero_atp",0.0)))))
            _tx(Vector2(161,y+31),"ATP ESAURITO · %d s" % remains,13,PINK,w-320)

    # Four resources in four framed cards, not one dense stats string.
    var names: Array[String] = ["CARBONIO","AMMINOACIDI","LIPIDI","NUCLEOTIDI"]
    var keys: Array[String] = ["carbon","amino","lipid","nucleic"]
    var accents: Array[Color] = [GOLD,Color(.70,.89,.62),Color(.98,.85,.46),LAVENDER]
    var card_gap: float = 9.0
    var card_w: float = (w-36.0-card_gap*3.0)/4.0
    for i in range(4):
        var x: float = 18.0+float(i)*(card_w+card_gap)
        _box(x,202,card_w,77,card)
        _tx(Vector2(x+10,227),names[i],12,accents[i],card_w-17)
        _tx(Vector2(x+12,264),str(int(state.get(keys[i],0))),27,PAPER,card_w-20)

    # Chapter objective and thin progress indicator.
    var chapter: String = str(state.get("chapter","1/3  PRIMA DISCENDENZA"))
    _tx(Vector2(22,308),chapter,18,PAPER,w-44)
    _tx(Vector2(22,331),str(state.get("objective","Raccogli nutrienti e dividi la cellula")),13,MUTED,w-42)
    _fillbar(22,344,w-44,9,float(state.get("chapter_progress",0)),MINT)
    _tx(Vector2(w-80,377),"%d%%" % int(round(float(state.get("chapter_progress",0))*100.0)),13,GOLD,64)
    _tx(Vector2(22,377),str(state.get("chapter_detail","LA TUA LINEA EVOLUTIVA")),12,Color(.44,.83,.79),w-112)

    # Controls occupy the lateral margins, leaving world visible.
    var action_top: float = h-382.0
    _tx(Vector2(24,action_top-13),"◇ DIFESA",15,CYAN)
    _tx(Vector2(w-160,action_top-13),"⚔ INTERAZIONE",15,Color(.99,.79,.63),151)

    # Scission requirements: legible but not covering the center of the cell.
    var bottom: float = h-177.0
    var fission_x: float = 183.0
    var fission_width: float = maxf(158.0,w-363.0)
    _box(fission_x,bottom,fission_width,144.0,progress_card)
    _tx(Vector2(fission_x+13,bottom+25),"SCISSIONE  ·  %d%%" % int(floor(float(state.get("fission",0))*100.0)),17,PAPER,fission_width-23)
    _fillbar(fission_x+13,bottom+34,fission_width-26,10,float(state.get("fission",0)),LAVENDER)
    _tx(Vector2(fission_x+13,bottom+68),str(state.get("requirements_1","C 0/24 · A 0/15")),13,MUTED,fission_width-25)
    _tx(Vector2(fission_x+13,bottom+91),str(state.get("requirements_2","L 0/12 · N 0/8")),13,MUTED,fission_width-25)
    _tx(Vector2(fission_x+13,bottom+114),str(state.get("requirements_3","BIO 0/65 · ATP 0/30")),13,MUTED,fission_width-25)
    _tx(Vector2(fission_x+13,bottom+136),"PRONTA" if bool(state.get("can_divide",false)) else str(state.get("division_status","RACCOGLI RISORSE")),11,MINT if bool(state.get("can_divide",false)) else GOLD,fission_width-25)

func panel_height() -> float:
    return (412.0 if size.y/ui_scale >= 1120 else 386.0)*ui_scale
