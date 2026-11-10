"""Build the rigid Surtr study. Requires Python, NumPy, SciPy and Pillow."""
import io
import json
import math
import struct
from pathlib import Path

import numpy as np
from PIL import Image
from scipy.spatial.transform import Rotation

ART = Path(__file__).resolve().parents[3]
OUT = ART / "characters/surtr/char_surtr.glb"
colors = dict(
    hair="#985f56", hairshade="#673e45", hairlight="#ba8275", copper="#bf927e",
    horn="#33303d", hornlight="#514650", tip="#b58970", skin="#f1c4aa",
    blush="#df9e90", cream="#efe5dc", snow="#fcf4e9", ink="#262333",
    plum="#464152", steel="#64616e", coat="#373442", wine="#61444f",
    violet="#9173b2", iris="#644885", lilac="#ccaddf", amber="#edb155",
    gold="#b07d52", edge="#ffcf73", blade="#555263", ridge="#847883")
nodes, names, geo = [], {}, {}
def joint(name, parent=None, pos=(0,0,0), rot=(0,0,0)):
    i = len(nodes)
    names[name] = i
    q = Rotation.from_euler("xyz", rot, degrees=True).as_quat().tolist()
    nodes.append(dict(name=name, translation=list(pos), rotation=q))
    if parent is not None:
        nodes[names[parent]].setdefault("children", []).append(i)
    geo[name] = []
    return name

def face(n, pts, color, outside):
    pts = np.array(pts, dtype=float)
    normal = np.cross(pts[1]-pts[0], pts[2]-pts[0])
    if np.dot(normal, outside) < 0:
        pts = pts[::-1]
    for k in range(1,len(pts)-1):
        tri = pts[[0,k,k+1]]
        if np.linalg.norm(np.cross(tri[1]-tri[0],tri[2]-tri[0])) > 1e-10:
            geo[n].append((tri, color))

def loft(n, rows, color, sides=8, chamfer=False):
    # rows are (y, centre x/z, half-width, half-depth)
    rings = []
    for y,x,z,w,d in sorted(rows):
        if chamfer:
            shape = [(.72,1),(-.72,1),(-1,.68),(-1,-.68),(-.72,-1),(.72,-1),(1,-.68),(1,.68)]
        else:
            shape = [(math.sin((i+.5)*2*math.pi/sides),math.cos((i+.5)*2*math.pi/sides)) for i in range(sides)]
        rings.append(np.array([[x+u*w,y,z+v*d] for u,v in shape]))
    face(n,rings[0],color,[0,-1,0])
    face(n,rings[-1],color,[0,1,0])
    for low,high in zip(rings,rings[1:]):
        mid=(low.mean(0)+high.mean(0))*.5
        for i in range(len(low)):
            j=(i+1)%len(low)
            poly=[low[i],low[j],high[j],high[i]]
            out=np.mean(poly,0)-mid
            out[1]=0
            face(n,poly,color,out)

def block(n,x,y,z,w,h,d,c,b=.12):
    b=min(min(h,w,d)*b,.012)
    loft(n,[(y-h/2,x,z,w/2-b,d/2-b),(y-h/2+b,x,z,w/2,d/2),
        (y+h/2-b,x,z,w/2,d/2),(y+h/2,x,z,w/2-b,d/2-b)],c,chamfer=True)

def plate(n, xy, z, c, depth=.005):
    # Convex in XY. Front face and bevel-like dark sidewalls.
    a=np.array([[x,y,z] for x,y in xy]); b=a.copy(); b[:,2]-=depth
    face(n,a,c,[0,0,1]); face(n,b,c,[0,0,-1])
    for i in range(len(a)):
        j=(i+1)%len(a); p=[a[i],a[j],b[j],b[i]]
        face(n,p,c,np.mean(p,0)-(a.mean(0)+b.mean(0))*.5)

def stroke(n,a,b,width,z,c):
    a,b=np.array(a),np.array(b)
    delta=b-a; perp=np.array([-delta[1],delta[0]])/np.linalg.norm(delta)*width*.5
    plate(n,[a+perp,b+perp,b-perp,a-perp],z,c,.002)

