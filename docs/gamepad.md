# Gamepad support (0.8)

How auxForever works with a controller in Forever's gamepad mode, why it is built the way it is,
and what was found in Blizzard's code and in game on the way. Built and tested in game on
2026-10-13 by a contributor (GitHub nokkty, branch `gamepad-navigation` of their fork). The code is
`auxForever/gamepad.lua`; its tests are the `gamepad` entries in `tests/load_test.lua`.

Nothing in this file applies with mouse and keyboard: every part checks for gamepad mode
(`InputUtil.IsGamepadUIEnabled`) and does nothing otherwise.

## What the player gets

| Button | What it does |
| --- | --- |
| D-pad | Moves a gold frame to the nearest control in that direction. In a list, past the last row shown, it scrolls the list. |
| A | Presses the control. A text box starts typing; a dropdown opens, then up and down walk its options and A picks one. On a Sniper deal, the gold frame then moves to the buy bar's Buy button once it shows. |
| B | Closes what is open, in this order: a dropdown, typing in a text box, a popup (Settings, quick searches, the Filter Builder menu, aux's own popups), then aux. On the buy bar after a Sniper deal, B goes back to the deal. |
| X | A right-click on the control: search from a bag item, add or remove a favorite, clear a text box. |
| Y | The open tab's main action: Buy and then Confirm on Search, Start or Stop on Sniper, Post on Post, Cancel on Auctions, Buyout on Bids. |
| LB / RB | Step through the top bar: the five tabs switch at once; after them come Settings, Full scan and Blizzard UI (A presses them). It wraps round at both ends. |

aux opens with the focus on the top-left control of the tab. The top bar is reached only with LB
and RB, so the D-pad stays inside the tab. A strip under the window shows the buttons with the
controller's own icons and what each does on the control in focus; Y shows only while its button
can be pressed. Y never spends money on the Sniper: there, buying is A on the deal, A on Buy, A on
Confirm.

The Blizzard UI button gives the pad back to Blizzard's own navigation while Blizzard's window is
shown, and aux takes it again once it is hidden.

## How it works

- **aux's own bindings.** While aux is open in gamepad mode, aux binds the D-pad, A, B, X, Y, LB
  and RB to buttons of its own with `SetOverrideBindingClick` on a frame it owns, one frame after
  aux shows, and clears them when aux closes. Tested: these win over Blizzard's navigation, which
  still drives the invisible Blizzard auction house window, and stay won. A press through such a
  binding is a hardware event, so buying, bidding, posting and cancelling work from it.
- **Combat.** Bindings cannot change in combat. aux does not take the buttons when it opens in
  combat, and if it closes in combat it gives them back once combat ends
  (`PLAYER_REGEN_ENABLED`).
- **Finding controls.** On each press, aux walks its window's visible frames: buttons, text boxes,
  and frames with a mouse-down or mouse-up script (the Post tab's bag list rows). It does not look
  inside a found control (a row's icon is part of the row), except inside text boxes (the Post
  tab's -, + and Max are children of its quantity boxes). Scroll frames, sliders, the resize
  corner, the close button and the top bar are left out. A visible frame in the `DIALOG` layer
  (Settings, quick searches, the Filter Builder menu, aux's dialog) keeps the focus inside it.
- **Moving.** The nearest control in the pressed direction wins: distance along the direction plus
  twice the distance across it. Up or down from a list row, when the nearest control is not a row
  of the same list, the list's scroll bar moves one row instead, while it can.
- **Pressing.** A button with an `OnClick` gets `Click`; other frames get their mouse-down and
  mouse-up scripts. X does the same with the right button. Text boxes get `SetFocus`.
- **Dropdowns** open their menu in a frame outside aux's window (`gui.dropdown_menu`); while it is
  open, up and down move the gold frame over its options and A runs the option's mouse-down, as a
  click does.
- **Popups.** aux's popups (`StaticPopupDialogs.AUX_*`) go through `aux.show_popup` and
  `aux.hide_popup`. In gamepad mode they open in a dialog of aux's own built from the same
  definition (text, buttons, OnShow, OnAccept, OnCancel, OnHide, edit box), with the focus on
  Cancel or No when there are two buttons. With mouse and keyboard they are the game's popups as
  before.
- **Hints.** The strip is checked four times a second while it is shown, since buttons appear and
  grey out without a pad press, and redrawn only on a change. Nothing else runs on a timer, and
  nothing runs with aux closed or with mouse and keyboard.

## Do not touch Blizzard's gamepad code

aux must never write into Blizzard's gamepad system: `GamepadMode`, `SmartNavigation`, the window
manager (`GamepadMode.FrameControlsManager`) or its binding groups (`CreateBindingGroup`,
`ActivateBindingGroup`, `DeactivateBindingGroup`). Whatever aux's code writes there is tainted,
and Blizzard's own code fails later when it reads it.

What happened (2026-10-13, `Logs/taint.log`): the first version registered aux with Blizzard's
window manager (`FrameControlsManager:FrameShown`), so that Blizzard's navigation
(`SmartNavigation`) would drive aux's window. Opening worked. Closing aux by pad made Blizzard's
code call `SetPreferredGamepadInteractTarget()` from tainted code; it was blocked, the game's
"blocked" popup registered with the same tainted manager and was blocked too, 259 times in a
second, and the game froze. The same applies to showing a Blizzard popup (`StaticPopup_Show`)
from aux's code in gamepad mode, which is why aux shows its own dialog there.

Reading is fine. aux reads `InputUtil.IsGamepadUIEnabled()` and, for the hint icons,
`InputIconTextureSetUtility.GetNormalActiveInputIconButtonTexture('PAD1')`, a lookup into
Blizzard's icon table for the controller in use (PADChat does the same).

`C_Texture.GetAtlasInfo` must not be used: on Forever it fails with "unable to find mixin or
metatable (Vector2DMixin)" (BugSack, 2026-10-13).

## Sources

Blizzard's UI code for Forever, `Gethe/wow-ui-source`, branch `forever`, build 70374:

- `Blizzard_GamepadSharedUtility/FrameControlsManager.lua`: the window manager. "A frame can
  subscribe to this by either being a part of ShowUIPanel or by manually calling FrameShown."
- `Blizzard_GamepadSmartNavigation/SmartNavigation.lua` and `Utility.lua`: the navigation; it
  takes every Button and EditBox of the window it drives.
- `Blizzard_GamepadSharedUtility/InputBindingStack/*`: every gamepad binding is a
  `SetOverrideBindingClick` on `UIParent`.
- `Blizzard_SharedXML/Shared/InputIcons/InputIconTexture.lua`: the controller icons.

## Finding problems in game

- **Script errors:** with BugSack installed, errors are saved to
  `WTF/Account/<account>/SavedVariables/!BugGrabber.lua` at logout.
- **Blocked actions:** add `SET taintLog "2"` to `WTF/Config.wtf` while the game is closed, play,
  log out, and read `Logs/taint.log`. The game drops the line when it saves `Config.wtf`, so it
  lasts one game session. A clean session shows no "An action was blocked" line; aux's three
  "Execution tainted by auxForever while reading global" lines (`aux_frame`, `SLASH_AUX1`,
  `SLASH_AUX2`) were there before gamepad support and do no harm.
