// Shared elements for the single-page selector. See LICENSE.md.
#define MONEY_COLOR 0.62 0.9 0.52 1
#define CLASS_COLOR 1 0.81 0.53 1
#define CLOSED_COLOR 0.92 0.45 0.40 1
#define FLAT_READY dvarInt(flat_has_class) == 1
// Hover descriptions: an item sets flat_hint on focus; the footer bar shows it.
#define HINT_ON(TEXT) setDvar flat_hint TEXT;
#define HINT_OFF setDvar flat_hint "";
#define FLAT_TEXT(PX, PY, PW, LABEL, SIZE) \
itemDef { rect PX PY PW 20 0 0 type ITEM_TYPE_TEXT text LABEL textfont UI_FONT_NORMAL \
textscale SIZE textaligny 15 textstyle ITEM_TEXTSTYLE_SHADOWED forecolor 0.9 0.92 0.94 1 visible 1 decoration }
#define FLAT_VALUE(PX, PY, PW, VALUE, SIZE, SHOW) \
itemDef { rect PX PY PW 20 0 0 type ITEM_TYPE_TEXT exp text(VALUE); textfont UI_FONT_NORMAL \
textscale SIZE textaligny 15 textstyle ITEM_TEXTSTYLE_SHADOWED forecolor 0.9 0.92 0.94 1 visible when(SHOW) decoration }
#define FLAT_PANEL(PX, PY, PW, PH) \
itemDef { rect PX PY PW PH 0 0 style WINDOW_STYLE_FILLED backcolor 0 0 0 0.66 \
border WINDOW_BORDER_FULL bordersize 1 bordercolor 0.4 0.4 0.42 0.8 visible 1 decoration } \
itemDef { rect PX PY PW PH 0 0 style WINDOW_STYLE_SHADER background "gradient_center" forecolor 0.3 0.3 0.325 0.6 visible 1 decoration } \
itemDef { rect PX PY PW 2 0 0 style WINDOW_STYLE_FILLED backcolor 0.3 0.3 0.325 0.8 visible 1 decoration } \
itemDef { rect PX (PY + PH - 2) PW 2 0 0 style WINDOW_STYLE_FILLED backcolor 0.3 0.3 0.325 0.8 visible 1 decoration }
#define FLAT_OPTION(ID, PX, PY, PW, LABEL, RESPONSE, SHOW, ALLOW, SELECTED) \
itemDef { name ID rect PX PY PW 21 0 0 type ITEM_TYPE_BUTTON style WINDOW_STYLE_FILLED \
backcolor 0.02 0.025 0.03 0.7 border WINDOW_BORDER_FULL bordersize 1 bordercolor 1 1 1 0.22 text LABEL textfont UI_FONT_NORMAL textscale 0.23 \
textalign ITEM_ALIGN_CENTER textalignx 0 textaligny 15 textstyle ITEM_TEXTSTYLE_SHADOWED \
forecolor 0.90 0.93 0.95 1 visible when((SHOW) && (ALLOW)) action { scriptMenuResponse RESPONSE; } } \
itemDef { rect PX PY PW 21 0 0 type ITEM_TYPE_TEXT style WINDOW_STYLE_FILLED \
backcolor 0.02 0.025 0.03 0.7 text LABEL textfont UI_FONT_NORMAL textscale 0.23 \
textalign ITEM_ALIGN_CENTER textalignx 0 textaligny 15 forecolor 0.35 0.38 0.40 1 \
visible when((SHOW) && (ALLOW) == 0) decoration } \
itemDef { rect (PX + 6) (PY + 19) (PW - 12) 1 0 0 style WINDOW_STYLE_FILLED \
backcolor 1 0.81 0.53 1 visible when((SHOW) && (SELECTED)) decoration }
#define FLAT_SLOT(PX, PY, CLASS, INDEX) \
itemDef { rect PX PY 5 5 0 0 style WINDOW_STYLE_SHADER background "white" forecolor 0.23 0.25 0.27 1 \
exp forecolor A(0.18 + 0.82 * (dvarInt("flat_"CLASS"_limit") >= INDEX)); visible 1 decoration } \
itemDef { rect PX PY 5 5 0 0 style WINDOW_STYLE_SHADER background "white" forecolor CLASS_COLOR \
visible when(dvarInt("flat_"CLASS"_count") >= INDEX && dvarInt("flat_"CLASS"_limit") >= INDEX) decoration }
#define FLAT_CLASS(PY, LABEL, CLASS, RESPONSE) \
FLAT_PANEL(16, PY, 172, 43) \
itemDef { rect 16 PY 172 43 0 0 type ITEM_TYPE_BUTTON text LABEL textfont UI_FONT_NORMAL \
textscale 0.31 textalignx 11 textaligny 20 textstyle ITEM_TEXTSTYLE_SHADOWED forecolor 1 0.81 0.53 1 \
visible when(dvarInt("flat_"CLASS"_allowed") == 1) action { scriptMenuResponse RESPONSE; } } \
itemDef { rect 16 PY 172 43 0 0 type ITEM_TYPE_TEXT text LABEL textfont UI_FONT_NORMAL \
textscale 0.31 textalignx 11 textaligny 20 forecolor 0.38 0.40 0.42 1 \
visible when(dvarInt("flat_"CLASS"_allowed") != 1) decoration } \
itemDef { rect 16 PY 2 43 0 0 style WINDOW_STYLE_FILLED backcolor 1 0.81 0.53 1 \
visible when(FLAT_READY && dvarString(loadout_class) == CLASS) decoration } \
FLAT_VALUE(27, (PY + 22), 100, dvarString("flat_"CLASS"_capacity"), 0.21, 1) \
FLAT_SLOT(151, (PY + 30), CLASS, 1) FLAT_SLOT(161, (PY + 30), CLASS, 2) FLAT_SLOT(171, (PY + 30), CLASS, 3)
#define FLAT_WEAPON_TILE(PX, PY, PW, PH, IW, IH, FIELD, POPUP, CAPTION, HINT) \
itemDef { rect PX PY PW PH 0 0 type ITEM_TYPE_BUTTON style WINDOW_STYLE_FILLED \
backcolor 0 0 0 0.3 border WINDOW_BORDER_FULL bordersize 1 bordercolor 0.4 0.4 0.42 0.9 \
text CAPTION textfont UI_FONT_NORMAL textscale 0.22 textalign ITEM_ALIGN_CENTER textalignx 0 textaligny (PH - 6) \
forecolor 0.85 0.85 0.87 1 visible when(FLAT_READY) onFocus { HINT_ON(HINT) } leaveFocus { HINT_OFF } action { play "mouse_click"; open POPUP; } } \
itemDef { rect (PX + (PW - IW) / 2) (PY + 5) IW IH 0 0 style WINDOW_STYLE_SHADER \
exp material(tablelookup("mp/statstable.csv", 4, dvarString(FIELD), 6)); forecolor 1 1 1 1 visible when(FLAT_READY) decoration }
#define FLAT_UTILITY(PX, LABEL, REF, MATERIAL) \
FLAT_OPTION(REF, PX, 307, 82, LABEL, "grenade:"REF, FLAT_READY, dvarInt("weap_allow_"REF), dvarString(loadout_grenade) == REF) \
itemDef { rect (PX + 5) 309 16 16 0 0 style WINDOW_STYLE_SHADER background MATERIAL forecolor 1 1 1 1 visible when(FLAT_READY) decoration }
#define FLAT_PICKER_ROW(PY, LABEL, REF, FIELD, RESPONSE, SHOW, IW) \
itemDef { name REF rect 8 PY 194 29 0 0 type ITEM_TYPE_BUTTON style WINDOW_STYLE_FILLED \
backcolor 0.04 0.04 0.045 0.85 text LABEL textfont UI_FONT_NORMAL textscale 0.29 textalignx 65 textaligny 20 \
textstyle ITEM_TEXTSTYLE_SHADOWEDMORE forecolor 0.85 0.85 0.87 1 \
visible when((SHOW) && dvarInt("weap_allow_"REF)) action { CASH_BEGIN play "mouse_click"; scriptMenuResponse RESPONSE; close self; } } \
itemDef { rect 8 PY 194 29 0 0 type ITEM_TYPE_TEXT style WINDOW_STYLE_FILLED backcolor 0.04 0.04 0.045 0.85 \
text LABEL textfont UI_FONT_NORMAL textscale 0.29 textalignx 65 textaligny 20 forecolor 0.35 0.35 0.37 1 \
visible when((SHOW) && !dvarInt("weap_allow_"REF)) decoration } \
itemDef { rect (14 + (48 - IW) / 2) (PY + 2) IW 24 0 0 style WINDOW_STYLE_SHADER \
exp material(tablelookup("mp/statstable.csv", 4, REF, 6)); forecolor 1 1 1 1 \
exp forecolor A(0.25 + 0.75 * dvarInt("weap_allow_"REF)); visible when(SHOW) decoration } \
itemDef { rect 8 PY 2 29 0 0 style WINDOW_STYLE_FILLED backcolor 1 0.81 0.53 1 visible when((SHOW) && dvarString(FIELD) == REF) decoration }
#define FLAT_PICK_PRIMARY(PY, LABEL, REF, CLASS) \
FLAT_PICKER_ROW(PY, LABEL, REF, loadout_primary, "primary:"REF, dvarString(loadout_class) == CLASS, 48)
#define FLAT_PICK_PISTOL(PY, LABEL, REF) \
FLAT_PICKER_ROW(PY, LABEL, REF, loadout_secondary, "secondary:"REF, FLAT_READY, 24)
#define FLAT_PICKER_FRAME(ROWS, TITLE) \
itemDef { rect 0 0 210 276 0 0 exp rect H(59 + 31 * ROWS); style WINDOW_STYLE_FILLED \
backcolor 0.16 0.16 0.175 1 border WINDOW_BORDER_FULL bordersize 1 bordercolor 0.4 0.4 0.42 1 visible 1 decoration } \
FLAT_TEXT(10, 7, 170, TITLE, 0.30) \
itemDef { rect 8 31 194 1 0 0 style WINDOW_STYLE_FILLED backcolor 0.4 0.4 0.42 1 visible 1 decoration } \
itemDef { name "close_picker" rect 183 5 19 19 0 0 type ITEM_TYPE_BUTTON text "x" textfont UI_FONT_NORMAL textscale 0.27 textalign ITEM_ALIGN_CENTER textalignx 0 textaligny 15 forecolor 0.9 0.9 0.92 1 visible 1 action { close self; } } \
itemDef { rect 10 257 190 17 0 0 exp rect Y(42 + 31 * ROWS); type ITEM_TYPE_TEXT text "Click to select / Esc to return" textfont UI_FONT_NORMAL textscale 0.20 textaligny 13 forecolor 0.7 0.7 0.72 1 visible 1 decoration }
#define FLAT_TEAM(PX, INDEX) \
itemDef { rect PX 405 89 41 0 0 style WINDOW_STYLE_FILLED backcolor 0.06 0.07 0.08 0.93 visible 1 decoration } \
FLAT_VALUE((PX + 5), 406, 80, dvarString("flat_mate_"INDEX"_name"), 0.22, 1) \
FLAT_VALUE((PX + 5), 420, 80, dvarString("flat_mate_"INDEX"_class"), 0.19, 1) \
FLAT_VALUE((PX + 5), 432, 80, dvarString("flat_mate_"INDEX"_cash"), 0.16, 1)