joint("root")
joint("pelvis","root",(0,.475,0))
joint("spine","pelvis",(0,.045,0))
joint("chest","spine",(0,.115,0))
joint("neck","chest",(0,.106,0))
joint("head","neck",(0,.014,0))
joint("face","head")
loft("pelvis",[(-.104,0,0,.174,.111),(-.085,0,0,.186,.122),(.041,0,0,.114,.077)],"ink",10)
loft("pelvis",[(-.109,0,0,.178,.115),(-.094,0,0,.185,.121),(-.084,0,0,.184,.12)],"cream",10)
loft("spine",[(-.021,0,0,.11,.076),(.046,0,0,.108,.073),(.111,0,0,.139,.088)],"coat",chamfer=True)
loft("chest",[(-.036,0,0,.116,.077),(.041,0,0,.151,.087),(.09,0,0,.087,.057)],"plum",chamfer=True)
loft("neck",[(-.008,0,.003,.057,.05),(.056,0,.003,.057,.05)],"skin")
loft("chest",[(.057,0,.004,.086,.063),(.09,0,.008,.072,.057)],"ink")
for side in [-1,1]:
    plate("chest",[(side*x,y) for x,y in [(.145,.045),(.071,.081),(.025,.052),(.05,-.022)]],.083,"cream")
stroke("spine",(-.094,.099),(.083,-.002),.025,.088,"ink")
stroke("spine",(-.092,.096),(.082,-.006),.003,.092,"steel")
block("pelvis",0,.032,.006,.239,.035,.167,"ink")
block("pelvis",.014,.034,.09,.042,.026,.008,"gold")
block("pelvis",.014,.034,.095,.023,.012,.006,"coat")
for side in [-1,1]:
    sf="l" if side==1 else "r"
    joint("thigh_"+sf,"pelvis",(side*.084,-.025,0))
    joint("shin_"+sf,"thigh_"+sf,(0,-.195,0))
    joint("foot_"+sf,"shin_"+sf,(0,-.19,0))
    n="thigh_"+sf
    loft(n,[(0,0,0,.068,.063),(-.18,0,0,.051,.052),(-.202,0,0,.048,.047)],"wine",chamfer=True)
    loft(n,[(-.144,0,0,.053,.055),(-.125,0,0,.058,.056)],"ink",chamfer=True)
    n="shin_"+sf
    loft(n,[(.006,0,0,.058,.057),(-.032,0,-.006,.064,.06),(-.174,0,0,.052,.048)],"coat",chamfer=True)
    block(n,side*.037,-.051,.035,.038,.017,.032,"steel")
    foot="foot_"+sf
    block(foot,0,-.029,.024,.125,.067,.164,"ink")
    block(foot,0,-.055,.027,.132,.018,.172,"steel")
    plate(foot,[(-.049,-.044),(.048,-.044),(.029,-.02),(-.018,-.021)],.109,"cream")
    joint("upper_arm_"+sf,"chest",(side*.139,.045,0))
    joint("forearm_"+sf,"upper_arm_"+sf,(side*.031,-.126,0))
    joint("hand_"+sf,"forearm_"+sf,(0,-.115,.012))
    n="upper_arm_"+sf
    loft(n,[(.022,0,0,.058,.056),(-.015,side*.009,0,.067,.066),(-.123,side*.03,0,.049,.047)],"plum",chamfer=True)
    loft(n,[(.025,0,.002,.056,.056),(-.03,side*.009,.002,.066,.065)],"cream",chamfer=True)
    n="forearm_"+sf
    loft(n,[(.01,0,0,.048,.05),(-.058,0,.006,.045,.044),(-.113,0,.011,.036,.039)],"skin",chamfer=True)
    block(n,0,-.096,.011,.086,.046,.088,"ink")
    block("hand_"+sf,0,-.029,.012,.075,.07,.065,"skin")
    block("hand_"+sf,-side*.028,-.018,.035,.023,.039,.027,"skin")
# Layered skirt panels, split to clear the legs.
for i,(x,z,yaw) in enumerate([(-.119,-.01,-38),(.119,-.01,38),(0,-.068,180)],1):
    n=joint("cloth_0"+str(i),"pelvis",(x,.025,z),(0,yaw,0))
    plate(n,[(-.045,0),(.05,0),(.086,-.183),(.012,-.221),(-.066,-.171)],.018,"coat",.023)
    stroke(n,(-.042,-.17),(.012,-.206),.01,.022,"cream")

# Sculpted planar face: a flat front for the eye artwork and a tapered chin.
loft("head",[(.006,0,.02,.053,.072),(.026,0,.013,.107,.105),
    (.086,0,.006,.162,.13),(.187,0,0,.175,.137),(.265,0,-.004,.147,.12),
    (.305,0,-.009,.083,.076)],"skin",chamfer=True)
