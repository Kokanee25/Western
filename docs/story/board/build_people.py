#!/usr/bin/env python3
"""Builds people_board.json for the People board (people_board.html) from docs/story/people.json (the sheets)
and config/valley_folk.json (each man's day). Run from the repo root:
    python3 docs/story/board/build_people.py OUT.json      # the page's data (not committed)
    python3 docs/story/board/build_people.py --check        # ids, places and line ids only
Then publish the page with it (docs/story/README.md, "The people board").

A person's `hash` is of his sheet's own fields (not `notes`, not his day): the page's Person OK stores the hash it
was tapped on, so an OK counts only while the sheet is as it was. Lines of the town's script that carry a person
(`who`) and a place tag (`place`), as #1293 adds them, are shown on his page and the place's, outside the hash."""
import hashlib, json, os, sys, datetime

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, '..', '..', '..')
PEOPLE = os.path.join(HERE, '..', 'people.json')
FOLK = os.path.join(ROOT, 'config', 'valley_folk.json')
TOWN = os.path.join(ROOT, 'docs', 'scripts', 'town.json')

SHORT = {'saloon.bar': "the saloon's bar", 'saloon.table': "the saloon's tables", 'saloon.room': "the saloon's piano corner",
         'saloon.upstairs': 'over the saloon', 'store': 'the general store', 'street': 'the street', 'livery': 'the livery',
         'hotel': 'the hotel', 'church': 'the church', 'graveyard': 'the graveyard', 'doctor': "the doctor's",
         'smithy': 'the smithy', 'undertaker': "the undertaker's shop", 'print_shop': "the Clarion's office",
         'jail': 'the jail', 'depot': 'the depot', 'out': 'out of town'}
LOTS = {'general_store': 'store', 'hotel': 'hotel', 'livery': 'livery', 'blacksmith': 'smithy', 'undertaker': 'undertaker',
        'doctor': 'doctor'}
DOING = {'sleep': 'asleep', 'away': 'away', 'home': 'at home', 'work': 'working', 'breakfast': 'at breakfast',
         'dinner': 'at dinner', 'supper': 'at supper', 'counter': 'behind the bar', 'drink': 'drinking', 'play': 'playing',
         'talk': 'talking', 'lean': 'leaning', 'stand': 'standing about', 'sit': 'sitting', 'sweep': 'sweeping',
         'carry': 'carrying freight', 'errand': 'on an errand'}
KINDS = {'ordinary': 'An ordinary day', 'sunday': 'Sunday', 'payday': 'A payday (every second Saturday)',
         'uneasy': 'The day after a killing or a shooting'}
GONE = ('sleep', 'away')          # not somewhere he can be met
HASHED = ('kind', 'role', 'name', 'called', 'who', 'age', 'born', 'from', 'came', 'work', 'place', 'wants', 'secret',
          'likes', 'dislikes', 'habit', 'talks', 'voice', 'body', 'clothes', 'lines', 'seen', 'day_proposed', 'fixed',
          'in_town', 'circle', 'home', 'if_dies', 'knows', 'trouble', 'harlan', 'jobs', 'looks', 'casting', 'owns', 'week',
          'loyalty')


def spot_place(name, spots):
    """A named spot (valley_folk.json `spots`) -> a place tag."""
    s = spots.get(name) or {}
    if 'chair' in s:
        return 'saloon.room' if 'piano' in s['chair'] else 'saloon.table'
    if s.get('hall') == 'saloon':
        if name.startswith('bar_') or name == 'room_bar_end':
            return 'saloon.bar'
        if name.startswith('room_talk'):
            return 'saloon.table'
        return 'saloon.room'
    return LOTS.get(s.get('lot'), 'street')


def in_place(where, do):
    """A block's `in` (a building, or a way out of town) -> a place tag."""
    if where == 'saloon':
        return 'saloon.upstairs'
    if where.startswith('ns@'):
        return 'church'
    if '@' in where or where.endswith('_back'):
        return 'out'
    return LOTS.get(where, 'street')


