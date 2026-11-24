"""The game's booze (#1222, docs/briefs/booze.md): the 53 invented brands Sean approved (#1223), the bottle
shapes they come in, and the kit files of those bottles and of the stencilled barrel and keg heads,
written from the numbers here, so a change is one number and a re-run. The Blender half
(tools/blender/props/booze.py) reads the same numbers: it models every shape into glb:booze_bottles and
prints every label, on one sheet (pbr:booze_labels: one material for all 53, so the labels batch).

    python3 tools/props/booze.py                  # writes assets/props/kit/<id>.json for every kit here
    ~/.venvs/bpy/bin/python tools/blender/props/booze.py    # the model and the label sheet (~1 min)

A bottle kit holds every brand of its shape as its `variants` (its "Label<Shape>%d" part): the Nth made
wears label N mod the count, or the one a dressing entry names (`variant`, PropDressing; the dressing
scripts name brands, `variant_of`). The labels' look by grade (booze.md section 4): letterpress in one or
two colours for the rotgut (R) and the saloon's (S) and the dumb ones; chromolithograph with gold for the
fine (F) and the bitters. No strip stamps (1897), no crown caps (1892): corks.
"""
import json
import os
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
KIT = os.path.join(ROOT, "assets", "props", "kit")


def r(v, n=4):
    return [round(float(c), n) for c in v] if isinstance(v, (list, tuple)) else round(float(v), n)


# === The brands (booze.md section 2, all three tables) ================================================
# Each: the big name, the line over it (`top`), the line under it (`kind`), the slogan, the maker and his
# place, grade, the printing (`press` letterpress, `chromo` chromolithograph), its paper and inks (RGB),
# its engraved vignette (drawn by the Blender half: still, eagle, ...), a year if the label gives one, and
# small print (`small`: Quill's whole list). The dumb ones are set exactly as straight as the rest.
P_BUFF, P_WHITE, P_CREAM, P_YELLOW, P_PINK, P_BLUE, P_GREEN = (
    (226, 208, 166), (236, 230, 212), (232, 220, 186), (232, 210, 120), (226, 186, 170), (178, 196, 206), (186, 204, 168))
BLACK, RED, BLUE, BROWN, GREEN, GOLD = (24, 20, 18), (160, 34, 26), (34, 50, 110), (82, 46, 24), (30, 80, 44), (190, 150, 70)


def B(bid, name, kind, maker, place, grade, style, paper, ink, ink2, vignette, top="", slogan="", year="", small=None, shape="quart"):
    return {"id": bid, "name": name, "top": top, "kind": kind, "slogan": slogan, "maker": maker, "place": place,
            "grade": grade, "style": style, "paper": paper, "ink": ink, "ink2": ink2, "vignette": vignette,
            "year": year, "small": small or [], "shape": shape}


QUILL_LIST = ["Dyspepsia", "Liver Complaint", "Ague", "Chills and Fever", "Mountain Fever", "Female Weakness",
              "Nervous Prostration", "Nervous Twitter", "Want of Vigor", "Sour Stomach", "Costiveness", "the Gravel",
              "the Piles", "Melancholy", "Snake Bite"]

