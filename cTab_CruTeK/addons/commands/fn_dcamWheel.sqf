/*
    crutek_fnc_dcamWheel
    Rotella del mouse sul feed.

    Maiusc + rotella -> cambia operatore, avanti e indietro.

    Tre paletti, tutti voluti:

      solo OpCam        sui mezzi la rotella non fa niente, la sorgente si
                        sceglie dal menu ACE
      feed a schermo    vale sul telefono aperto e sul telefonino sempre a
                        schermo, ma il feed deve vedersi: col dispositivo
                        chiuso la rotella resta al gioco
      solo con Maiusc   senza modificatori la rotella resta libera per il
                        gioco e per ACE

    I modificatori non arrivano con questo evento: si leggono da
    crutek_dcam_mods, che tiene dcamInput aggiornato sui tasti premuti.

    0: NUMBER - verso della rotella
    Ritorna: BOOL - true se il comando e stato gestito
*/

params [["_dir", 0]];

if (!crutek_dcam_active || {crutek_dcam_hidden}) exitWith { false };
if !(crutek_dcam_kind isEqualTo "HCAM") exitWith { false };
if (_dir isEqualTo 0) exitWith { false };

// il feed deve essere a schermo, su una delle due forme del telefono
if (crutek_dcam_overlayOn isEqualTo "") exitWith { false };

/*
    Col telefono aperto l'evento della rotella puo arrivare due volte, dal
    dialogo e dal display di gioco. Due chiamate ravvicinate sarebbero due
    operatori saltati invece di uno, quindi la seconda si butta.
*/
if (diag_tickTime < crutek_dcam_wheelTick) exitWith { false };
crutek_dcam_wheelTick = diag_tickTime + 0.06;

crutek_dcam_mods params [["_shift", false], ["_ctrl", false], ["_alt", false]];
if (!_shift || {_ctrl} || {_alt}) exitWith { false };

[if (_dir > 0) then { 1 } else { -1 }] call crutek_fnc_dcamNext;
true