def legs(block, spots):
    """One day block -> [(place, do)], a round's legs each."""
    out = []
    for leg in (block.get('round') or [block]):
        do = leg.get('do') or block.get('do') or ''
        if leg.get('at'):
            out.append((spot_place(leg['at'], spots), do))
        elif leg.get('in'):
            out.append((in_place(leg['in'], do), do))
    return out


def clock(h):
    h = h % 24
    m = int(round((h - int(h)) * 60))
    hh = int(h)
    ap = 'am' if hh < 12 else 'pm'
    h12 = hh % 12 or 12
    if m == 0 and hh == 12:
        return 'noon'
    if m == 0 and hh == 0:
        return 'midnight'
    return ('%d:%02d %s' % (h12, m, ap)) if m else ('%d %s' % (h12, ap))


def span(a, b):
    return clock(a) + ' to ' + clock(b)


def day_kinds(man):
    d = man.get('day')
    if not d:
        return {}
    return {'ordinary': d} if isinstance(d, list) else d


def blocks_of(day):
    """[(from, to, block)], the last running round to the first."""
    bl = sorted(day, key=lambda b: b['from'])
    return [(b['from'], bl[(i + 1) % len(bl)]['from'], b) for i, b in enumerate(bl)]


def day_words(day, spots):
    rows = []
    for a, b, blk in blocks_of(day):
        by = {}                                   # place -> what he does there, in order
        for place, do in legs(blk, spots):
            by.setdefault(place, [])
            if do not in by[place]:
                by[place].append(do)
        parts = []
        for place, dos in by.items():
            if dos == ['away']:
                parts.append('away, out of town' if place == 'out' else 'up at ' + SHORT[place])
            else:
                parts.append(SHORT[place] + ': ' + ', '.join(DOING.get(d, d) for d in dos))
        rows.append({'h': span(a, b), 'what': '; '.join(parts)})
    return rows


def hours_at(day, spots):
    """{place: [(from, to)]} for where he can be met, ranges merged, hours 0-24 from the day's start."""
    out = {}
    for a, b, blk in blocks_of(day):
        for place, do in legs(blk, spots):
            if do in GONE:
                continue
            out.setdefault(place, []).append((a, b))
    for place, rs in out.items():
        rs = sorted(set(rs))
        merged = [list(rs[0])]
        for a, b in rs[1:]:
            if a == merged[-1][1]:
                merged[-1][1] = b
            else:
                merged.append([a, b])
        out[place] = merged
    return out


def unwrap(rs):
    """Ranges as plain intervals on a 0-48 line (a range past midnight wraps)."""
    out = []
    for a, b in rs:
        if b <= a:
            b += 24
        out += [(a, b), (a + 24, b + 24), (a - 24, b - 24)]
    return out


def overlap(r1, r2):
    best = None
    for a, b in [(x, y if y > x else y + 24) for x, y in r1]:
        for c, d in unwrap(r2):
            lo, hi = max(a, c), min(b, d)
            if hi - lo > 0.01 and (best is None or hi - lo > best[1] - best[0]):
                best = (lo, hi)
    return best


def sheet_hash(p):
    body = {k: p.get(k) for k in HASHED}
    return hashlib.sha1(json.dumps(body, sort_keys=True, ensure_ascii=False).encode('utf-8')).hexdigest()[:12]