for side in [-1,1]:
    def mirror(points):
        return [(x*side,y) for x,y in points]
    n="face"
    plate(n,mirror([(.028,.131),(.048,.155),(.105,.153),(.129,.159),(.113,.113),(.084,.098),(.042,.105)]),.139,"ink")
    plate(n,mirror([(.033,.128),(.051,.147),(.104,.145),(.116,.149),(.106,.116),(.082,.104),(.048,.11)]),.141,"snow")
    plate(n,mirror([(.054,.143),(.089,.145),(.098,.132),(.094,.114),(.078,.105),(.059,.111),(.052,.128)]),.143,"iris")
    plate(n,mirror([(.055,.122),(.093,.124),(.091,.114),(.078,.107),(.061,.113)]),.145,"violet")
    plate(n,mirror([(.068,.142),(.081,.141),(.083,.127),(.076,.118),(.069,.123)]),.147,"ink")
    block(n,side*.064,.139,.15,.012,.011,.004,"snow",.07)
    stroke(n,(side*.04,.169),(side*.101,.181),.009,.139,"hairshade")
    stroke(n,(side*.096,.087),(side*.111,.09),.004,.132,"blush")
stroke("face",(-.016,.057),(.001,.054),.0035,.13,"hairshade")
stroke("face",(.001,.054),(.014,.058),.0035,.13,"hairshade")
plate("face",[(-.006,.085),(.003,.10),(.009,.084)],.141,"blush")
# Single hair cap, back curtain and two swept side locks.
loft("head",[(.185,0,-.009,.178,.145),(.238,0,-.013,.19,.151),
    (.292,0,-.018,.163,.13),(.334,0,-.024,.096,.09),(.342,-.009,-.025,.049,.046)],"hair",12)
for i,(x,y,z,rows,col) in enumerate([
    (0,.235,-.093,[(0,0,0,.153,.063),(-.15,0,-.021,.181,.071),(-.36,-.023,-.061,.158,.064),(-.55,-.088,-.12,.096,.039),(-.60,-.157,-.16,.009,.006)],"hairshade"),
    (-.122,.23,-.045,[(0,0,0,.062,.065),(-.134,-.018,-.021,.07,.065),(-.38,-.024,-.058,.074,.048),(-.46,-.142,-.112,.062,.025),(-.48,-.226,-.142,.006,.004)],"hair"),
    (.126,.225,-.041,[(0,0,0,.06,.068),(-.15,.024,-.013,.067,.061),(-.32,.014,-.05,.065,.046),(-.41,.107,-.105,.048,.026),(-.43,.184,-.147,.004,.004)],"hair"),
    (-.143,.217,.044,[(0,0,0,.05,.074),(-.116,-.014,.008,.046,.07),(-.226,.013,.018,.037,.045),(-.30,.069,.027,.004,.005)],"hair"),
    (.143,.213,.041,[(0,0,0,.047,.072),(-.097,.015,.008,.047,.07),(-.188,-.002,.024,.035,.046),(-.235,-.043,.032,.004,.006)],"hair")],1):
    n=joint("hair_%02d"%i,"head",(x,y,z))
    loft(n,rows,col,7)
# Large overlapping asymmetrical bangs and restrained planar highlights.
for points,z,c in [
    ([(-.176,.222),(-.131,.29),(-.048,.296),(-.057,.216),(-.126,.153),(-.155,.126)],.145,"hair"),
    ([(.002,.319),(.088,.296),(.13,.248),(.115,.198),(.076,.149),(.032,.12),(.044,.182)],.153,"hair"),
    ([(-.119,.278),(-.062,.322),(.004,.324),(.066,.281),(.061,.224),(.025,.16),(-.011,.124),(-.019,.176),(-.077,.192)],.158,"hair"),
    ([(-.107,.273),(-.068,.293),(-.033,.296),(-.059,.278)],.16,"hairlight"),
    ([(.066,.279),(.093,.265),(.104,.244),(.078,.256)],.157,"hairlight")]:
    plate("head",points,z,c,.024)
