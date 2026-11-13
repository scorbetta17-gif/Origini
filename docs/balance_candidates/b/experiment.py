"""Deterministic surrogate experiment; no Godot or save access. Python stdlib only."""
import json, math, random
from pathlib import Path

HERE = Path(__file__).resolve().parent
C = json.loads((HERE / 'config.json').read_text(encoding='utf-8'))
STATS = list(C['gains'])
HABITATS = {
    'prey_rich': {'attack': .55, 'motility': .18, 'vitality': .12, 'metabolism': .15},
    'exposed_reef': {'defense': .48, 'vitality': .32, 'uptake': .10, 'metabolism': .10},
    'nutrient_mat': {'uptake': .60, 'metabolism': .30, 'vitality': .10},
    'fragmented_patches': {'motility': .65, 'metabolism': .20, 'uptake': .15},
    'lean_vent': {'metabolism': .60, 'uptake': .20, 'defense': .10, 'vitality': .10},
}
ARCHETYPES = {
    'predator': {'attack': .60, 'motility': .20, 'vitality': .20},
    'defender': {'defense': .60, 'vitality': .40},
    'grazer': {'uptake': .65, 'metabolism': .35},
    'disperser': {'motility': .75, 'metabolism': .25},
    'economist': {'metabolism': .70, 'uptake': .20, 'defense': .10},
    'hybrid_hunter': {'attack': .35, 'defense': .25, 'motility': .20, 'metabolism': .20},
    'hybrid_grazer': {'uptake': .35, 'defense': .30, 'vitality': .15, 'metabolism': .20},
    'generalist': {s: 1 / 7 for s in STATS},
    'mutation_rush': {'mutation': .70, 'uptake': .15, 'metabolism': .15},
}

def phenotype(investment):
    out = {}
    for s in STATS:
        penalty = sum(C['tradeoffs'].get(t, {}).get(s, 0) * (investment.get(t, 0) / 40) ** 1.3 for t in STATS)
        value = 1 + C['gains'][s] * (1 - math.exp(-investment.get(s, 0) / 20)) - penalty
        out[s] = min(C['caps'][s], max(C['floors'][s], value))
    return out

def fitness(p, habitat):
    return math.exp(sum(w * math.log(p[s]) for s, w in HABITATS[habitat].items()))

def qualifies(own_count, rival_counts, area):
    if area <= 0:
        raise ValueError('Area must be positive km2')
    strongest = max(rival_counts, default=0)
    return own_count / area >= 30 and (strongest == 0 or own_count >= 1.5 * strongest)

def run():
    rng = random.Random(20261113)
    report = {'seed': 20261113, 'model': 'weighted geometric habitat fitness surrogate', 'budgets': {}}
    for budget in [10, 40, 80, 160, 240]:
        allocations = {name: {s: budget * weights.get(s, 0) for s in STATS} for name, weights in ARCHETYPES.items()}
        for n in range(2500):
            weights = [rng.expovariate(1) for _ in STATS]
            allocations[f'random_{n}'] = {s: budget * w / sum(weights) for s, w in zip(STATS, weights)}
        phenotypes = {name: phenotype(a) for name, a in allocations.items()}
        scores = {name: {h: fitness(p, h) for h in HABITATS} for name, p in phenotypes.items()}
        winners = {h: max(scores, key=lambda name: scores[name][h]) for h in HABITATS}
        assert len(set(winners.values())) > 1, 'Sample has universal habitat winner'
        for p in phenotypes.values():
            assert all(C['floors'][s] <= p[s] <= C['caps'][s] for s in STATS)
        counters = {}
        for name in ARCHETYPES:
            # A counter here means a better ecological competitor in >=1 habitat, not a combat kill.
            h, rival = max(((h, winners[h]) for h in HABITATS), key=lambda pair: scores[pair[1]][pair[0]] / scores[name][pair[0]])
            ratio = scores[rival][h] / scores[name][h]
            assert ratio > 1.001
            counters[name] = {'habitat': h, 'competitor': rival, 'fitness_ratio': round(ratio, 4)}
        report['budgets'][budget] = {
            'build_count': len(allocations), 'habitat_winners': winners,
            'specialists': {n: {'stats': phenotypes[n], 'fitness': scores[n]} for n in ARCHETYPES},
            'counter_examples': counters,
            'all_stats_above_baseline': sum(all(v > 1 for v in p.values()) for p in phenotypes.values()),
            'universal_habitat_winner': len(set(winners.values())) == 1,
        }
    # Boundary tests use real density/count arithmetic, independent of fitness.
    assert qualifies(30, [20, 19], 1)
    assert not qualifies(29, [1], 1)
    assert not qualifies(30, [21], 1)
    assert qualifies(60, [40, 39], 2)
    assert not qualifies(60, [41], 2)
    assert qualifies(30, [], 1)
    assert not qualifies(0, [], 1)
    # Increasing marginal cost before floors: superlinear penalty grows >2x from 20 to40.
    assert (40 / 40) ** 1.3 > 2 * (20 / 40) ** 1.3
    report['niche_boundary_cases_passed'] = 7
    report['pace'] = {
        'assumptions': '240 points; 2 base points per controlled-lineage division; 180..300s/division; +45..90min ecological stabilization/travel, sequential assumption',
        'fastest_minutes': 240 / (2 * 1.5) * 3 + 45,
        'unboosted_slow_minutes': 240 / 2 * 5 + 90,
        'warning': 'Analytic design estimate, not observed game duration. Spending on mutation has opportunity cost; no NPC multiplication reward.'
    }
    (HERE / 'results.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
    print(json.dumps({'status': 'PASS', 'builds': 2509 * 5, 'niche_cases': 7, 'pace': report['pace']}))

if __name__ == '__main__':
    run()