BRANDS = [
    # --- The straight 31 -------------------------------------------------------------------------------
    B("burnt_hollow", "BURNT HOLLOW", "Kentucky Bourbon Whiskey", "Ezra Tullis & Sons", "Burnt Hollow, Ky.", "S", "press",
      P_BUFF, BLACK, RED, "distillery", top="Old Fashioned Hand Made", slogan="Distilled Since 1846. Rebuilt 1871."),
    B("pettibone", "COL. PETTIBONE'S", "Old Sour Mash", "Pettibone Distilling Co.", "Bardstown, Ky.", "S", "press",
      P_WHITE, BLACK, RED, "colonel", top="Pure Kentucky", slogan="The Colonel Answers For Every Barrel."),
    B("belle_of_larue", "BELLE OF LARUE", "Bourbon Whiskey", "J. W. Gentry & Co.", "Hodgenville, Ky.", "S", "press",
      P_CREAM, BLUE, RED, "belle", top="Hand Made", slogan="Copper Distilled."),
    B("south_platte", "SOUTH PLATTE", "Kentucky Bourbon", "Jas. Dunleavy & Co., Wholesale Liquors", "Denver, Colo.", "R", "press",
      P_YELLOW, BLACK, None, "mountain", slogan="Equal To Any Kentucky Goods."),
    B("brandauer", "PIONEER RYE", "Brandauer's", "M. Brandauer, Rectifier, Blake St.", "Denver, Colo.", "R", "press",
      P_WHITE, RED, BLACK, "wagon", slogan="Mellowed By Our Own Process."),
    B("fenwick", "JUDGE FENWICK'S", "Monongahela Rye Whiskey", "Fenwick & Mohr", "Brownsville, Pa.", "F", "chromo",
      (40, 52, 70), GOLD, (226, 214, 180), "judge", top="Pure Old", slogan="Drawn From The Wood At Eight Years.", shape="quart_flint"),
    B("ashby", "ASHBY'S", "Private Stock", "Thos. Ashby", "Frankfort, Ky.", "F", "chromo",
      (236, 226, 196), (120, 20, 24), GOLD, "horse", top="Kentucky Bourbon", slogan="Sold Only In Glass. See That The Seal Is Whole.", shape="quart_flint"),
    B("drumbannagh", "DRUMBANNAGH", "Old Irish Whiskey", "Drumbannagh Distillery", "Co. Antrim", "F", "chromo",
      (40, 74, 50), GOLD, (236, 226, 196), "harp", slogan="Pot Still. Very Old.", shape="quart_flint"),
    B("strathcorran", "STRATHCORRAN", "Old Highland Whisky", "D. & A. Mackellar", "Strathcorran, Perthshire", "F", "chromo",
      (230, 214, 170), (24, 40, 80), (150, 30, 30), "stag", slogan="Very Old. Very Scarce.", shape="quart_flint"),
    B("bramwell", "DR. BRAMWELL'S", "Pure Malt Whiskey", "Bramwell Malt Co.", "Baltimore, Md.", "S", "press",
      P_WHITE, BLACK, RED, "barley", top="For Medicinal Use",
      slogan="A Tablespoonful Thrice Daily, Or As Required.", shape="flask"),
    B("riedl", "RIEDL'S", "Spring Lager", "Salt Creek Brewery, Aug. Riedl, Prop.", "Salt Creek, Colo.", "S", "press",
      P_WHITE, BLUE, RED, "spring", slogan="Brewed With Spring Water. Not From The Creek.", shape="beer"),
    B("zeitler", "ZEITLER'S", "Mountain Export Lager", "Zeitler & Sohn, Brewers", "Denver, Colo.", "S", "press",
      P_CREAM, RED, BLACK, "hops", slogan="Bottled Expressly For The Mountain Trade.", shape="beer"),
    B("ebner", "EBNER'S", "St. Louis Pale Export", "Gottfried Ebner Brewing Ass'n", "St. Louis, Mo.", "F", "chromo",
      (232, 214, 150), (30, 40, 90), (170, 30, 30), "eagle", slogan="Keeps In Any Climate.", shape="beer"),
    B("fothergill", "FOTHERGILL'S", "East India Pale Ale", "Fothergill & Ames", "Burton-on-Trent", "F", "chromo",
      (200, 40, 36), (240, 228, 200), GOLD, "ship", slogan="Brewed For Export.", shape="beer"),
    B("quill", "DR. A. QUILL'S", "Celebrated Vegetable Restorative Bitters", "Quill & Co.", "Philadelphia", "M", "chromo",
      (232, 222, 190), BLACK, (170, 36, 28), "herbs", slogan="The Alcohol Is A Preservative Only.",
      small=["For"] + QUILL_LIST + ["and All Diseases Arising From a Disordered Stomach."], shape="square"),
    B("corlew", "GEN. CORLEW'S", "Camp Bitters", "Corlew Bros.", "Cincinnati, O.", "M", "chromo",
      (40, 50, 90), GOLD, (236, 226, 196), "tent", slogan="As Carried By The Army Of The Cumberland.", shape="square"),
    B("pruett", "DR. PRUETT'S", "Temperance Stomach Bitters", "Pruett Medicine Co.", "Rochester, N.Y.", "M", "chromo",
      (236, 230, 214), (30, 70, 40), (150, 40, 30), "church", slogan="Free From Whiskey. Recommended By The Clergy.", shape="square"),
    B("haskett", "MRS. HASKETT'S", "Iron & Quinine Tonic", "Haskett & Daughter", "Lowell, Mass.", "M", "chromo",
      (226, 190, 196), (90, 20, 50), GOLD, "lady", slogan="For The Delicate Of Both Sexes.",
      small=["For Hysterics, Sleeplessness", "And Nervous Twitter."], shape="square"),
    B("hearthstone", "HEARTHSTONE", "Cabin Bitters", "Hearth & Cole", "New York", "M", "chromo",
      (232, 214, 150), (90, 40, 20), (170, 30, 30), "cabin", slogan="Jamaica Spirits, Gentian, Wild Cherry Bark.", year="Pat'd 1872",
      shape="cabin"),
    B("cardell", "CARDELL'S", "Aromatic Bitters", "J. B. Cardell", "Port of Spain, Trinidad", "F", "chromo",
      (236, 226, 196), (20, 60, 90), GOLD, "palm", slogan="For The Cocktail And The Stomach.", shape="square"),
    B("van_oorst", "VAN OORST", "Schiedam Geneva", "J. van Oorst & Zn.", "Schiedam", "S", "press",
      P_WHITE, BLACK, RED, "windmill", slogan="Recommended For The Kidneys.", shape="gin"),
    B("pelham", "PELHAM'S OLD TOM", "Gin", "Pelham & Fry, Distillers", "London", "F", "chromo",
      (236, 226, 196), BLACK, (40, 80, 50), "cat", slogan="Sweetened. Ready For The Punch.", shape="quart_flint"),
    B("cuthbert", "CUTHBERT'S", "Merrimack Rum", "Cuthbert & Son", "Newburyport, Mass.", "S", "press",
      P_BUFF, BROWN, BLACK, "ship", slogan="Distilled Since The Revolution."),
    B("carriere", "CARRIERE'S", "California Grape Brandy", "L. Carriere", "Sonoma, Cal.", "S", "press",
      P_WHITE, (90, 20, 60), BLACK, "grapes", slogan="Pure Juice Of The Grape. No Drugs."),
    B("delaurier", "MAISON DELAURIER", "Fine Champagne Cognac", "Delaurier Freres", "Cognac", "F", "chromo",
      (20, 20, 22), GOLD, (236, 226, 196), "crest", slogan="Grande Reserve.", shape="quart_flint"),
    B("felder", "DR. FELDER'S", "Blackberry Cordial", "Felder & Lusk", "Louisville, Ky.", "M", "press",
      P_PINK, (70, 20, 50), BLACK, "berries", slogan="For The Summer Complaint, Cholera Morbus And Teething Children.",
      shape="panel"),
    B("morandiere", "VEUVE MORANDIERE", "Carte Blanche", "Veuve Morandiere & Cie.", "Reims", "F", "chromo",
      (236, 228, 204), BLACK, GOLD, "crest", slogan="Extra Sec.", shape="wine"),
    B("larcenac", "CHATEAU LARCENAC", "Medoc", "Laffriere & Fils", "Bordeaux", "F", "chromo",
      (236, 228, 204), (110, 20, 30), GOLD, "chateau", slogan="Bottled At The Chateau.", shape="wine"),
    B("tolliver", "DR. TOLLIVER'S", "Compound Extract of Sarsaparilla", "Tolliver & Gage", "Albany, N.Y.", "M", "press",
      P_BLUE, BLACK, RED, "root", slogan="Purifies The Blood. Cures Scrofula, Boils And Salt Rheum.", shape="panel"),
    B("holcombe", "HOLCOMBE'S", "Stone Ginger Beer", "W. Holcombe, Larimer St.", "Denver", "M", "stamp",
      None, (60, 40, 30), None, None, slogan="This Bottle Is Holcombe's. Return It.", shape="stone"),
    # --- The double meanings (32-39) ---------------------------------------------------------------------
    B("crack_shot", "CRACK SHOT", "Rye Whiskey", "Jas. Dunleavy & Co.", "Denver, Colo.", "R", "press",
      P_BUFF, BLACK, RED, "rifles", slogan="The Choice Of Crack Shots."),
    B("tinderbox", "TINDERBOX", "Bourbon Whiskey", "Ezra Tullis & Sons", "Burnt Hollow, Ky.", "S", "press",
      P_YELLOW, BLACK, RED, "distillery", top="Old Fashioned Sour Mash"),
    B("amazon", "AMAZON", "Restorative Tonic Bitters", "Thorne & Peck", "Hartford, Conn.", "M", "chromo",
      (230, 214, 170), (40, 60, 30), (160, 40, 30), "amazon", slogan="For Female Weakness.", shape="square"),
    B("cougar", "COUGAR BRAND", "Pure Rye Whiskey", "Kittredge & Co., Wholesale Liquors", "Pueblo, Colo.", "R", "press",
      P_WHITE, BROWN, BLACK, "cougar"),
    B("stoner_blunt", "PURE RYE", "Old Sour Mash", "Stoner & Blunt, Distillers", "Lancaster Co., Pa.", "S", "press",
      P_CREAM, BLACK, BLUE, "still", top="Stoner & Blunt's"),
    B("pellow", "DR. PELLOW'S", "Coca Cordial", "Pellow Chemical Co.", "New York", "M", "press",
      P_GREEN, (20, 50, 30), BLACK, "leaf", slogan="For Fatigue And Low Spirits.", shape="panel"),
    # --- The dumb ones (40-53): printed dead straight ----------------------------------------------------
    B("uranus", "URANUS", "Anisette", "P. Anus et Fils", "Bordeaux", "R", "press",
      P_BLUE, (24, 30, 70), BLACK, "planet", slogan="The Far-Off Spirit."),
    B("twin_buttes", "TWIN BUTTES", "Lager Beer", "Twin Buttes Brewery", "Pueblo, Colo.", "R", "press",
      P_YELLOW, BLACK, RED, "buttes", slogan="Two Fine Buttes, One Fine Beer.", shape="beer"),
    B("bottoms", "DR. BOTTOMS'", "Loosening Bitters", "Bottoms & Co.", "Cincinnati, O.", "M", "press",
      P_BUFF, BLACK, RED, "door", slogan="Opens The Bowels Like A Church Door.", shape="square"),
    B("wiener", "WIENER'S", "Vienna Lager", "Otto Wiener, Brewer", "Denver, Colo.", "R", "press",
      P_WHITE, RED, BLACK, "hops", slogan="Every Man Enjoys A Wiener.", shape="beer"),
    B("pemberly", "DR. PEMBERLY'S", "Tonic", "Pemberly & Son", "Boston", "M", "press",
      P_CREAM, BLACK, RED, "bird", slogan="Keep Your Pecker Up!", shape="panel"),
    B("ferrell", "DR. FERRELL'S", "Cock Ale", "Ferrell Bros.", "Philadelphia", "R", "press",
      P_BUFF, BROWN, RED, "rooster", slogan="A Cock In Every Cask.", shape="beer"),
    B("aunt_fanny", "AUNT FANNY'S", "Rhubarb Bitters", "Fanny Gorse & Co.", "Albany, N.Y.", "M", "press",
      P_PINK, BLACK, (120, 30, 40), "rhubarb", slogan="Gentle On The Fanny.", shape="square"),
    B("windham", "DR. WINDHAM'S", "Wind Expeller", "Windham & Gale", "New Haven, Conn.", "M", "press",
      P_WHITE, BLUE, BLACK, "wind", slogan="Expels The Wind Promptly And Without Shame.", shape="panel"),
    B("dingle", "DINGLE'S BERRY", "Cordial", "Dingle & Co.", "Louisville, Ky.", "M", "press",
      P_PINK, (80, 20, 40), BLACK, "berries", slogan="Picked Fresh From The Bottom Of The Bush.", shape="panel"),
    B("old_seaman", "OLD SEAMAN'S", "Navy Rum", "Gosling Wharf Distillers", "Boston", "R", "press",
      P_BLUE, BLACK, RED, "anchor", slogan="For The Thirsty Seaman."),
    B("boner", "DR. BONER'S", "Stiffening Elixir", "Boner Medicine Co.", "St. Louis, Mo.", "M", "press",
      P_YELLOW, BLACK, RED, "clock", slogan="For Want Of Vigor. Results In Twenty Minutes.", shape="panel"),
    B("ball", "BALL'S", "Old Sour Mash", "J. T. Ball & Sons", "Bardstown, Ky.", "R", "press",
      P_WHITE, BLACK, RED, "barrel", slogan="Aged In The Wood. Hand Made."),
    B("long_hardy", "PURE RYE", "Whiskey", "Long & Hardy, Distillers", "Pittsburgh, Pa.", "R", "press",
      P_BUFF, BLACK, BLUE, "still", top="Long & Hardy's", slogan="Satisfaction For The Whole Evening."),
    B("bumstead", "BUMSTEAD'S", "Stone Ginger Beer", "H. Bumstead", "Denver", "M", "stamp",
      None, (60, 40, 30), None, None, slogan="Return This Bottle To Bumstead.", shape="stone"),
]
BY_ID = {b["id"]: b for b in BRANDS}
# Brandauer's and Lowry's are also (or only) barrel heads; the line "Rectified From High Wines" (#35) is on
# Brandauer's head, below.

