extends RefCounted
## Semantic diagrams, not literal scale models. RNA orange; DNA violet.
const IDS := ["cell_zero","rna_inheritance","dormancy","translation","dna_archive","bioenergetics","luca","bacteria","archaea","prokaryotic_groups","differentiated_groups","alpha_partner","asgard_host","cytoskeleton","membrane_traffic","stable_consortium","internal_symbiont","nucleus","er_golgi","protein_import","metabolic_integration","coordinated_division","mitochondrion","leca","rna_replicase","dna_stabilization","membrane_transport","surface_recognition","pili_twitch","hydrolase_secretion","vesicle_pathway","eps_biosynthesis","thermal_membrane","chaperone_complex","cell_elongation","monoderm_envelope","diderm_envelope","archaeal_envelope","flagellar_motor","archaellar_motor"]

static func path(c: CanvasItem, o: Vector2, r: float, points: Array, ink: Color, w: float = 1.5) -> void:
    var p := PackedVector2Array()
    for v in points: p.append(o+Vector2(v[0],v[1])*r)
    c.draw_polyline(p,ink,w,true)

static func oval(c: CanvasItem, o: Vector2, r: float, x: float, y: float, sx: float, sy: float, ink: Color) -> void:
    var p := PackedVector2Array()
    for i in range(33):
        var a: float = TAU*i/32.0
        p.append(o+Vector2(x+cos(a)*sx,y+sin(a)*sy)*r)
    c.draw_polyline(p,ink,1.5,true)

static func strand(c: CanvasItem, o: Vector2, r: float, dna: bool, ink: Color) -> void:
    var p := PackedVector2Array()
    for i in range(65):
        var t: float = float(i)/64.0
        var v := Vector2((t-.5)*1.6,sin(t*TAU*1.5)*.35)
        if dna: v = Vector2(cos(t*TAU*3.7)*(.35+.22*sin(t*PI)),sin(t*TAU*5.1)*.50)
        p.append(o+v*r)
    c.draw_polyline(p,ink,1.6,true)