for side in [-1,1]:
    n=joint("ext_horn_"+("l" if side==1 else "r"),"head",(side*.132,.259,-.024))
    loft(n,[(0,0,0,.052,.049),(.037,side*.025,-.009,.052,.043),(.082,side*.062,-.023,.036,.032),
        (.118,side*.077,-.033,.026,.024),(.15,side*.065,-.045,.015,.016),
        (.178,side*.041,-.05,.002,.002)],"horn",6)
    plate(n,[(side*.043,.095),(side*.064,.126),(side*.064,.146),(side*.078,.121),(side*.068,.092)],-.002,"hornlight")
    loft(n,[(.142,side*.068,-.042,.017,.016),(.158,side*.06,-.047,.01,.011),(.178,side*.041,-.05,.002,.002)],"tip",6)
    block("head",side*.159,.204,.024,.035,.029,.045,"gold")
# Long asymmetrical greatsword: raised spine, amber cutting edge, forged quillons.
joint("prop","hand_r")
block("prop",.046,0,0,.189,.031,.038,"ink")
for x in [-.026,.002,.03,.058,.086,.114]:
    block("prop",x,0,0,.009,.034,.041,"gold")
loft("prop",[(-.041,-.053,0,.016,.013),(0,-.063,0,.032,.027),(.039,-.051,0,.01,.01)],"steel",6)
plate("prop",[(.116,-.088),(.133,-.033),(.159,-.012),(.166,.021),(.133,.052),(.103,.101),(.1,.062),(.118,.015),(.096,-.042)],.035,"horn",.07)
for z in [.019,-.012]:
    plate("prop",[(.14,.032),(.232,.048),(.363,.022),(.635,-.021),(.818,-.033),(.727,-.064),(.498,-.077),(.237,-.053),(.154,-.023)],z,"blade",.014)
plate("prop",[(.157,.013),(.236,.033),(.632,-.024),(.782,-.035),(.512,-.045),(.243,-.012)],.021,"ridge")
plate("prop",[(.169,-.019),(.27,-.039),(.504,-.057),(.721,-.05),(.818,-.033),(.727,-.064),(.498,-.077),(.237,-.053)],.023,"amber")
plate("prop",[(.23,-.047),(.502,-.071),(.724,-.06),(.818,-.033),(.727,-.065),(.498,-.078)],.025,"edge")
joint("prop_emblem","prop",(.145,0,.038))
plate("prop_emblem",[(-.021,0),(0,.026),(.026,0),(0,-.026)],.002,"amber")

# Structured overskirt and lining: broad folds stay legible from a fight camera.
for sign in [-1,1]:
    plate("pelvis",[(sign*x,y) for x,y in [(.012,.023),(.09,.021),(.158,-.076),
        (.132,-.126),(.054,-.109)]],.099,"plum",.022)
    plate("pelvis",[(sign*x,y) for x,y in [(.05,-.088),(.137,-.069),(.153,-.087),
        (.127,-.126),(.065,-.113)]],.103,"cream",.006)
    stroke("pelvis",(sign*.11,-.045),(sign*.139,-.079),.006,.105,"steel")
    foot="foot_"+("l" if sign==1 else "r")
    for j in range(2):
        stroke(foot,(-.025,-.023-j*.007),(.029,-.029-j*.007),.004,.111,"steel")
    # Side framing gives the large cap an angular change of plane at the temple.
    n="hair_0"+("5" if sign==1 else "4")
    plate(n,[(sign*.011,-.01),(sign*.036,-.07),(sign*.017,-.14),
        (sign*.012,-.077)],.068,"hairlight",.003)
plate("chest",[(-.017,.046),(.002,.058),(.016,.042),(-.002,.019)],.092,"gold")
plate("chest",[(-.009,.044),(.002,.05),(.009,.042),(0,.029)],.094,"amber")
for j in range(2):
    stroke("spine",(-.069,.062-j*.025),(.023,.039-j*.025),.005,.094,"steel")
# One palette atlas / one surface per pivot; geometry keeps flat face normals.
palette=Image.new("RGB",(16*len(colors),16))
for k,(name,value) in enumerate(colors.items()):
    palette.paste(value,(k*16,0,k*16+16,16))
png=io.BytesIO(); palette.save(png,format="PNG")
blob=bytearray()
doc=dict(asset=dict(version="2.0",generator="Surtr rigid character study"),scene=0,
    scenes=[dict(nodes=[0])],nodes=nodes,meshes=[],accessors=[],bufferViews=[],
    samplers=[dict(magFilter=9728,minFilter=9728,wrapS=33071,wrapT=33071)],
    textures=[dict(source=0,sampler=0)],animations=[],
    materials=[dict(name="surtr_palette",pbrMetallicRoughness=dict(baseColorTexture=dict(index=0),metallicFactor=0,roughnessFactor=.82))])