# === The bottle shapes (booze.md section 1, "Bottles") ================================================
# Sections bottom up, as the doctor's bottles (tools/props/doctor.py BOTTLES): (y, half width x, half depth
# z, squareness (2 round, 6 a rounded box), sides). `label`: (y0, y1, half angle about +z); `stopper`:
# (radius, y0, y1); `liquid`: its level and its baked finish. Sizes from the period's bottles: a whiskey
# "fifth" (the quart of the trade) ~30 cm, a pint flask ~20, a square bitters ~25, a gin case bottle ~25,
# champagne ~30, a beer quart ~28, a stone ginger beer ~19.
RIM = lambda y, r_: [(y, r_ * 1.24, r_ * 1.24, 2, 0), (y + 0.012, r_ * 1.24, r_ * 1.24, 2, 0)]


def _round(rows):
    return [(y, a, a, 2, 0) for y, a in rows]


SHAPES = {
    # The round quart: the kit's whiskey_bottle's profile (PropModels.bottle), the same size, so a labelled
    # quart stands where the old one stood.
    "quart": {"kit": "liquor_quart", "glass": "amber", "kind": "whiskey",
              "sections": _round([(0.0, 0.040), (0.004, 0.044), (0.020, 0.044), (0.190, 0.044), (0.215, 0.038),
                                  (0.240, 0.016), (0.262, 0.013), (0.263, 0.0158), (0.276, 0.0158), (0.277, 0.0118)]),
              "label": (0.062, 0.168, 1.05), "stopper": (0.0118, 0.255, 0.30), "liquid": 0.205, "finish": "whiskey",
              "litres": 0.6, "mass": 1.2, "breaks": 4.5, "kpa": 60,
              "what": "a round amber glass quart (the trade's 'fifth'), an applied lip, a cork"},
    "quart_flint": {"kit": "liquor_quart_flint", "glass": "clear", "kind": "whiskey", "same_as": "quart",
                    "litres": 0.6, "mass": 1.2, "breaks": 4.5, "kpa": 60,
                    "what": "a round clear flint-glass quart (the fine goods: the colour shown through), a cork"},
    # The union oval / coffin pint: flat, for the pocket.
    "flask": {"kit": "liquor_flask", "glass": "amber", "kind": "whiskey",
              "sections": [(0.0, 0.044, 0.019, 2.6, 0), (0.004, 0.048, 0.022, 2.6, 0), (0.140, 0.048, 0.022, 2.6, 0),
                           (0.160, 0.034, 0.018, 2.4, 0), (0.172, 0.012, 0.012, 2, 0), (0.190, 0.011, 0.011, 2, 0),
                           (0.191, 0.0136, 0.0136, 2, 0), (0.200, 0.0136, 0.0136, 2, 0), (0.201, 0.0095, 0.0095, 2, 0)],
              "label": (0.030, 0.128, 0.95), "stopper": (0.0095, 0.178, 0.212), "liquid": 0.150, "finish": "whiskey",
              "litres": 0.36, "mass": 0.62, "breaks": 4.2, "kpa": 55,
              "what": "a pint flask (the 'union oval'), flat to carry in a coat, amber glass, a cork"},
    # The square bitters: amber, a short neck (the patent bitters of the 1870s, most embossed, a paper label
    # on the front panel).
    "square": {"kit": "bitters_bottle", "glass": "amber", "kind": "bitters",
               "sections": [(0.0, 0.031, 0.031, 6, 0), (0.004, 0.033, 0.033, 6, 0), (0.180, 0.033, 0.033, 6, 0),
                            (0.196, 0.026, 0.026, 5, 0), (0.206, 0.0135, 0.0135, 2, 0), (0.234, 0.0125, 0.0125, 2, 0),
                            (0.235, 0.0152, 0.0152, 2, 0), (0.246, 0.0152, 0.0152, 2, 0), (0.247, 0.0100, 0.0100, 2, 0)],
               "label": (0.030, 0.170, 0.72), "stopper": (0.0100, 0.222, 0.256), "liquid": 0.190, "finish": "whiskey",
               "litres": 0.7, "mass": 1.25, "breaks": 4.4, "kpa": 60,
               "what": "a square amber bitters bottle, a short neck, its paper label on the front panel, a cork"},
    # The log cabin (a figural bitters bottle of the 1860s-70s): square, its logs moulded, a pitched roof
    # for shoulders; a smooth panel for the label where the door would be.
    "cabin": {"kit": "bitters_cabin", "glass": "amber", "kind": "bitters", "logs": True,
              "sections": None,  # built by cabin_sections()
              "label": (0.048, 0.128, 0.62), "stopper": (0.0100, 0.196, 0.228), "liquid": 0.150, "finish": "whiskey",
              "litres": 0.6, "mass": 1.1, "breaks": 4.4, "kpa": 60,
              "what": "a log-cabin bitters bottle (figural, its logs and roof moulded in the amber glass), a paper label on its front, a cork"},
    # The Holland gin case bottle: square, wider at the shoulder than the foot (they packed a dozen to a case),
    # olive green, a short neck.
    "gin": {"kit": "gin_case_bottle", "glass": "green", "kind": "gin",
            "sections": [(0.0, 0.028, 0.028, 6, 0), (0.004, 0.030, 0.030, 6, 0), (0.200, 0.037, 0.037, 6, 0),
                         (0.214, 0.030, 0.030, 5, 0), (0.222, 0.0125, 0.0125, 2, 0), (0.238, 0.0115, 0.0115, 2, 0),
                         (0.239, 0.0145, 0.0145, 2, 0), (0.248, 0.0145, 0.0145, 2, 0), (0.249, 0.0092, 0.0092, 2, 0)],
            "label": (0.060, 0.165, 0.72), "stopper": (0.0092, 0.226, 0.258), "liquid": 0.200, "finish": "whiskey",
            "litres": 0.75, "mass": 1.3, "breaks": 4.4, "kpa": 60,
            "what": "a Holland gin case bottle, square and wider at the shoulder, olive-green glass, a cork"},
    # Champagne and claret: heavy dark green, a punt, the cork foiled.
    "wine": {"kit": "wine_bottle", "glass": "green", "kind": "wine", "foil": True,
             "sections": _round([(0.0, 0.040), (0.004, 0.045), (0.170, 0.045), (0.200, 0.040), (0.240, 0.022),
                                 (0.270, 0.0145), (0.288, 0.0145), (0.289, 0.0165), (0.296, 0.0165), (0.297, 0.0110)]),
             "label": (0.055, 0.135, 0.95), "stopper": (0.0110, 0.272, 0.305), "liquid": 0.215, "finish": "whiskey",
             "litres": 0.75, "mass": 1.6, "breaks": 5.0, "kpa": 70,
             "what": "a heavy dark-green wine bottle (champagne or claret), a punt, its cork under gilt foil"},
    # The beer quart: a blob top (the thick applied lip a wired cork sat on).
    "beer": {"kit": "beer_bottle", "glass": "amber", "kind": "beer",
             "sections": _round([(0.0, 0.037), (0.004, 0.041), (0.165, 0.041), (0.195, 0.035), (0.225, 0.016),
                                 (0.262, 0.0135), (0.263, 0.0178), (0.280, 0.0178), (0.281, 0.0112)]),
             "label": (0.055, 0.140, 1.0), "stopper": (0.0112, 0.262, 0.290), "liquid": 0.200, "finish": "beer",
             "litres": 0.7, "mass": 1.25, "breaks": 4.5, "kpa": 60,
             "what": "an amber beer quart with a blob top, its cork wired down (no crown caps until 1892)"},
    # The druggist's tall panel (patent medicines): aqua, flat front and back.
    "panel": {"kit": "patent_medicine_bottle", "glass": "aqua", "kind": "medicine",
              "sections": [(0.0, 0.036, 0.020, 6, 0), (0.004, 0.038, 0.022, 6, 0), (0.168, 0.038, 0.022, 6, 0),
                           (0.182, 0.028, 0.018, 4, 0), (0.192, 0.0120, 0.0120, 2, 0), (0.210, 0.0110, 0.0110, 2, 0),
                           (0.211, 0.0135, 0.0135, 2, 0), (0.220, 0.0135, 0.0135, 2, 0), (0.221, 0.0090, 0.0090, 2, 0)],
              "label": (0.030, 0.158, 0.95), "stopper": (0.0090, 0.198, 0.232), "liquid": 0.170, "finish": "syrup",
              "litres": 0.35, "mass": 0.6, "breaks": 3.6, "kpa": 50,
              "what": "a tall aqua patent-medicine panel bottle, a flat front for its label, a cork"},
    # Stone ginger beer: salt-glazed stoneware, tan dipped over cream, the maker's name stamped in.
    "stone": {"kit": "ginger_beer_bottle", "glass": None, "kind": "ginger_beer", "stone": True,
              "sections": _round([(0.0, 0.033), (0.004, 0.036), (0.145, 0.036), (0.160, 0.030), (0.172, 0.0145),
                                  (0.180, 0.0135), (0.181, 0.0155), (0.190, 0.0155), (0.191, 0.0110)]),
              "label": (0.0, 0.191, 3.14159), "stopper": (0.0110, 0.176, 0.200), "liquid": None, "finish": None,
              "litres": 0.3, "mass": 0.7, "breaks": 4.8, "kpa": 70,
              "what": "a salt-glazed stoneware ginger beer bottle, tan dipped over cream, its maker's name stamped in, a cork"},
}
SHAPES["quart_flint"].update({k: SHAPES["quart"][k] for k in ("sections", "label", "stopper", "liquid", "finish")})
# What a bottle holds, for PropContents (its liquids: whiskey, beer, water, lamp oil); a gin, a rum, a
# bitters are spirits as whiskey is (they burn); ginger beer and the medicines take their own colour.
CONTENTS = {"whiskey": ("whiskey", [0.55, 0.32, 0.1]), "gin": ("whiskey", [0.8, 0.8, 0.72]), "wine": ("whiskey", [0.42, 0.08, 0.1]),
            "beer": ("beer", [0.72, 0.5, 0.16]), "bitters": ("whiskey", [0.42, 0.18, 0.06]), "medicine": ("tincture", [0.4, 0.15, 0.08]),
            "ginger_beer": ("water", [0.8, 0.72, 0.5])}


