| scenario | steps | why it stopped | cloth at the end | faults (below floor / in bar / flung / lost) | brain ms | cloth ms |
|---|---|---|---|---|---|---|
| cycle | idle@0 take@6 lay@7 wipe@8 move@15 wipe@15 move@21 wipe@21 move@28 wipe@29 glass@36 put_back@41 idle@42 | done | shoulder | 0 / 0 / 2 / 0 | 0.061 | 0.010 |
| customer | idle@0 take@6 lay@7 wipe@8 put_back@14 idle@14 take@33 lay@33 wipe@35 move@39 wipe@40 | customer | hand | 0 / 0 / 0 / 0 | 0.052 | 0.010 |
| trouble | idle@0 take@6 lay@7 wipe@8 idle@12 fetch@25 put_back@26 idle@26 take@32 lay@32 wipe@34 move@38 wipe@39 | fetched | hand | 0 / 0 / 0 / 0 | 0.043 | 0.006 |
| dropped | idle@0 take@6 lay@7 wipe@8 idle@12 fetch@13 put_back@14 idle@14 take@19 lay@20 wipe@22 move@26 wipe@27 move@33 wipe@34 | fetched | hand | 0 / 0 / 0 / 0 | 0.071 | 0.009 |
| blast | idle@0 fetch@17 put_back@19 idle@19 take@25 lay@25 wipe@27 | fetched | hand | 0 / 0 / 2 / 0 | 0.057 | 0.008 |
| burn | idle@0 take@6 lay@7 wipe@8 idle@12 | trouble | free, burnt | 0 / 0 / 1 / 0 | 0.112 | 0.052 |
| blood | idle@0 take@6 lay@7 wipe@8 idle@12 | trouble | hand, blood 5.7 ml | 0 / 0 / 2 / 0 | 0.040 | 0.012 |