def buffer_view(raw):
    while len(blob)%4: blob.append(0)
    off=len(blob); blob.extend(raw)
    doc["bufferViews"].append(dict(buffer=0,byteOffset=off,byteLength=len(raw)))
    return len(doc["bufferViews"])-1
def accessor(values,kind,limits=False):
    a=np.asarray(values,dtype="<f4")
    r=dict(bufferView=buffer_view(a.tobytes()),componentType=5126,count=len(a),type=kind)
    if limits:
        r["min"]=a.reshape(len(a),-1).min(0).tolist()
        r["max"]=a.reshape(len(a),-1).max(0).tolist()
    doc["accessors"].append(r)
    return len(doc["accessors"])-1
doc["images"]=[dict(bufferView=buffer_view(png.getvalue()),mimeType="image/png")]
for name,tris in geo.items():
    if not tris: continue
    verts=[]; normals=[]; tex=[]; smooth={}
    for tri,color in tris:
        norm=np.cross(tri[1]-tri[0],tri[2]-tri[0]); unit=norm/np.linalg.norm(norm)
        for p in tri:
            verts.append(p); normals.append(unit)
            tex.append(((list(colors).index(color)+.5)/len(colors),.5))
            key=tuple(p.round(7)); smooth[key]=smooth.get(key,np.zeros(3))+norm
    outline=[smooth[tuple(p.round(7))] for p in verts]
    outline=np.array(outline); outline/=np.maximum(np.linalg.norm(outline,axis=1,keepdims=True),1e-12)
    attrs=dict(POSITION=accessor(verts,"VEC3",True),NORMAL=accessor(normals,"VEC3"),
        TEXCOORD_0=accessor(tex,"VEC2"),_OUTLINE_NORMAL=accessor(outline,"VEC3"))
    nodes[names[name]]["mesh"]=len(doc["meshes"])
    doc["meshes"].append(dict(name=name,primitives=[dict(attributes=attrs,material=0)]))

def rot(x,y,z):
    return Rotation.from_euler("xyz",[x,y,z],degrees=True)
def align(a,b):
    a=np.asarray(a)/np.linalg.norm(a); b=np.asarray(b)/np.linalg.norm(b)
    return Rotation.from_rotvec(np.cross(a,b)/max(np.linalg.norm(np.cross(a,b)),1e-9)*math.acos(np.clip(np.dot(a,b),-1,1)))
def arms(poses,grip,blade):
    # Both hands stay on the grip. Elbows use independent outward pole vectors.
    for side,sf,along in [(-1,"r",0),(1,"l",.093)]:
        u="upper_arm_"+sf; f="forearm_"+sf; h="hand_"+sf
        shoulder=np.array(nodes[names[u]]["translation"])
        upper=np.array(nodes[names[f]]["translation"]); lower=np.array(nodes[names[h]]["translation"])
        target=grip+blade.apply([along,0,0]); line=target-shoulder
        length=np.linalg.norm(line); direction=line/length
        lu,ll=np.linalg.norm(upper),np.linalg.norm(lower)
        reach=min(length,lu+ll-.0001)
        advance=(lu*lu-ll*ll+reach*reach)/(2*reach)
        pole=np.array([side*.8,-1,-.4]); pole-=direction*np.dot(direction,pole)
        elbow=direction*advance+pole/np.linalg.norm(pole)*math.sqrt(max(0,lu*lu-advance*advance))
        upper_rot=align(upper,elbow); lower_rot=align(lower,direction*reach-elbow)
        poses[u]=upper_rot; poses[f]=upper_rot.inv()*lower_rot
        poses[h]=lower_rot.inv()*blade
    poses["prop"]=rot(0,0,0)

def curve(frame,keys):
    return np.array([np.interp(frame,[k[0] for k in keys],[k[1][i] for k in keys]) for i in range(len(keys[0][1]))])