def check(people, folk):
    errs = []
    P, places, al = people['people'], people['places'], people.get('aliases', {})
    for man in folk['people']:
        if man['id'] not in P and man['id'] not in al:
            errs.append('roster id with no sheet: ' + man['id'])
    for a, b in al.items():
        if b not in P:
            errs.append('alias to a missing sheet: %s -> %s' % (a, b))
    seen = set()
    for pid, p in P.items():
        for k in ('kind', 'role', 'who', 'talks', 'lines', 'fixed'):
            if k not in p:
                errs.append('%s: no %s' % (pid, k))
        for rel in ('likes', 'dislikes'):
            for r in p.get(rel) or []:
                if r['id'] not in P:
                    errs.append('%s: %s an unknown id %s' % (pid, rel, r['id']))
        for ln in p.get('lines') or []:
            if ln['id'] in seen:
                errs.append('line id twice: ' + ln['id'])
            seen.add(ln['id'])
            if ln['place'] not in places:
                errs.append('%s: unknown place %s' % (ln['id'], ln['place']))
            if ln.get('to') and ln['to'] not in P:
                errs.append('%s: to an unknown id %s' % (ln['id'], ln['to']))
        for ln in (p.get('if_dies') or {}).get('lines') or []:
            if ln['id'] in seen:
                errs.append('line id twice: ' + ln['id'])
            seen.add(ln['id'])
            if ln['by'] not in P:
                errs.append('%s: by an unknown id %s' % (ln['id'], ln['by']))
        if p.get('home') and p['home'].get('state') not in ('built', 'to be built'):
            errs.append('%s: home.state is built or to be built' % pid)
        for s in p.get('seen') or []:
            if s['place'] not in places:
                errs.append('%s: seen at an unknown place %s' % (pid, s['place']))
        if p.get('kind') == 'townsfolk' and not p.get('name'):
            errs.append('%s: a townsperson with no name' % pid)
    for group in ('stranger', 'rider', 'outlaw'):
        for ln in (people.get('nobody_knew') or {}).get(group) or []:
            if ln['by'] not in P:
                errs.append('%s: by an unknown id %s' % (ln['id'], ln['by']))
    return errs


