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
	var n := PackedInt32Array()
	n.resize(13)
	for c: int in hand:
		n[c % 13] += 1
	var g: Array = []
	for k in range(4, 0, -1):
		for r in range(12, -1, -1):
			if n[r] == k:
				g.append([k, r])
	return g


## The straight's top rank (the wheel, A-2-3-4-5, tops at the five), or -1.
static func _straight_top(hand: Array) -> int:
	var mask := 0
	for c: int in hand:
		mask |= 1 << (c % 13)
	return _top_of(mask) if hand.size() == 5 else -1


## A straight's top from the ranks' bits (five of them), or -1.
static func _top_of(mask: int) -> int:
	if mask == 0x100F:
		return 3
	for top in range(12, 3, -1):
		if mask == (0x1F << (top - 4)):
			return top
	return -1


## [kind, tie-breaking ranks...]: compare two with `compare`. (Counted in packed arrays, no sort: the
## men's odds score thousands of these a hand, `equity`, #1294.)
static func score(hand: Array) -> Array:
	var n := PackedInt32Array()
	n.resize(13)
	var mask := 0
	var flush := hand.size() == 5
	var s0: int = int(hand[0]) / 13 if not hand.is_empty() else 0
	for c: int in hand:
		var r := c % 13
		n[r] += 1
		mask |= 1 << r
		if c / 13 != s0:
			flush = false
	# The ranks, most of a kind first, then highest.
	var ranks: Array = []
	var top_count := 0
	var second := 0
	for k in range(4, 0, -1):
		for r in range(12, -1, -1):
			if n[r] == k:
				if ranks.is_empty():
					top_count = k
				elif ranks.size() == 1:
					second = k
				ranks.append(r)
	var top := _top_of(mask) if ranks.size() == 5 else -1
	if top >= 0 and flush:
		return [Kind.STRAIGHT_FLUSH, top]
	if top_count == 4:
		return [Kind.FOUR] + ranks
	if top_count == 3 and second == 2:
		return [Kind.FULL_HOUSE] + ranks
	if flush:
		return [Kind.FLUSH] + ranks
	if top >= 0:
		return [Kind.STRAIGHT, top]
	if top_count == 3:
		return [Kind.THREE] + ranks
	if top_count == 2 and second == 2:
		return [Kind.TWO_PAIR] + ranks
	if top_count == 2:
		return [Kind.PAIR] + ranks
	return [Kind.HIGH] + ranks


## > 0 if `a` beats `b`, < 0 if it loses, 0 a split.
static func compare(a: Array, b: Array) -> int:
	return compare_scores(score(a), score(b))


## `compare` on two `score`s already made.
static func compare_scores(sa: Array, sb: Array) -> int:
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
## his two highest if both are a jack or better, his highest otherwise (three at most; four, keeping a
## lone ace, where the table lets you draw four to an ace: `four_with_ace`).
static func discards(hand: Array, four_with_ace := false) -> Array[int]:
	var out: Array[int] = []
	var s := score(hand)
	var kind := int(s[0])
	if kind >= Kind.STRAIGHT or kind == Kind.FOUR:
		return out
	if kind in [Kind.THREE, Kind.TWO_PAIR, Kind.PAIR]:
		# The made ranks are the score's first (and, two pair, its second).
		var k1 := int(s[1])
		var k2 := int(s[2]) if kind == Kind.TWO_PAIR else -1
		for i in hand.size():
			var r := rank(hand[i])
			if r != k1 and r != k2:
				out.append(i)
		return out
	# Four of a suit: the odd one out.
	var per := PackedInt32Array()
	per.resize(4)
	for c: int in hand:
		per[c / 13] += 1
	for st in 4:
		if per[st] == 4:
			for i in hand.size():
				if suit(hand[i]) != st:
					out.append(i)
			return out
	# Nothing: every rank differs, the score's ranks are them highest first.
	var keep_n := 2 if int(s[2]) >= 9 else 1
	var most := 4 if four_with_ace and keep_n == 1 and int(s[1]) == 12 else 3
	# Three at most (four to an ace): the lowest.
	var throw_ranks := {}
	for k in range(maxi(keep_n, hand.size() - most), hand.size()):
		throw_ranks[int(s[1 + k])] = true
	for i in hand.size():
		if throw_ranks.has(rank(hand[i])):
			out.append(i)
	return out


## How many cards `hand` may throw at the draw (#1294; config/card_game.json `draw`): `most` (three),
## or one more when the card kept is an ace and `four_with_ace` (shown, by the house's rule).
static func draw_limit(hand: Array, throw: Array, most := 3, four_with_ace := true) -> int:
	if four_with_ace and throw.size() == most + 1 and hand.size() == 5:
		for i in hand.size():
			if not throw.has(i):
				return most + 1 if rank(hand[i]) == 12 else most
	return most


## Whether throwing `throw` (indices into `hand`) is within the table's rule: 0..`most`, `most`+1 keeping
## an ace.
static func can_throw(hand: Array, throw: Array, most := 3, four_with_ace := true) -> bool:
	for i: int in throw:
		if i < 0 or i >= hand.size() or throw.count(i) > 1:
			return false
	return throw.size() <= draw_limit(hand, throw, most, four_with_ace)


## A man's honest odds (#1294): the share of the pot `hand` wins against `opponents` others, 0..1 (a
## split shared), by `samples` deals of the cards he can't see (the deck less his own: nobody's peeking),
## every other hand drawing as `discards` says, his own too while `he_draws` (before the draw). One sample
## at a time, so it can be spread over frames: `equity_sample` returns that deal's share.
static func equity(hand: Array, opponents: int, rng: RandomNumberGenerator, samples := 100, he_draws := true, four_with_ace := false) -> float:
	var rest := unseen(hand)
	var won := 0.0
	for n in samples:
		won += equity_sample(hand, opponents, rng, rest, he_draws, four_with_ace)
	return won / maxf(samples, 1)


## The cards `hand` can't see (the deck less his own).
static func unseen(hand: Array) -> Array[int]:
	var rest: Array[int] = []
	for i in 52:
		if not hand.has(i):
			rest.append(i)
	return rest


## One deal of `equity`: the share he takes of it (1, a split's share, or 0). `rest` is shuffled in part.
static func equity_sample(hand: Array, opponents: int, rng: RandomNumberGenerator, rest: Array[int], he_draws := true, four_with_ace := false) -> float:
	var need := mini(rest.size(), 5 * opponents + 4 * (opponents + 1))
	for i in need:
		var j := rng.randi_range(i, rest.size() - 1)
		var x := rest[i]
		rest[i] = rest[j]
		rest[j] = x
	var k := 0
	var mine := hand.duplicate()
	if he_draws:
		for i in discards(mine, four_with_ace):
			mine[i] = rest[k]
			k += 1
	var ms := score(mine)
	var ties := 1
	for o in opponents:
		var h := rest.slice(k, k + 5)
		k += 5
		for i in discards(h, four_with_ace):
			if k < rest.size():
				h[i] = rest[k]
				k += 1
		var c := compare_scores(ms, score(h))
		if c < 0:
			return 0.0
		if c == 0:
			ties += 1
	return 1.0 / ties