def sample(clip,frame,total):
    phase=2*math.pi*frame/total; wave=math.sin(phase); p={}; offsets={}
    grip=np.array([-.074,-.116,.14]); blade=rot(3,-12,-18)
    if clip=="idle":
        offsets["pelvis"]=[0,.475+.005*wave,0]
        p["chest"]=rot(-3+2*wave,-6,1); p["head"]=rot(3-wave,7,1+wave)
        blade=rot(3,-12,-18+1.5*wave)
    elif clip=="walk_fwd":
        offsets["pelvis"]=[.009*wave,.475-.014*abs(wave),0]
        p["pelvis"]=rot(1,5*wave,-2*wave); p["chest"]=rot(5,-9*wave,2*wave)
        p["head"]=rot(-4,3*wave,-wave)
        for side,sf in [(-1,"r"),(1,"l")]:
            s=side*wave; knee=35*max(0,-s)
            p["thigh_"+sf]=rot(-27*s,0,side*2); p["shin_"+sf]=rot(knee,0,0)
            p["foot_"+sf]=rot(15*s-knee*.5,0,0)
        blade=rot(5,-12,-15+3*wave)
    else:
        k=[(0,[-13,-20,-18]),(3,[4,27,81]),(4,[5,30,96]),(5,[2,4,46]),
           (7,[-12,-38,-35]),(9,[-10,-42,-42]),(12,[-4,-25,-28]),(16,[3,-12,-18])]
        blade=rot(*curve(frame,k))
        grip=curve(frame,[(0,grip),(4,[-.044,.029,.115]),(7,[-.066,-.095,.169]),(10,[-.062,-.115,.16]),(16,grip)])
        yaw,bend=curve(frame,[(0,[-6,-3]),(4,[-25,-9]),(7,[24,13]),(10,[27,12]),(16,[-6,-3])])
        p["chest"]=rot(bend,yaw,0); p["head"]=rot(-bend*.62,-yaw*.7,1)
        drive=math.sin(math.pi*frame/total)
        p["thigh_l"]=rot(-13*drive,0,-5*drive);p["shin_l"]=rot(17*drive,0,0)
        p["thigh_r"]=rot(12*drive,0,4*drive);p["shin_r"]=rot(8*drive,0,0)
        offsets["pelvis"]=[.011*drive,.475-.014*drive,.016*drive]
    for i in range(1,6):
        flutter=math.sin(phase-(i-1)*.47)
        p["hair_%02d"%i]=rot((2 if clip=="idle" else 6)*flutter,0,1.3*flutter)
    for i in range(1,4):
        p["cloth_%02d"%i]=rot((2 if clip=="idle" else 7)*math.sin(phase+i),[-38,38,180][i-1],0)
    arms(p,grip,blade)
    return p,offsets
for clip,ticks,loop in [("idle",120,True),("walk_fwd",36,True),("light_atk",16,False)]:
    anim=dict(name=clip,channels=[],samplers=[],extras=dict(loop=loop,ticks=ticks))
    time=accessor(np.arange(ticks+1)/60,"SCALAR",True)
    tracks={}
    for frame in range(ticks+1):
        p,offset=sample(clip,frame,ticks)
        for name,r in p.items():
            vals=tracks.setdefault((name,"rotation"),[])
            q=r.as_quat()
            if vals and np.dot(vals[-1],q)<0:q=-q
            vals.append(q)
        for name,v in offset.items(): tracks.setdefault((name,"translation"),[]).append(v)
    for (name,path),v in tracks.items():
        output=accessor(v,"VEC4" if path=="rotation" else "VEC3")
        anim["channels"].append(dict(sampler=len(anim["samplers"]),target=dict(node=names[name],path=path)))
        anim["samplers"].append(dict(input=time,output=output,interpolation="LINEAR"))
    doc["animations"].append(anim)
# Use frame-zero idle as the unanimated display pose.
rest,trans=sample("idle",0,120)
for n,r in rest.items(): nodes[names[n]]["rotation"]=r.as_quat().tolist()
for n,t in trans.items(): nodes[names[n]]["translation"]=t
while len(blob)%4:blob.append(0)
doc["buffers"]=[dict(byteLength=len(blob))]
js=json.dumps(doc,separators=(",",":")).encode()
js+=b" "*((-len(js))%4)
OUT.parent.mkdir(parents=True,exist_ok=True)
OUT.write_bytes(struct.pack("<4sII",b"glTF",2,28+len(js)+len(blob))+struct.pack("<I4s",len(js),b"JSON")+js+
    struct.pack("<I4s",len(blob),b"BIN\0")+blob)
print(OUT, len(nodes),"nodes,",sum(map(len,geo.values())),"triangles")

