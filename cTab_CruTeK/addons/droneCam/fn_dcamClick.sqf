/*
    crutek_fnc_dcamClick
    Pulsanti del mouse sul feed.

    Tasto destro tenuto premuto      -> brandeggia la torretta, ma solo sui
                                        droni senza operatore e solo col
                                        telefono aperto (serve il cursore)
    Maiusc + rotella premuta         -> nasconde il video, mostra la mappa

    0: ARRAY  - parametri dell'evento [display, pulsante, x, y, maiusc, ctrl, alt]
    1: STRING - "down" oppure "up"

    Pulsanti: 0 sinistro, 1 destro, 2 rotella.
*/

params [["_ev", []], ["_kind", "down"]];
_ev params ["", ["_btn", -1], ["_mx", 0], ["_my", 0], ["_shift", false], ["_ctrl", false], ["_alt", false]];

// questo evento porta lo stato vero dei modificatori: si risincronizza il
// tracciamento, cosi un eventuale flag rimasto acceso si corregge da solo
crutek_dcam_mods = [_shift, _ctrl, _alt];

if (!crutek_dcam_active) exitWith { false };

// ---- rilascio del trascinamento ----------------------------------
if (_kind isEqualTo "up") exitWith {
    if (_btn isEqualTo 1 && {crutek_dcam_dragging}) then {
        ["STOP"] call crutek_fnc_dcamDrag;
        true
    } else {
        false
    };
};

// ---- rotella premuta: nascondi o rimostra ------------------------
if (_btn isEqualTo 2) exitWith {
    if (_shift && {!_ctrl} && {!_alt}) then {
        call crutek_fnc_dcamToggle;
        true
    } else {
        false
    };
};

// ---- tasto destro: inizio brandeggio -----------------------------
if (_btn != 1) exitWith { false };
if (_ctrl || {_shift} || {_alt}) exitWith { false };

// il cursore deve stare dentro il video
crutek_dcam_picRect params [["_px", 0], ["_py", 0], ["_pw", 0], ["_ph", 0]];
if (_pw <= 0 || {_ph <= 0}) exitWith { false };
if (_mx < _px || {_mx > (_px + _pw)} || {_my < _py} || {_my > (_py + _ph)}) exitWith { false };

["START"] call crutek_fnc_dcamDrag
