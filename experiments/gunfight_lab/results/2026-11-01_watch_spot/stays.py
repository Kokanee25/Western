#!/usr/bin/env python3
"""Why each stay behind cover ended, a run and opening: python3 stays.py RUN [RUN...] (run roots with fights/)."""
import json,glob,sys,collections,statistics as st
for run in sys.argv[1:]:
    for op in ["", "shoot"]:
        why=collections.Counter(); n=0; men=0; open_s=0.0; search_s=0.0; hunts_found=0
        for f in glob.glob(run+'/fights/*.json'):
            d=json.load(open(f))
            if d.get('opening','')!=op: continue
            for m in d['men'].values():
                if not m.get('fought'): continue
                men+=1
                for s in m.get('stays',[]):
                    n+=1; why[s['left'].split(':')[0]]+=1
                open_s+=m.get('open_waiting',0)+m.get('open_searching',0)+m.get('open_prone',0)
                search_s+=sum(1 for dd in m.get('decisions',[]) if 'look for you' in str(dd))
        print(run.split('/')[-1], op or 'they', 'stays',n, 'look for you',why['look for you'], 'top',why.most_common(6), 'open s/man %.1f'%(open_s/men), 'hunts/man %.2f'%(search_s/men))