static func draw(c: CanvasItem, id: String, o: Vector2, r: float, ink: Color) -> void:
    var rna := Color(1,.62,.26,ink.a)
    var dna := Color(.77,.52,1,ink.a)
    match id:
        "rna_replicase","rna_inheritance": strand(c,o,r,false,rna)
        "dna_stabilization","dna_archive": strand(c,o,r,true,dna)
        "cell_zero":
            oval(c,o,r,0,0,.92,.76,ink)
            strand(c,o,r*.65,false,rna)
        "translation":
            oval(c,o,r,0,-.23,.55,.42,ink)
            oval(c,o,r,0,.35,.42,.19,ink)
            path(c,o,r,[[-.95,.18],[.95,.18]],rna)
            path(c,o,r,[[0,-.55],[.1,-.8],[.4,-.9]],ink)
        "dormancy":
            oval(c,o,r,0,0,.86,.70,ink)
            path(c,o,r,[[-.2,-.35],[-.2,.35]],ink,2)
            path(c,o,r,[[.2,-.35],[.2,.35]],ink,2)
        "cell_elongation","bacteria","alpha_partner","monoderm_envelope","diderm_envelope":
            oval(c,o,r,0,0,.91,.47,ink)
            if id != "cell_elongation": strand(c,o,r*.48,true,dna)
            if id in ["monoderm_envelope","diderm_envelope"]: oval(c,o,r,0,0,.77,.34,ink)
            if id == "diderm_envelope": oval(c,o,r,0,0,1.04,.62,ink)
            if id == "alpha_partner": path(c,o,r,[[.4,.7],[.8,.7],[.65,.55]],ink)
        "archaea","archaeal_envelope","thermal_membrane":
            for i in range(4):
                var x: float = -.75+i*.5
                oval(c,o,r,x,-.55,.10,.10,ink)
                oval(c,o,r,x,.55,.10,.10,ink)
                path(c,o,r,[[x,-.4],[x+.08,-.1]],ink)
                path(c,o,r,[[x,.4],[x-.08,.1]],ink)
                if id != "thermal_membrane": path(c,o,r,[[x,-.12],[x+.2,-.23]],ink)
        "luca":
            oval(c,o,r,0,.52,.24,.22,ink)
            for x in [-.65,0,.65]:
                path(c,o,r,[[0,.28],[x,-.3]],ink)
                oval(c,o,r,x,-.55,.19,.20,ink)
        "pili_twitch","asgard_host":
            oval(c,o,r,-.35,0,.45,.55,ink)
            path(c,o,r,[[.05,-.2],[.85,-.4],[.95,-.15]],ink)
            path(c,o,r,[[.05,.2],[.65,.45],[.9,.3]],ink)
            if id == "pili_twitch": path(c,o,r,[[.7,-.8],[.35,-.8],[.5,-.95]],ink)
        "flagellar_motor","archaellar_motor":
            oval(c,o,r,-.6,0,.28,.40,ink)
            var p := []
            for i in range(25): p.append([-.3+i/20.0,sin(i*.55)*.23])
            path(c,o,r,p,ink)
            oval(c,o,r,-.3,0,.12,.15,ink)
            if id == "archaellar_motor": oval(c,o,r,-.5,.62,.13,.13,ink)
        "surface_recognition":
            path(c,o,r,[[-.85,.7],[.85,.7]],ink)
            path(c,o,r,[[0,.7],[0,.05],[-.3,.05],[-.3,-.25]],ink)
            path(c,o,r,[[0,.05],[.3,.05],[.3,-.25]],ink)
            oval(c,o,r,0,-.65,.22,.20,ink)
        "membrane_transport","bioenergetics","protein_import":
            for y in [-.2,.2]:
                path(c,o,r,[[-1,y],[-.3,y],[-.3,y-.1]],ink)
                path(c,o,r,[[.3,y-.1],[.3,y],[1,y]],ink)
            path(c,o,r,[[0,-.85],[0,.8],[-.2,.55]],ink)
            if id == "protein_import": strand(c,o+Vector2(0,-r*.7),r*.4,false,ink)
            elif id == "bioenergetics": oval(c,o,r,.65,.65,.24,.21,ink)
        "hydrolase_secretion":
            path(c,o,r,[[-.8,.6],[-.8,-.2],[-.35,-.55],[0,-.15],[.35,-.55],[.8,-.2],[.8,.6],[-.8,.6]],ink)
            path(c,o,r,[[-.65,-.9],[-.2,-.9]],rna)
            path(c,o,r,[[.2,-.9],[.65,-.9]],rna)
        "vesicle_pathway","membrane_traffic":
            path(c,o,r,[[-.8,.9],[-.8,.25],[-.3,.05],[-.2,-.3],[-.5,-.5],[-.8,-.25],[-.8,-.9]],ink)
            oval(c,o,r,.48,-.45,.28,.28,ink)
            if id == "membrane_traffic": oval(c,o,r,.4,.55,.2,.2,ink)
        "eps_biosynthesis":
            oval(c,o,r,0,0,.45,.42,ink)
            for sign_value in [-1,1]:
                path(c,o,r,[[-.9,.48*sign_value],[-.5,.75*sign_value],[0,.6*sign_value],[.55,.8*sign_value],[.9,.5*sign_value]],ink)
        "cytoskeleton":
            oval(c,o,r,0,0,.95,.85,ink)
            for i in range(3):
                var y: float = -.4+i*.4
                path(c,o,r,[[-.65,y],[-.3,y+.1],[.3,y-.1],[.65,y]],ink)
        "chaperone_complex":
            for i in range(7):
                var a: float = TAU*i/7.0
                oval(c,o,r,cos(a)*.6,sin(a)*.6,.2,.2,ink)
            path(c,o,r,[[-.2,0],[0,-.15],[.2,.1]],rna)
        "prokaryotic_groups","differentiated_groups":
            for i in range(3):
                var x: float = -.65+i*.65
                oval(c,o,r,x,0,.32,.42,ink)
                if id == "differentiated_groups":
                    if i%2 == 0: path(c,o,r,[[x,.4],[x,.75],[x-.15,.75]],ink)
                    else: oval(c,o,r,x,0,.1,.1,rna)
        "stable_consortium","metabolic_integration":
            oval(c,o,r,-.55,0,.38,.56,ink)
            oval(c,o,r,.65,0,.25,.40,ink)
            path(c,o,r,[[-.1,-.35],[.3,-.35],[.2,-.5]],ink)
            path(c,o,r,[[.3,.35],[-.1,.35],[0,.5]],ink)
            if id == "metabolic_integration": oval(c,o,r,0,0,1.05,.9,ink)
        "internal_symbiont","mitochondrion","nucleus","leca","coordinated_division":
            oval(c,o,r,0,0,.95,.78,ink)
            if id == "internal_symbiont":
                oval(c,o,r,.25,.05,.42,.28,ink)
                strand(c,o+Vector2(r*.25,0),r*.23,true,dna)
            elif id == "mitochondrion":
                oval(c,o,r,0,0,.80,.63,ink)
                path(c,o,r,[[-.65,-.3],[-.4,.3],[-.15,-.3],[.1,.3],[.35,-.3],[.65,.25]],ink)
            elif id == "coordinated_division":
                path(c,o,r,[[0,-.75],[0,.75]],ink)
                oval(c,o,r,-.42,0,.20,.16,ink)
                oval(c,o,r,.42,0,.20,.16,ink)
            else:
                if id == "leca": oval(c,o,r,-.2,0,.48,.43,ink)
                strand(c,o-Vector2(r*.2,0),r*.32,true,dna)
                if id == "nucleus": oval(c,o,r,0,0,.82,.66,ink)
                else:
                    oval(c,o,r,.6,.3,.17,.26,ink)
                    path(c,o,r,[[.35,-.45],[.65,-.5],[.7,-.25]],ink)
        "er_golgi":
            for i in range(3):
                var y: float = -.5+i*.45
                path(c,o,r,[[-.7,y],[-.45,y+.12],[.4,y+.12],[.65,y]],ink)
            oval(c,o,r,.85,.65,.15,.15,ink)
