class_name Poker
extends RefCounted
## Five-card draw's rules, pure (#766: the saloon yard's card game, CardGame): a card is an int,
## 0..51, its rank `c % 13` (0 the two .. 12 the ace) and its suit `c / 13` (spades, hearts,
## diamonds, clubs). A hand's `score` compares as an array: its kind first (high card .. straight
## flush), then the ranks that break a tie. What the men say at the showdown is `name`'s.

enum Kind { HIGH, PAIR, TWO_PAIR, THREE, STRAIGHT, FLUSH, FULL_HOUSE, FOUR, STRAIGHT_FLUSH }

const RANKS := ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"]
const RANK_WORDS := ["two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "jack", "queen", "king", "ace"]
const RANK_PLURAL := ["twos", "threes", "fours", "fives", "sixes", "sevens", "eights", "nines", "tens", "jacks", "queens", "kings", "aces"]
const SUITS := ["♠", "♥", "♦", "♣"]
const SUIT_LETTERS := ["s", "h", "d", "c"]


static func rank(c: int) -> int:
	return c % 13


static func suit(c: int) -> int:
	return c / 13


static func red(c: int) -> bool:
	return suit(c) == 1 or suit(c) == 2


## "9♥" (or "9h" with `letters`).
static func label(c: int, letters := false) -> String:
	return RANKS[rank(c)] + (SUIT_LETTERS[suit(c)] if letters else SUITS[suit(c)])


## A new deck, shuffled by `rng`.
static func deck(rng: RandomNumberGenerator) -> Array[int]:
	var d: Array[int] = []
	for i in 52:
		d.append(i)
	for i in range(51, 0, -1):
		var j := rng.randi_range(0, i)
		var x := d[i]
		d[i] = d[j]
		d[j] = x
	return d


## The ranks by how many of each, most first then highest: [[count, rank], ...].
static func _groups(hand: Array) -> Array:
	var n := {}
	for c: int in hand:
		n[rank(c)] = int(n.get(rank(c), 0)) + 1
	var g: Array = []
	for r: int in n:
		g.append([n[r], r])
	g.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0] or (a[0] == b[0] and a[1] > b[1]))
	return g


## The straight's top rank (the wheel, A-2-3-4-5, tops at the five), or -1.
static func _straight_top(hand: Array) -> int:
	var rs: Array[int] = []
	for c: int in hand:
		if not rs.has(rank(c)):
			rs.append(rank(c))
	if rs.size() != 5:
		return -1
	rs.sort()
	if rs[4] - rs[0] == 4:
		return rs[4]
	if rs == [0, 1, 2, 3, 12]:
		return 3
	return -1


## [kind, tie-breaking ranks...]: compare two with `compare`.
static func score(hand: Array) -> Array:
	var g := _groups(hand)
	var flush := hand.size() == 5 and hand.all(func(c: int) -> bool: return suit(c) == suit(hand[0]))
	var top := _straight_top(hand) if hand.size() == 5 else -1
	var ranks: Array = g.map(func(x: Array) -> int: return x[1])
	if top >= 0 and flush:
		return [Kind.STRAIGHT_FLUSH, top]
	if g[0][0] == 4:
		return [Kind.FOUR] + ranks
	if g[0][0] == 3 and g.size() > 1 and g[1][0] == 2:
		return [Kind.FULL_HOUSE] + ranks
	if flush:
		return [Kind.FLUSH] + ranks
	if top >= 0:
		return [Kind.STRAIGHT, top]
	if g[0][0] == 3:
		return [Kind.THREE] + ranks
	if g[0][0] == 2 and g.size() > 1 and g[1][0] == 2:
		return [Kind.TWO_PAIR] + ranks
	if g[0][0] == 2:
		return [Kind.PAIR] + ranks
	return [Kind.HIGH] + ranks


## > 0 if `a` beats `b`, < 0 if it loses, 0 a split.
static func compare(a: Array, b: Array) -> int:
	var sa := score(a)
	var sb := score(b)
	for i in mini(sa.size(), sb.size()):
		if sa[i] != sb[i]:
			return 1 if sa[i] > sb[i] else -1
	return 0


## What a man calls his hand at the showdown: "a pair of nines", "kings over fours".
static func name(hand: Array) -> String:
	var s := score(hand)
	match int(s[0]):
		Kind.STRAIGHT_FLUSH:
			return "a straight flush"
		Kind.FOUR:
			return "four %s" % RANK_PLURAL[s[1]]
		Kind.FULL_HOUSE:
			return "a full house, %s over %s" % [RANK_PLURAL[s[1]], RANK_PLURAL[s[2]]]
		Kind.FLUSH:
			return "a flush"
		Kind.STRAIGHT:
			return "a straight, %s high" % RANK_WORDS[s[1]]
		Kind.THREE:
			return "three %s" % RANK_PLURAL[s[1]]
		Kind.TWO_PAIR:
			return "two pair, %s and %s" % [RANK_PLURAL[s[1]], RANK_PLURAL[s[2]]]
		Kind.PAIR:
			return "a pair of %s" % RANK_PLURAL[s[1]]
	return "%s high" % RANK_WORDS[s[1]]


## How good the hand is, 0..1, for a man's betting: its kind, and within it its top rank.
static func strength(hand: Array) -> float:
	var s := score(hand)
	return clampf((float(s[0]) + float(s[1]) / 13.0) / 4.0, 0.0, 1.0)


## Which cards (indices into `hand`) he throws in at the draw: nothing from a made hand (a straight
## or better); the odd ones round trips, two pair or a pair; one to four to a flush; else he keeps
## his two highest if both are a jack or better, his highest otherwise (three at most).
static func discards(hand: Array) -> Array[int]:
	var out: Array[int] = []
	var s := score(hand)
	var kind := int(s[0])
	if kind >= Kind.STRAIGHT or kind == Kind.FOUR:
		return out
	if kind in [Kind.THREE, Kind.TWO_PAIR, Kind.PAIR]:
		var keep := {}
		for x: Array in _groups(hand):
			if x[0] >= 2:
				keep[x[1]] = true
		for i in hand.size():
			if not keep.has(rank(hand[i])):
				out.append(i)
		return out
	# Four of a suit: the odd one out.
	for st in 4:
		var of := []
		for i in hand.size():
			if suit(hand[i]) == st:
				of.append(i)
		if of.size() == 4:
			for i in hand.size():
				if not of.has(i):
					out.append(i)
			return out
	var order: Array = range(hand.size())
	order.sort_custom(func(a: int, b: int) -> bool: return rank(hand[a]) > rank(hand[b]))
	var keep_n := 2 if rank(hand[order[1]]) >= 9 else 1
	# Three at most: the lowest.
	for k in range(maxi(keep_n, hand.size() - 3), hand.size()):
		out.append(order[k])
	out.sort()
	return out