def build():
    people = json.load(open(PEOPLE, encoding='utf-8'))
    folk = json.load(open(FOLK, encoding='utf-8'))
    errs = check(people, folk)
    if errs:
        sys.exit('people.json:\n  ' + '\n  '.join(errs))
    P, places, spots = people['people'], people['places'], folk['spots']
    roster = {m['id']: m for m in folk['people']}
    also = {}
    for a, b in people.get('aliases', {}).items():
        also.setdefault(b, []).append(a)

    # The town's script lines that carry a person and a place (#1293 adds them).
    # A line with `ex` is one turn of an overheard exchange (#1293): shown whole, in order, on each
    # speaker's page under its place and in the place's own view; `story` ones wait on Sean's OK.
    script, exchanges = {}, {}
    if os.path.exists(TOWN):
        for sc in json.load(open(TOWN, encoding='utf-8')).get('scenes', []):
            for ln in sc.get('lines', []):
                if ln.get('who') in P and ln.get('place') in places:
                    w = ln.get('words')
                    w = w if isinstance(w, str) else (w[0].get('text') if w and isinstance(w[0], dict) else (w[0] if w else ''))
                    row = {'id': ln['id'], 'place': ln['place'], 'words': w, 'to': ln.get('to'), 'when': ln.get('when'),
                           'src': 'town'}
                    if ln.get('ex'):
                        row.update({'ex': ln['ex'], 'delivery': ln.get('delivery') or '', 'story': bool(ln.get('story')),
                                    'pid': ln['who']})
                        e = exchanges.setdefault(ln['ex'], {'id': ln['ex'], 'place': ln['place'], 'when': ln.get('when') or '',
                                                            'story': bool(ln.get('story')), 'cast': [], 'lines': []})
                        e['lines'].append(row)
                        if ln['who'] not in e['cast']:
                            e['cast'].append(ln['who'])
                    script.setdefault(ln['who'], []).append(row)

    hours = {pid: hours_at(day_kinds(roster[pid]).get('ordinary') or [], spots) if pid in roster and day_kinds(roster[pid]) else {}
             for pid in P}
    label = lambda pid: P[pid].get('name') or P[pid]['role']
    out_people, by_place = {}, {t: {'place': t, 'label': places[t], 'who': [], 'lines': [],
                                    'exchanges': [e for e in exchanges.values() if e['place'] == t]} for t in places}
    for pid, p in P.items():
        man = roster.get(pid)
        kinds = day_kinds(man) if man else {}
        q = {k: p.get(k) for k in HASHED}
        q.update({'id': pid, 'hash': sheet_hash(p), 'notes': p.get('notes'), 'in_valley': pid in roster,
                  'roster_ids': [pid] + also.get(pid, []) if pid in roster else [],
                  'dials': (man or {}).get('dials'),
                  'day': [{'kind': k, 'label': KINDS.get(k, k), 'rows': day_words(v, spots)} for k, v in kinds.items()]})
        lines = (p.get('lines') or []) + script.get(pid, [])
        q['lines'] = lines
        tags = list(hours[pid].keys())
        for s in p.get('seen') or []:
            if s['place'] not in tags:
                tags.append(s['place'])
        for ln in lines:
            if ln['place'] not in tags:
                tags.append(ln['place'])
        tags.sort(key=lambda t: list(places).index(t))
        groups = []
        for t in tags:
            rs = hours[pid].get(t)
            seen = [s['when'] for s in p.get('seen') or [] if s['place'] == t]
            when = ', '.join(span(a, b) for a, b in rs) if rs else ('; '.join(seen) if seen else 'not in his day yet')
            if rs and seen:
                when += ' (' + '; '.join(seen) + ')'
            mates = []
            for oid in P:
                if oid == pid:
                    continue
                o = overlap(rs, hours[oid].get(t) or []) if rs and hours[oid].get(t) else None
                told = any(ln.get('to') == oid and ln['place'] == t for ln in lines) or \
                    any(ln.get('to') == pid and ln['place'] == t for ln in (P[oid].get('lines') or []))
                if o or told:
                    mates.append({'id': oid, 'name': label(oid), 'hours': span(*o) if o else ''})
            mine = [ln for ln in lines if ln['place'] == t]
            groups.append({'place': t, 'label': places[t], 'when': when, 'with': mates, 'lines': mine,
                           'exchanges': [e for e in exchanges.values() if e['place'] == t and pid in e['cast']]})
            by_place[t]['who'].append({'id': pid, 'name': label(pid), 'role': p['role'], 'when': when, 'n': len(mine)})
            for ln in mine:
                by_place[t]['lines'].append(dict(ln, pid=pid))
        q['groups'] = groups
        q['more'] = pid in (people.get('more_done') or [])
        for ln in (q.get('if_dies') or {}).get('lines') or []:
            ln['by_name'] = label(ln['by'])
        out_people[pid] = q
    return {'built': datetime.date.today().isoformat(), 'status': people.get('status'), 'assumed': people.get('assumed', []),
            'order': list(P.keys()), 'people': out_people,
            'nobody': {g: [dict(ln, by_name=label(ln['by'])) for ln in (people.get('nobody_knew') or {}).get(g) or []]
                       for g in ('stranger', 'rider', 'outlaw')},
            'homes': [{'id': pid, 'name': label(pid), 'what': p['home']['what'], 'state': p['home']['state'],
                       'where': p['home'].get('where', '')} for pid, p in P.items() if p.get('home')],
            'places': [v for v in by_place.values() if v['who']]}


if __name__ == '__main__':
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    if sys.argv[1] == '--check':
        errs = check(json.load(open(PEOPLE, encoding='utf-8')), json.load(open(FOLK, encoding='utf-8')))
        print('\n'.join(errs) if errs else 'people.json: ok')
        sys.exit(1 if errs else 0)
    data = build()
    json.dump(data, open(sys.argv[1], 'w', encoding='utf-8'), ensure_ascii=False)
    print('%d people, %d places, %d lines -> %s' % (len(data['people']), len(data['places']),
                                                    sum(len(p['lines']) for p in data['people'].values()), sys.argv[1]))
