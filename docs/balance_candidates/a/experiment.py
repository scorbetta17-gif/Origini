"""Deterministic surrogate experiment; no Godot gameplay claims. Python standard library only."""
import json, math, random
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parent
C = json.loads((ROOT / 'config.json').read_text())
STATS = list(C['gains'])
# Habitat weights are explicit design assumptions, not fitted biological measurements.
HABITATS = {
    'sparse_open_water': {'motility': .65, 'uptake': .25, 'metabolism': .10},
    'rich_substrate': {'uptake': .65, 'metabolism': .25, 'vitality': .10},
    'predation_front': {'attack': .60, 'motility': .25, 'vitality': .15},
    'exposed_refuge': {'defense': .55, 'vitality': .35, 'metabolism': .10},
    'energy_poor_vent': {'metabolism': .70, 'vitality': .15, 'uptake': .15},
}

def phenotype(investment):
    return {s: max(C['floors'][s], min(C['caps'][s], 1 + C['gains'][s] *
        (1-math.exp(-investment.get(s, 0)/20)) - sum(k * (investment.get(other, 0)/40)**1.3
        for other, k in C['tradeoffs'][s].items()))) for s in STATS}

def score(traits, weights):
    return math.exp(sum(w*math.log(traits[s]) for s, w in weights.items()))

def candidates(budget, rng):
    out = [('unspent', {})]
    for s in STATS:
        out.append((s, {s: budget}))
    for i, s in enumerate(STATS):
        for t in STATS[i+1:]:
            out.append((s+'+'+t, {s: budget/2, t: budget/2}))
    out.append(('generalist', {s: budget/len(STATS) for s in STATS}))
    for i in range(1200):
        values = [rng.expovariate(1) for _ in STATS]
        out.append(('random_'+str(i), dict(zip(STATS, [budget*v/sum(values) for v in values]))))
    return out

def main():
    rng = random.Random(131126)
    report = {'seed': 131126, 'model': 'weighted geometric habitat utility; not population simulation',
              'habitat_weights': HABITATS, 'budgets': {}}
    for budget in (10, 30, 60, 120, 240):
        builds = candidates(budget, rng)
        phenotypes = [phenotype(inv) for _, inv in builds]
        for p in phenotypes:
            assert all(C['floors'][s] <= p[s] <= C['caps'][s] for s in STATS)
            assert 1 <= p['mutation'] <= 1.5
        utilities = [[score(p, w) for w in HABITATS.values()] for p in phenotypes]
        winners = {hab: max(range(len(builds)), key=lambda i: utilities[i][h]) for h, hab in enumerate(HABITATS)}
        universal = [builds[i][0] for i in range(len(builds)) if all(
            utilities[i][h] >= max(row[h] for row in utilities)-1e-12 for h in range(5))]
        top_counts = Counter()
        for h in range(5):
            for i in sorted(range(len(builds)), key=lambda j: utilities[j][h], reverse=True)[:25]:
                inv = builds[i][1]
                top_counts[max(STATS, key=lambda s: inv.get(s, 0))] += 1
        report['budgets'][budget] = {
            'sample_size': len(builds),
            'winners': {hab: {'build': builds[i][0], 'investments': builds[i][1], 'utility': utilities[i][h]}
                        for h, (hab, i) in enumerate(winners.items())},
            'top25_per_habitat_dominant_investment_distribution': dict(top_counts),
            'universal_habitat_winners': universal,
            'all_seven_stats_above_baseline_count': sum(all(p[s]>1 for s in STATS) for p in phenotypes),
            'division_seconds_range': [max(75, 120/max(max(row) for row in utilities)),
                                       max(75, 120/min(min(row) for row in utilities))]
        }
        assert not universal, 'A sampled build wins every habitat'
    # Fractional credits must accumulate, never round 1.49 to two per division.
    credit = 0.0
    for _ in range(100): credit += phenotype({'mutation': 1000})['mutation']
    assert credit <= 150.000001
    report['pacing'] = {'minimum_24_divisions_minutes': 24*75/60,
                        'reference_24_divisions_minutes': 24*120/60,
                        'minimum_60_divisions_minutes': 60*75/60,
                        'reference_60_divisions_minutes': 60*120/60,
                        'max_points_per_100_divisions': credit}
    (ROOT / 'results.json').write_text(json.dumps(report, indent=2)+'\n')
    print(json.dumps({'passed': True, 'samples': 5*1230, 'universal_winners': 0, 'pacing': report['pacing']}))

if __name__ == '__main__': main()
