"""Paired comparison: same 10,029 builds per budget, same energy/habitat model."""
import importlib.util, json, random
from pathlib import Path
ROOT=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('model',ROOT/'c'/'experiment.py')
m=importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
rng=random.Random(20261113)
samples={b:list(m.builds(b,rng)) for b in (10,30,60,120,240)}
out={'seed':20261113,'model':'same resource-budget surrogate and paired allocations; not engine playtest','candidates':{}}
original_phenotype=m.phenotype
def limited_phenotype(x):
    p=original_phenotype(x)
    positive=sum(max(0,p[s]-1) for s in m.STATS if s!='mutation')
    if positive>1.2:
        for s in m.STATS:
            if s!='mutation' and p[s]>1: p[s]=1+(p[s]-1)*1.2/positive
    return p
for candidate in ('a','b','c','b_capacity'):
    config=json.loads((ROOT/('b' if candidate=='b_capacity' else candidate)/'config.json').read_text())
    m.phenotype=limited_phenotype if candidate=='b_capacity' else original_phenotype
    if config.get('tradeoff_orientation','').startswith('target'):
        original=config['tradeoffs']; config['tradeoffs']={s:{} for s in m.STATS}
        for target,sources in original.items():
            for source,coefficient in sources.items(): config['tradeoffs'][source][target]=coefficient
    m.C=config
    rows={}
    for budget,builds in samples.items():
        phenotypes=[m.phenotype(x) for _,x in builds]
        winners={}
        for habitat,h in m.HABITATS.items():
            scores=[m.score(x,h) for _,x in builds]
            best=max(range(len(scores)), key=scores.__getitem__)
            winners[habitat]={'winner':builds[best][0],'score':round(scores[best],5),
                'starved_fraction':round(sum(s==0 for s in scores)/len(scores),5)}
        if candidate=='b_capacity':
            assert all(sum(max(0,p[s]-1) for s in m.STATS if s!='mutation')<=1.200000001 for p in phenotypes)
        rows[budget]={'all_six_above_1_2':sum(all(p[s]>1.200000001 for s in m.STATS if s!='mutation') for p in phenotypes),
            'unique_winners':len(set(w['winner'] for w in winners.values())),'habitats':winners}
    out['candidates'][candidate]=rows
(ROOT/'comparison_results.json').write_text(json.dumps(out,indent=2)+'\n')
for c,rows in out['candidates'].items():
    print(c, {b:{k:v for k,v in row.items() if k!='habitats'} for b,row in rows.items()})
print('PASS paired comparison: 200580 builds, 1002900 habitat evaluations; B capacity verified')
