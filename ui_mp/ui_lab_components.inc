// UI learning components, added 2026-10-09. See LICENSE.md.
// Menu textscale and GSC fontScale are separate APIs.
#define LAB_REVEAL sin( sin( min( max( milliseconds() - dvarInt(ui_lab_open_time), 0 ), 280 ) * (1.5707 / 280) ) * 1.5707 )
#define LAB_SURFACE(PX, PY, PW, PH, PAGE, MATERIAL, OPACITY) \
itemDef { rect PX PY PW PH 0 0 style WINDOW_STYLE_SHADER \
exp rect X( PX + (PW * (1 - LAB_REVEAL) / 2) ); \
exp rect Y( PY + (PH * (1 - LAB_REVEAL) / 2) ); \
exp rect W( max(1, PW * LAB_REVEAL) ); exp rect H( max(1, PH * LAB_REVEAL) ); \
exp material( MATERIAL ); forecolor 1 1 1 1 exp forecolor A( OPACITY ); \
visible when ( dvarInt(ui_lab_page) == PAGE ) decoration }

#define LAB_BORDER(PX, PY, PW, PH, PAGE) \
itemDef { rect PX PY PW PH 0 0 style WINDOW_STYLE_SHADER \
exp rect X( PX + PW / 2 - PW * LAB_REVEAL ); \
exp rect Y( PY + PH / 2 - PH * 1.6 * LAB_REVEAL ); \
exp rect W( max(1, PW * 2 * LAB_REVEAL) ); exp rect H( max(1, PH * 3.2 * LAB_REVEAL) ); \
background "lab_glow_button" forecolor 1 1 1 0.65 \
visible when ( dvarInt(ui_lab_page) == PAGE ) decoration } \
itemDef { rect PX PY PW PH 0 0 style WINDOW_STYLE_SHADER \
exp rect X( PX + (PW * (1 - LAB_REVEAL) / 2) ); \
exp rect Y( PY + (PH * (1 - LAB_REVEAL) / 2) ); \
exp rect W( max(1, PW * LAB_REVEAL) ); exp rect H( max(1, PH * LAB_REVEAL) ); \
background "lab_corner_button" forecolor 1 1 1 0.95 \
visible when ( dvarInt(ui_lab_page) == PAGE ) decoration }

#define LAB_TEXT(ID, X, Y, W, LABEL, SIZE, PAGE) \
itemDef { name ID rect X Y W 22 0 0 type ITEM_TYPE_TEXT text LABEL \
textfont UI_FONT_NORMAL textscale SIZE textaligny 17 forecolor 0.86 0.90 0.94 1 \
visible when ( dvarInt(ui_lab_page) == PAGE && LAB_REVEAL > 0.98 ) decoration }

#define LAB_PANEL(ID, X, Y, W, H, PAGE) \
itemDef { name ID rect X Y W H 0 0 style WINDOW_STYLE_FILLED \
backcolor 0.07 0.095 0.12 0.96 border WINDOW_BORDER_FULL bordercolor 0.18 0.27 0.32 1 \
bordersize 1 visible when ( dvarInt(ui_lab_page) == PAGE ) decoration }

#define LAB_ACTION_BUTTON(ID, X, Y, W, LABEL, ACTION, PAGE) \
LAB_SURFACE(X, Y, W, 28, PAGE, dvarString(ui_lab_material), dvarFloat(ui_lab_opacity)) \
LAB_BORDER(X, Y, W, 28, PAGE) \
itemDef { name ID rect X Y W 28 0 0 type ITEM_TYPE_BUTTON style WINDOW_STYLE_EMPTY \
text LABEL textfont UI_FONT_NORMAL textscale 0.28 textalign ITEM_ALIGN_CENTER \
textalignx 0 textaligny 20 forecolor 0.90 0.96 1 1 visible when ( dvarInt(ui_lab_page) == PAGE && LAB_REVEAL > 0.98 ) \
action { ACTION } }

#define LAB_BUTTON(ID, X, Y, W, LABEL, RESPONSE, PAGE) \
LAB_ACTION_BUTTON(ID, X, Y, W, LABEL, scriptMenuResponse RESPONSE;, PAGE)
