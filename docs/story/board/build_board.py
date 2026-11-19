#!/usr/bin/env python3
"""Builds missions.json for the mission board page (missions_board.html) from docs/story/MISSIONS.md
and docs/story/missions/*.md. Run from the repo root: python3 docs/story/board/build_board.py OUT.json
The JSON is not committed: build it, then publish the page with it (docs/story/README.md, "The mission board")."""
import re, json, sys, glob, html, datetime, os

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
FRONT = os.path.join(ROOT, 'MISSIONS.md')


def inline(t):
    t = html.escape(t, quote=False)
    t = re.sub(r'\[([^\]]+)\]\([^)]*\)', r'\1', t)          # links: keep the words
    t = re.sub(r'\*\*(.+?)\*\*', r'<b>\1</b>', t)
    t = re.sub(r'`([^`]+)`', r'<code>\1</code>', t)
    t = re.sub(r'(?<![\w*])\*([^*\n]+)\*(?![\w*])', r'<i>\1</i>', t)
    return t


def blocks(md):
    """Markdown fragment -> [{t: 'p'|'li'|'h', n: marker, x: html}], list items with their continuation lines."""
    out, cur = [], None
    def flush():
        nonlocal cur
        if cur:
            cur['x'] = inline(' '.join(cur.pop('lines')).strip())
            if cur['x']:
                out.append(cur)
        cur = None
    for line in md.strip('\n').split('\n'):
        s = line.strip()
        if not s:
            flush(); continue
        m = re.match(r'^(\s*)(\d+)\.\s+(.*)$', line)
        b = re.match(r'^(\s*)[-*]\s+(.*)$', line)
        if re.match(r'^#{2,6}\s', s):
            flush(); out.append({'t': 'h', 'x': inline(re.sub(r'^#+\s*', '', s))}); continue
        if m and len(m.group(1)) < 4:
            flush(); cur = {'t': 'li', 'n': m.group(2) + '.', 'lines': [m.group(3)]}; continue
        if b:
            flush(); cur = {'t': 'li', 'n': '', 'd': min(len(b.group(1)) // 2, 2), 'lines': [b.group(2)]}; continue
        if re.match(r'^\*[^*].*\*$', s) and cur is None:
            out.append({'t': 'h', 'x': inline(s.strip('*'))}); continue
        if cur is None:
            cur = {'t': 'p', 'lines': [s]}
        elif line.startswith(' ') or cur['t'] == 'p':
            cur['lines'].append(s)
        else:
            flush(); cur = {'t': 'p', 'lines': [s]}
    flush()
    return out


def fields(sec):
    return [(k.strip(), v.strip()) for k, v in re.findall(r'(?ms)^\*\*([^*:\n]+):\*\*(.*?)(?=^\*\*[^*:\n]+:\*\*|\Z)', sec)]


SCRIPTS = {'the-sheriff': 'sheriff_road', 'no-law': 'no_law', 'no-justice': 'no_justice'}


def script_section(mission_id):
    """The mission's whole script (docs/scripts/<name>.json) as blocks: a heading a scene, a line a block.
    A line's note is keyed by its script and line id, so it stays on the line however the script is reordered.
    No Law's copy of the sheriff's last day shares its keys with the sheriff's script: one note, shown in both."""
    name = SCRIPTS.get(mission_id)
    path = os.path.join(ROOT, '..', 'scripts', '%s.json' % name) if name else None
    if not path or not os.path.exists(path):
        return None
    d = json.load(open(path))
    cast = {c['id']: (c.get('called') or c.get('name') or c['id']) for c in d['cast']}
    out = []
    for sc in d['scenes']:
        built = 'in the game' if sc.get('built') is True else ('partly in the game' if sc.get('built') else 'not in the game yet')
        out.append({'t': 'h', 'x': inline('%s. %s (%s)' % (sc['title'], sc.get('when', ''), built))})
        owner = 'sheriff_road' if (name == 'no_law' and sc['id'] == 'day2') else name
        if sc.get('setting'):
            out.append({'t': 'p', 'x': inline(sc['setting']), 'key': 's.%s.scene.%s' % (owner, sc['id'])})
        for l in sc['lines']:
            who = cast.get(l['speaker'], l['speaker']).split(',')[0].strip() or l['speaker']
            words = []
            for w in l['words']:
                t = '(a breath, no words)' if w['text'].strip() == '...' else html.escape(w['text'], quote=False)
                words.append(t + (' <span class="tag">in the game</span>' if w.get('status') == 'built' else ''))
            x = '<b>%s</b><br>' % html.escape(who.upper(), quote=False) + '<br>'.join('<span class="say">%s</span>' % w for w in words)
            meta = []
            if l.get('trigger'):
                meta.append('When: ' + html.escape(l['trigger'], quote=False))
            if l.get('when') and l['when'] != 'any':
                meta.append('If: ' + html.escape(l['when'], quote=False))
            if l.get('delivery'):
                meta.append('How: ' + html.escape(l['delivery'], quote=False))
            if l.get('note'):
                meta.append(html.escape(l['note'], quote=False))
            x += '<span class="meta">' + ' · '.join(meta) + '</span>'
            out.append({'t': 'li', 'n': '', 'x': x, 'key': 's.%s.%s' % (owner, l['id'])})
    return {'k': 'script', 'label': 'The script, line by line', 'blocks': out}


def slug_of(title):
    m = re.search(r'\(`([^`]+)`\)', title)
    s = m.group(1) if m else re.sub(r'[^a-z0-9]+', '-', title.lower()).strip('-')[:40]
    return s


def main(out):
    front = open(FRONT).read()
    # the top sections of the front page (everything before the table), each as blocks
    top = []
    for sec in re.split(r'(?m)^(?=## )', front):
        if not sec.startswith('## '):
            continue
        title = sec.split('\n')[0][3:].strip()
        if title.startswith('The whole game on one screen') or title.startswith('Act '):
            continue
        top.append({'id': re.sub(r'[^a-z0-9]+', '-', title.lower()).strip('-')[:32], 'title': title,
                    'blocks': blocks(sec.split('\n', 1)[1])})
    # the missions, from the full record (it has every field)
    acts, seen = [], {}
    names = {'1_opening.md': 'Act I: becoming the law', '2_act1_open.md': 'Act I: open once he has the badge',
             '3_act2.md': 'Act II: learning the valley', '4_act3.md': 'Act III: the conspiracy shows',
             '5_act4_sides.md': 'Act IV, the ending, side missions and set pieces'}
    for fn in sorted(glob.glob(os.path.join(ROOT, 'missions', '[1-5]_*.md'))):
        act = {'title': names[os.path.basename(fn)], 'missions': []}
        for sec in re.split(r'(?m)^(?=### |## )', open(fn).read()):
            if not (sec.startswith('### ') or sec.startswith('## ')):
                continue
            title = sec.split('\n')[0].lstrip('# ').strip()
            sid = slug_of(title)
            if sid in seen:
                sid += '-2'
            seen[sid] = 1
            fs = fields(sec)
            m = {'id': sid, 'title': re.sub(r'\s*\(`[^`]*`\)', '', title), 'sections': []}
            if fs and any(k.lower().startswith('in one line') for k, _ in fs):
                for k, v in fs:
                    if k.lower().startswith('in one line'):
                        m['one'] = inline(re.sub(r'\s+', ' ', v))
                    else:
                        m['sections'].append({'k': re.sub(r'[^a-z0-9]+', '', k.lower())[:10], 'label': k, 'blocks': blocks(v)})
            else:
                m['one'] = ''
                m['sections'].append({'k': 'all', 'label': 'Notes gathered', 'blocks': blocks(sec.split('\n', 1)[1])})
                m['loose'] = True
            sc = script_section(sid)
            if sc:
                m['sections'].append(sc)
            act['missions'].append(m)
        acts.append(act)
    data = {'built': datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%d %H:%M UTC'), 'top': top, 'acts': acts}
    json.dump(data, open(out, 'w'), ensure_ascii=False)
    print(out, os.path.getsize(out), 'bytes;', sum(len(a['missions']) for a in acts), 'entries')


if __name__ == '__main__':
    main(sys.argv[1])