def cabin_sections():
    """The cabin's walls: its logs as rings proud and back every 12 mm (the moulded logs), smooth where its
    label goes, the roof a square pyramid to the neck."""
    secs = [(0.0, 0.031, 0.031, 8, 0), (0.004, 0.034, 0.034, 8, 0)]
    y = 0.004
    y0, y1 = SHAPES["cabin"]["label"][0] - 0.004, SHAPES["cabin"]["label"][1] + 0.004
    while y < 0.150:
        y += 0.006
        a = 0.034 if (int(round(y / 0.006)) % 2 or y0 < y < y1) else 0.0328
        secs.append((round(y, 4), a, a, 8, 0))
    secs += [(0.156, 0.036, 0.036, 8, 0), (0.160, 0.034, 0.034, 8, 0), (0.186, 0.014, 0.014, 3, 0),
             (0.190, 0.0115, 0.0115, 2, 0), (0.204, 0.0115, 0.0115, 2, 0), (0.205, 0.0145, 0.0145, 2, 0),
             (0.214, 0.0145, 0.0145, 2, 0), (0.215, 0.0100, 0.0100, 2, 0)]
    return secs


SHAPES["cabin"]["sections"] = cabin_sections()


def brands_of(shape):
    """The brands a shape wears, in their variant order (the brand list's order)."""
    return [b["id"] for b in BRANDS if b["shape"] == shape] + EXTRA.get(shape, [])


