// Visual communication components. See LICENSE.md.
#include "ui_mp/flat_loadout_components.inc"
#define BUY_CLOSED (dvarInt(flat_economy_live) && !dvarInt(economy_buy_open))
#define LIVE_BUY_OPEN (dvarInt(flat_economy_live) && dvarInt(economy_buy_open))
#define BUY_OPEN (dvarInt(flat_economy_live) == 0 || dvarInt(economy_buy_open))
#define PURCHASE_OPEN (dvarInt(flat_economy_live) == 0 || dvarInt(economy_purchase_allowed))
#define WAIT_FOR_SPAWN (dvarInt(flat_economy_live) && dvarInt(economy_buy_open) && !dvarInt(economy_purchase_allowed))
#define RICH_PRICE(PX, PY, PW, VALUE, SIZE, SHOW) \
itemDef { rect PX PY PW 20 0 0 type ITEM_TYPE_TEXT exp text(VALUE); textfont UI_FONT_NORMAL textscale SIZE \
textaligny 15 textstyle ITEM_TEXTSTYLE_SHADOWED forecolor MONEY_COLOR exp forecolor A(0.4 + 0.6 * PURCHASE_OPEN); visible when((SHOW) && BUY_CLOSED == 0) decoration }
#define CASH_BEGIN exec "setdvartotime flat_cash_start"; setDvar flat_cash_anim "1";
#define CASH_PROGRESS min(1, max(0, (milliseconds() - dvarInt(flat_cash_start)) / 300.0))
#define CASH_RENDER int(dvarInt(flat_cash_from) + (dvarInt(flat_cash_to) - dvarInt(flat_cash_from)) * CASH_PROGRESS)
#define RICH_VALUE(PX, PY, PW, VALUE, SIZE, COLOR, SHOW) \
itemDef { rect PX PY PW 20 0 0 type ITEM_TYPE_TEXT exp text(VALUE); textfont UI_FONT_NORMAL textscale SIZE \
textaligny 15 textstyle ITEM_TEXTSTYLE_SHADOWED forecolor COLOR visible when(SHOW) decoration }
#define CAN_BUY_DEMO dvarInt(flat_economy_live) && dvarInt(economy_purchase_allowed) && dvarInt(economy_demolition_available) && dvarInt(economy_cash) >= dvarInt(economy_demolition_price)
#define CLASS_ACTIVE(CLASS) (dvarInt("flat_"CLASS"_allowed") || (CLASS == "demolitions" && CAN_BUY_DEMO))
#define CLASS_INACTIVE(CLASS) (CLASS_ACTIVE(CLASS) == 0)
#define RICH_CLASS(PY, KEY, LABEL, CLASS, RESPONSE, ICON, IH) \
itemDef { rect 16 PY 172 43 0 0 style WINDOW_STYLE_SHADER background "gradient" forecolor 0.14 0.15 0.17 0.72 visible 1 decoration } \
itemDef { rect 16 PY 172 43 0 0 style WINDOW_STYLE_SHADER background "gradient" forecolor 0.7 0.7 0.73 0.15 \
visible when((dvarString(flat_hover_class) == CLASS && CLASS_ACTIVE(CLASS)) || (FLAT_READY && dvarString(loadout_class) == CLASS)) decoration } \
itemDef { rect 102 (PY + (43 - IH) / 2) 84 IH 0 0 style WINDOW_STYLE_SHADER background ICON forecolor 1 1 1 1 exp forecolor A(0.08 + 0.08 * (FLAT_READY && dvarString(loadout_class) == CLASS)); visible 1 decoration } \
itemDef { rect 16 (PY + 42) 172 1 0 0 style WINDOW_STYLE_FILLED backcolor 0.42 0.43 0.46 0.32 visible 1 decoration } \
itemDef { rect 16 PY 172 43 0 0 style WINDOW_STYLE_FILLED backcolor 0 0 0 0.40 visible when(CLASS_INACTIVE(CLASS)) decoration } \
itemDef { rect 16 PY 172 43 0 0 type ITEM_TYPE_BUTTON text LABEL textfont UI_FONT_NORMAL textscale 0.31 textalignx 30 textaligny 20 \
textstyle ITEM_TEXTSTYLE_SHADOWEDMORE forecolor CLASS_COLOR visible when(dvarInt("flat_"CLASS"_allowed") || (CLASS == "demolitions" && CAN_BUY_DEMO)) \
onFocus { setDvar flat_hover_class CLASS; } leaveFocus { setDvar flat_hover_class ""; } action { CASH_BEGIN scriptMenuResponse RESPONSE; } } \
itemDef { rect 16 PY 172 43 0 0 type ITEM_TYPE_BUTTON text LABEL textfont UI_FONT_NORMAL textscale 0.31 textalignx 30 textaligny 20 \
forecolor 0.4 0.4 0.42 1 visible when(CLASS_INACTIVE(CLASS)) action { scriptMenuResponse RESPONSE; } } \
itemDef { rect 23 (PY + 5) 16 18 0 0 type ITEM_TYPE_TEXT text KEY textfont UI_FONT_NORMAL textscale 0.26 textaligny 14 \
forecolor 0.95 0.95 0.97 1 visible 1 decoration } \
itemDef { rect 16 PY 2 43 0 0 style WINDOW_STYLE_FILLED backcolor CLASS_COLOR visible when(FLAT_READY && dvarString(loadout_class) == CLASS) decoration } \
RICH_VALUE(27, (PY + 22), 65, dvarString("flat_"CLASS"_capacity"), 0.20, 0.75 0.77 0.8 1, 1) \
RICH_VALUE(99, (PY + 22), 34, "FULL", 0.16, 0.4 0.4 0.42 1, CLASS_INACTIVE(CLASS) && CLASS != "demolitions" && dvarInt("flat_"CLASS"_count") >= dvarInt("flat_"CLASS"_limit"))
#define ATTACH_FOCUS(RESPONSE, HINT) onFocus { setDvar flat_hover_attachment RESPONSE; HINT_ON(HINT) } leaveFocus { setDvar flat_hover_attachment ""; HINT_OFF }
#define RICH_ATTACHMENT(PX, PY, PW, RESPONSE, MATERIAL, SHOW, SELECTED, ALLOW, PRICE, COLOR, HINT) \
itemDef { rect PX PY PW 28 0 0 type ITEM_TYPE_BUTTON style WINDOW_STYLE_FILLED backcolor 0 0 0 0.42 border WINDOW_BORDER_FULL bordersize 1 bordercolor 0.4 0.4 0.42 0.7 \
visible when((SHOW) && (ALLOW)) ATTACH_FOCUS(RESPONSE, HINT) action { play "mouse_click"; CASH_BEGIN scriptMenuResponse RESPONSE; } } \
itemDef { rect PX PY PW 28 0 0 type ITEM_TYPE_BUTTON style WINDOW_STYLE_EMPTY visible when((SHOW) && (ALLOW) == 0) ATTACH_FOCUS(RESPONSE, HINT) action { scriptMenuResponse RESPONSE; } } \
itemDef { rect PX PY PW 28 0 0 style WINDOW_STYLE_FILLED backcolor 0 0 0 0.4 visible when((SHOW) && (ALLOW) == 0) decoration } \
itemDef { rect PX PY PW 28 0 0 style WINDOW_STYLE_FILLED backcolor 0.23 0.24 0.25 0.60 border WINDOW_BORDER_FULL bordersize 1 bordercolor 0.8 0.8 0.82 0.8 visible when((SHOW) && (ALLOW) && dvarString(flat_hover_attachment) == RESPONSE) decoration } \
itemDef { rect (PX + (PW - 20) / 2) (PY + 4) 20 20 0 0 style WINDOW_STYLE_SHADER background MATERIAL forecolor 1 1 1 1 exp forecolor A(0.60 + 0.30 * (SELECTED) + 0.10 * ((ALLOW) && dvarString(flat_hover_attachment) == RESPONSE)); visible when((SHOW) && MATERIAL != "white") decoration } \
itemDef { rect PX (PY + 18) PW 10 0 0 type ITEM_TYPE_TEXT style WINDOW_STYLE_FILLED backcolor 0 0 0 0.38 exp text(PRICE); textfont UI_FONT_NORMAL textscale 0.13 textalign ITEM_ALIGN_CENTER textalignx 0 textaligny 8 forecolor COLOR exp forecolor A(0.4 + 0.6 * (ALLOW)); visible when((SHOW) && PRICE != "" && BUY_CLOSED == 0) decoration } \
itemDef { rect PX PY PW 28 0 0 type ITEM_TYPE_TEXT text "NONE" textfont UI_FONT_NORMAL textscale 0.15 textalign ITEM_ALIGN_CENTER textalignx 0 textaligny 18 forecolor 0.85 0.87 0.9 1 visible when((SHOW) && MATERIAL == "white") decoration } \
itemDef { rect PX PY 2 28 0 0 style WINDOW_STYLE_FILLED backcolor CLASS_COLOR visible when((SHOW) && (SELECTED)) decoration }
// Gear row: armor column (economy only) left of the grenades box, which widens when armor is hidden.
#define ARMOR_ON (dvarInt(flat_economy_live) && dvarInt(economy_armor_capacity) > 0)
#define ARMOR_CHARGES dvarInt(economy_armor_charges)
#define ARMOR_OPEN (ARMOR_CHARGES < dvarInt(economy_armor_capacity))
#define GEAR_X (220 + 90 * ARMOR_ON)
#define GEAR_W (386 - 90 * ARMOR_ON)
#define GEAR_HALF (GEAR_W / 2)
#define GEAR_ICON_X(OFFSET) (GEAR_X + OFFSET + (GEAR_HALF - 64) / 2)
#define RICH_TEAM(PX, INDEX) \
itemDef { rect PX 400 89 56 0 0 style WINDOW_STYLE_SHADER background "gradient" forecolor 0.11 0.13 0.12 0.85 visible 1 decoration } \
itemDef { rect PX 400 89 56 0 0 style WINDOW_STYLE_FILLED backcolor 0.13 0.34 0.17 0.42 visible when(dvarInt("flat_mate_"INDEX"_exists") && dvarString(flat_hover_mate) == INDEX && BUY_OPEN) decoration } \
itemDef { rect PX 455 89 1 0 0 style WINDOW_STYLE_FILLED backcolor 0.35 0.43 0.36 0.6 visible 1 decoration } \
RICH_VALUE((PX + 5), 401, 80, dvarString("flat_mate_"INDEX"_name"), 0.22, 0.9 0.9 0.92 1, dvarInt("flat_mate_"INDEX"_exists")) \
RICH_VALUE((PX + 5), 419, 46, dvarString("flat_mate_"INDEX"_cash"), 0.20, MONEY_COLOR, dvarInt("flat_mate_"INDEX"_exists")) \
itemDef { rect (PX + 45) 416 40 20 0 0 style WINDOW_STYLE_SHADER exp material(tablelookup("mp/statstable.csv", 4, dvarString("flat_mate_"INDEX"_primary"), 6)); forecolor 1 1 1 0.9 \
visible when(dvarInt("flat_mate_"INDEX"_exists") && dvarString("flat_mate_"INDEX"_primary") != "") decoration } \
itemDef { rect (PX + 45) 416 40 20 0 0 style WINDOW_STYLE_FILLED backcolor 0.06 0.17 0.08 0.95 visible when(dvarInt("flat_mate_"INDEX"_can_give") && dvarString(flat_hover_mate) == INDEX) decoration } \
RICH_VALUE((PX + 45), 419, 40, "+$50", 0.22, MONEY_COLOR, dvarInt("flat_mate_"INDEX"_can_give") && dvarString(flat_hover_mate) == INDEX) \
itemDef { rect (PX + 5) 438 14 14 0 0 style WINDOW_STYLE_SHADER exp material(dvarString("flat_mate_"INDEX"_utility")); forecolor 1 1 1 1 visible when(dvarInt("flat_mate_"INDEX"_exists")) decoration } \
itemDef { rect (PX + 23) 438 14 14 0 0 style WINDOW_STYLE_SHADER background "weapon_attachment_suppressor" forecolor 1 1 1 1 visible when(dvarInt("flat_mate_"INDEX"_exists") && dvarString("flat_mate_"INDEX"_attachment") == "silencer") decoration } \
itemDef { rect (PX + 41) 438 14 14 0 0 style WINDOW_STYLE_SHADER background "weapon_fraggrenade" forecolor 1 1 1 1 visible when(dvarInt("flat_mate_"INDEX"_exists") && dvarInt("flat_mate_"INDEX"_frag")) decoration } \
RICH_VALUE((PX + 58), 436, 27, dvarString("flat_mate_"INDEX"_class"), 0.12, 0.65 0.68 0.7 1, dvarInt("flat_mate_"INDEX"_exists")) \
RICH_VALUE((PX + 9), 419, 75, "OPEN SLOT", 0.18, 0.45 0.47 0.5 1, !dvarInt("flat_mate_"INDEX"_exists")) \
itemDef { rect PX 400 89 56 0 0 type ITEM_TYPE_BUTTON style WINDOW_STYLE_EMPTY backcolor 0 0 0 0 visible when(dvarInt("flat_mate_"INDEX"_exists")) onFocus { setDvar flat_hover_mate INDEX; HINT_ON("Click to give this teammate $50") } leaveFocus { setDvar flat_hover_mate ""; HINT_OFF } action { play "mouse_click"; CASH_BEGIN execnow "vstr flat_mate_"INDEX"_give"; } }
#define RICH_PRIMARY_ROW(PY, INDEX, NINDEX) \
itemDef { rect 8 PY 194 29 0 0 type ITEM_TYPE_BUTTON style WINDOW_STYLE_FILLED backcolor 0.04 0.04 0.045 0.85 \
exp text(dvarString("flat_primary_"INDEX"_name")); textfont UI_FONT_NORMAL textscale 0.29 textalignx 65 textaligny 20 textstyle ITEM_TEXTSTYLE_SHADOWEDMORE forecolor 0.9 0.9 0.92 1 \
visible when(dvarInt(flat_primary_rows) > NINDEX) action { CASH_BEGIN play "mouse_click"; scriptMenuResponse "pick_primary:"INDEX; close self; } } \
itemDef { rect 14 (PY + 2) 48 24 0 0 style WINDOW_STYLE_SHADER exp material(tablelookup("mp/statstable.csv", 4, dvarString("flat_primary_"INDEX"_ref"), 6)); forecolor 1 1 1 1 visible when(dvarInt(flat_primary_rows) > NINDEX) decoration } \
itemDef { rect 8 PY 2 29 0 0 style WINDOW_STYLE_FILLED backcolor CLASS_COLOR visible when(dvarInt(flat_primary_rows) > NINDEX && dvarString(loadout_primary) == dvarString("flat_primary_"INDEX"_ref")) decoration }
