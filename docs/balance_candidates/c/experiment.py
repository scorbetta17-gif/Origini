"""Deterministic design surrogate; no game imports or save access. Python stdlib only."""
import json, math, random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
C = json.loads((ROOT / 'config.json').read_text())
STATS = list(C['gains'])
HABITATS = {
    'ricco': dict(food=1.35, travel=.40, danger=.15, prey=.05),
    'povero': dict(food=.78, travel=.60, danger=.18, prey=.04),
    'disperso': dict(food=.90, travel=1.00, danger=.20, prey=.12),
    'predatori': dict(food=1.00, travel=.55, danger=.80, prey=.10),
    'prede': dict(food=.65, travel=.75, danger=.35, prey=.85),
}

def phenotype(x):
    return {s: max(C['floors'][s], min(C['caps'][s], 1+C['gains'][s]*(1-math.exp(-x[s]/20))
        -sum(C['tradeoffs'].get(t, {}).get(s, 0)*(x[t]/40)**1.3 for t in STATS))) for s in STATS}

def score(x, h):
    p = phenotype(x)
    # Independent capacity charge persists when phenotype penalties reach floors.
    upkeep = .10 + .0018*sum(x.values()) + .000024*sum(v*v for v in x.values())
    movement = .18*h['travel']*p['motility']*(1+.30*max(0,(p['motility']-1)/.6)**2)/math.sqrt(p['metabolism'])
    intake = .85*h['food']*p['uptake']*(.65+.35*p['motility'])
    hunting = .35*h['prey']*p['attack']*math.sqrt(p['motility'])
    net = (intake+hunting)*p['metabolism']-upkeep-movement
    survival = math.exp(-h['danger']/(p['defense']*p['vitality']))
    return max(0, net)*survival

def builds(budget, rng):
    yield 'balanced', dict.fromkeys(STATS, budget/7)
    for s in STATS:
        yield s, {t: budget if s==t else 0 for t in STATS}
    for i,s in enumerate(STATS):
        for t in STATS[i+1:]:
            yield s+'+'+t, {k: budget/2 if k in (s,t) else 0 for k in STATS}
    for i in range(10000):
        weights = [rng.expovariate(1) for _ in STATS]
        yield 'random_'+str(i), {s: budget*w/sum(weights) for s,w in zip(STATS, weights)}

def main():
    rng = random.Random(20261113)
    result = {'seed':20261113, 'kind':'analytic surrogate, NOT Godot runtime', 'budgets':{}}
    for budget in (10,30,60,120,240):
        candidates = list(builds(budget, rng))
        checks = 0
        for _,x in candidates:
            p=phenotype(x)
            assert 1 <= p['mutation'] <= 1.5
            assert all(C['floors'][s] <= p[s] <= C['caps'][s] for s in STATS)
            checks += 1
        rows={}
        for name,h in HABITATS.items():
            ranked=sorted(((score(x,h),label,x) for label,x in candidates), reverse=True)
            best,label,x=ranked[0]
            rows[name]={'winner':label,'score':round(best,4),'investment':{s:round(v,2) for s,v in x.items()},
                'phenotype':{s:round(v,3) for s,v in phenotype(x).items()},
                'baseline_score':round(score(dict.fromkeys(STATS,0),h),4),
                'starved_fraction':round(sum(v[0]==0 for v in ranked)/len(ranked),4),
                'balanced_score':round(score(dict.fromkeys(STATS,budget/7),h),4)}
        result['budgets'][budget]={'tested_builds':checks,'habitats':rows,
            'all_six_above_1_2':sum(all(phenotype(x)[s]>1.2 for s in STATS if s!='mutation') for _,x in candidates)}
    # Pacing is explicitly a designed target, not measured engine time.
    phases=[('prima_discendenza_LUCA',12,90),('diversificazione',20,120),('consorzio',24,150),('integrazione_LECA',24,180)]
    result['pacing']={'base_points_per_division':2,'phases':[dict(name=n,divisions=d,seconds_per_division=s,minutes=d*s/60) for n,d,s in phases],
        'total_minutes':sum(d*s/60 for _,d,s in phases),'total_base_points':160,
        'first_division_target_seconds':[60,120], 'note':'80 successful divisions plus exploration/failure; innovation gates required independently of points'}
    assert result['pacing']['total_minutes']==190
    # Exact dominance boundaries; units are cells per simulated km2.
    dominant=lambda n,r: n>=30 and n>=1.5*r
    assert dominant(30,20) and not dominant(29.999,0) and not dominant(30,20.001)
    result['checks']='PASS: 50145 builds, 250725 habitat evaluations, bounds and dominance edges'
    (ROOT/'results.json').write_text(json.dumps(result,indent=2)+'\n')
    print(result['checks'])
    for b,data in result['budgets'].items():
        print(b, {h:(v['winner'],v['score'],v['starved_fraction']) for h,v in data['habitats'].items()},'supercells',data['all_six_above_1_2'])

if __name__=='__main__': main()