# Brands sold in a second shape too: the flask's pints of the rotgut.
EXTRA = {"flask": ["south_platte", "crack_shot", "burnt_hollow"]}


def variant_of(shape, brand):
    """The variant (label) number of `brand` on `shape`'s kit, for a dressing entry's `variant`."""
    return brands_of(shape).index(brand)


def kit_of(shape):
    return SHAPES[shape]["kit"]


def size_of(shape):
    s = SHAPES[shape]
    w = max(sec[1] for sec in s["sections"]) * 2
    d = max(sec[2] for sec in s["sections"]) * 2
    return [w, s["stopper"][2], d]


def part(shape):
    """The model's part names for a shape (shared glass where two kits share a shape)."""
    base = SHAPES[shape].get("same_as", shape)
    return base.replace("_", " ").title().replace(" ", ""), shape.replace("_", " ").title().replace(" ", "")


def bottle_kit(shape):
    s = SHAPES[shape]
    k, lk = part(shape)
    brands = brands_of(shape)
    liquid, colour = CONTENTS[s["kind"]]
    names = ", ".join(BY_ID[b]["name"].title() for b in brands)
    looks = {"Label%s%%d" % lk: "pbr:booze_labels", "Cork" + k: "pbr:booze_bottles"}
    glass = ["Label" + lk]
    if s.get("stone"):
        looks["Base" + k] = "pbr:booze_bottles"
        glass = ["Label" + lk, "Base" + k]
    else:
        looks["Glass" + k] = "glass:" + s["glass"]
        looks["Liquid" + k] = "pbr:booze_bottles"
        glass = ["Glass" + k, "Liquid" + k, "Label" + lk]
    if s.get("foil"):
        looks["Foil" + k] = "pbr:booze_labels"
        glass.append("Foil" + k)
    return {
        "_doc": "A bottle of the game's own booze (#1222, docs/briefs/booze.md): %s. Its labels the brands of its "
                "shape (%s): the Nth made wears label N mod %d (`variants`), or the one its dressing entry names "
                "(`variant`; tools/props/booze.py variant_of). A prop that shatters (GlassProp): a fall onto boards "
                "at %.1f m/s or %d kPa breaks it and what's in it goes on the floor. Drawn from glb:booze_bottles "
                "(tools/blender/props/booze.py): the glass the kit's `glass:` look, every label printed on one sheet "
                "(pbr:booze_labels), cork and contents baked the gun way. Written by tools/props/booze.py."
                % (s["what"], names, len(brands), s["breaks"], s["kpa"]),
        "id": s["kit"], "kind": "shatters", "fixture": True, "in_game": False,
        "model": "glb:booze_bottles", "looks": looks, "variants": len(brands), "brands": brands,
        "size": r(size_of(shape)), "mass": s["mass"], "wall": 0.004,
        "glass": glass, "whole": [["Cork" + k]],
        "shards": 12, "piece_mass": 0.04, "breaks_at": s["breaks"], "shatters_kpa": s["kpa"],
        "heat_seconds": 25, "cut_area": 0.05,
        "contents": {"liquid": liquid, "litres": round(s["litres"] * 0.85, 3), "colour": colour},
    }


