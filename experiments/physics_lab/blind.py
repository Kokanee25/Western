# blind.py A_ROOT B_ROOT OUT_DIR SEED (the lab's blind pairwise judge, 2026-10-21): for each fall in both, a sheet of A and one of B stacked in a
# random order (X above, Y below), unlabelled; the key in OUT_DIR/../key_<name>.json (not for the judge).
import sys,os,glob,json,random,subprocess
from PIL import Image,ImageDraw
a,b,out,seed=sys.argv[1],sys.argv[2],sys.argv[3],int(sys.argv[4])
# (an optional fifth: the sheet's times, s from the hit; 2026-10-24)
os.makedirs(out,exist_ok=True); os.makedirs(out.rstrip('/')+'_unblind',exist_ok=True); rnd=random.Random(seed); key={}
cmp=os.path.join(os.path.dirname(os.path.abspath(__file__)),'compare.py')
T=sys.argv[5] if len(sys.argv)>5 else '0,0.18,0.38,0.68,0.98,1.48,2.48,3.98,5.98'
for d in sorted(glob.glob(a+'/*/frames')):
    n=os.path.basename(os.path.dirname(d))
    if not os.path.isdir(os.path.join(b,n,'frames')): continue
    ims=[]
    for r in (a,b):
        p=os.path.join(out.rstrip('/')+'_unblind','%s_%s.png')%(os.path.basename(r.rstrip('/')),n)
        subprocess.run(['python3',cmp,'sheet',os.path.join(r,n),'--times='+T,'--out='+p],capture_output=True)
        im=Image.open(p).convert('RGB'); im=im.crop((0,18,im.width,im.height)); im.thumbnail((1800,1800)); ims.append(im)
    order=[0,1]; rnd.shuffle(order)
    key[n]={'X':['A','B'][order[0]],'Y':['A','B'][order[1]]}
    w=max(i.width for i in ims); h=sum(i.height for i in ims)+40
    c=Image.new('RGB',(w,h),'black'); dr=ImageDraw.Draw(c); y=0
    for lab,i in zip('XY',order):
        dr.text((5,y+2),lab,fill='yellow'); c.paste(ims[i],(0,y+20)); y+=ims[i].height+20
    # hide the sheet's own title line (it names the run): paint over each sheet's top strip
    c.save(os.path.join(out,'pair_%03d.png'%len(key)))
    key[n]['file']='pair_%03d.png'%len(key)
json.dump(key,open(os.path.join(os.path.dirname(out.rstrip('/')),'key_'+os.path.basename(out.rstrip('/'))+'.json'),'w'),indent=1)
print(len(key),'pairs')
