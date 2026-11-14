"""Seed-for-seed differences of two runs (B - A): shooting length and hits on you. python3 pairs.py RUN_A RUN_B"""
import json,glob,os,sys,statistics as st
def load(r):
    return {os.path.basename(p):json.load(open(p)) for p in glob.glob(r+'/fights/*.json')}
def last(r):
    s=[float(e[0]) for e in r.get('timeline',[]) if e[1]=='shot']; return max(s) if s else 0.0
a=load(sys.argv[1]);b=load(sys.argv[2])
ks=[k for k in a if k in b]
for name,f in [('shooting',last),('hits on you',lambda r:int(r['you'].get('hits_taken',0)))]:
    d=[f(b[k])-f(a[k]) for k in ks]
    print(name,'n',len(d),'mean diff %.2f se %.2f'%(st.mean(d),st.stdev(d)/len(d)**.5),'longer',sum(x>0 for x in d),'shorter',sum(x<0 for x in d),'same',sum(x==0 for x in d))