# === Barrel and keg heads, stencilled (booze.md section 4) ============================================
# A cask's maker burned or stencilled his name in its head, and the gauger stencilled his marks (serial,
# proof gallons, district) by the revenue laws of the 1870s. The stencil is drawn on the head's boards
# (each board's own share of it, a `dress` layer: it goes where its board goes, breaks with it).
HEADS = {
    # id: (the kit it's laid on, the head boards (member ids), the head's radius, its centre (prop space),
    #      the lines, ink, which way the head faces: "up" a standing cask's top, "z" a lying keg's tap end)
    "lowry": {"kit": "whiskey_barrel_lowry", "like": "whiskey_barrel", "face": "up",
              "lines": ["LOWRY BROS.", "XXX", "WHISKEY", "LEADVILLE, COLO.", "FOR FAMILY USE"], "ink": (30, 22, 18),
              "gauge": "No. 4172  40 GALS  2 DIST. COLO."},
    "burnt_hollow": {"kit": "whiskey_barrel_burnt_hollow", "like": "whiskey_barrel", "face": "up",
                     "lines": ["EZRA TULLIS & SONS", "BURNT HOLLOW", "BOURBON", "KY.", "1878"], "ink": (30, 22, 18),
                     "gauge": "No. 2216  44 GALS  5 DIST. KY.", "burned": True},
    "brandauer": {"kit": "whiskey_barrel_brandauer", "like": "whiskey_barrel", "face": "up",
                  "lines": ["M. BRANDAUER", "PIONEER RYE", "RECTIFIED FROM", "HIGH WINES", "DENVER"], "ink": (120, 24, 20),
                  "gauge": "No. 911  42 GALS  RECT. COLO."},
    "riedl": {"kit": "beer_keg_riedl", "like": "beer_keg", "face": "up",
              "lines": ["SALT CREEK", "BREWERY", "RIEDL", "LAGER", "1/2 BBL."], "ink": (30, 22, 18), "burned": True},
    "riedl_side": {"kit": "beer_keg_side_riedl", "like": "beer_keg_side", "face": "z",
                   "lines": ["SALT CREEK", "BREWERY", "RIEDL", "LAGER", "1/2 BBL."], "ink": (30, 22, 18), "burned": True},
}


def load_kit(kid):
    with open(os.path.join(KIT, kid + ".json")) as f:
        d = json.load(f)
    if "like" in d:
        base = load_kit(d["like"])
        base.update(d)
        base.pop("like", None)
        d = base
    return d


def head_boards(head):
    """The head's boards (members) the stencil goes on, with the head's middle and radius and its facing,
    read from the cask's own kit file: [(member id, x0, x1 across the head)], centre, radius."""
    d = load_kit(HEADS[head]["like"])
    face = HEADS[head]["face"]
    out = []
    for m in d["members"]:
        mid = m["id"]
        if face == "up" and not mid.startswith("head_top"):
            continue
        if face == "z" and not (mid.startswith("head_") and float(m["at"][2]) > 0):
            continue
        out.append(m)
    assert out, "no head boards on %s" % HEADS[head]["like"]
    if face == "up":
        top = max(float(m["at"][1]) + float(m["size"][1]) * 0.5 for m in out)
        radius = max(float(m.get("draw", {}).get("radius", 0.2)) for m in out)
        centre = (0.0, top, 0.0)
        spans = [(m["id"], float(m["at"][0]) - float(m["size"][0]) * 0.5, float(m["at"][0]) + float(m["size"][0]) * 0.5) for m in out]
    else:
        front = max(float(m["at"][2]) + float(m["size"][2]) * 0.5 for m in out)
        radius = max(float(m.get("draw", {}).get("radius", 0.0)) for m in out) or 0.18
        ys = [float(m["at"][1]) for m in out]
        centre = (0.0, sum(ys) / len(ys), front)
        spans = [(m["id"], -1.0, 1.0) for m in out]
    return spans, centre, radius, d


def head_kit(head):
    h = HEADS[head]
    spans, _, _, base = head_boards(head)
    members = json.loads(json.dumps(base["members"]))
    ids = {s[0] for s in spans}
    for i, (mid, _, _) in enumerate(spans):
        for m in members:
            if m["id"] == mid:
                m.setdefault("dress", []).append({"look": "pbr:booze_labels",
                                                  "draw": {"shape": "mesh", "model": "booze_bottles", "part": "Head%s%d" % (head.title().replace("_", ""), i)}})
    assert all(any(m["id"] == i for m in members) for i in ids)
    d = {k: v for k, v in base.items() if k not in ("_doc", "members", "id", "factory")}
    d.update({
        "_doc": "%s (%s.json) with its head stencilled (#1222, docs/briefs/booze.md): %s%s. The stencil is "
                "laid on the head's boards, each board its own share (a `dress` layer of glb:booze_bottles' Head "
                "parts on the label sheet, pbr:booze_labels): it goes where its board goes and breaks with it. "
                "Written by tools/props/booze.py." % (base.get("_doc", "").split(".")[0], h["like"], " / ".join(h["lines"]),
                                                     ("; the gauger's marks: " + h["gauge"]) if h.get("gauge") else ""),
        "id": h["kit"], "in_game": False, "fixture": True, "members": members,
    })
    d.pop("replaces", None)
    d["replaces"] = ""
    return d


def kits():
    out = [bottle_kit(s) for s in SHAPES]
    out += [head_kit(h) for h in HEADS]
    return out


def main():
    for d in kits():
        d["factory"] = "tools/props/booze.py"
        path = os.path.join(KIT, d["id"] + ".json")
        with open(path, "w") as f:
            json.dump(d, f, indent=2)
            f.write("\n")
        print("wrote", os.path.relpath(path, ROOT), "(%s)" % (("%d labels" % d["variants"]) if "variants" in d else "%d members" % len(d["members"])))


if __name__ == "__main__":
    if "--list" in sys.argv:
        for s in SHAPES:
            print(s, brands_of(s))
    else:
        main()
