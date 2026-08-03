/*
    crutek_fnc_dcamInput
    Due compiti.

    1) Tiene aggiornato lo stato dei modificatori per la rotella, che nel suo
       evento non li riceve. Attenzione al caso che sembra banale e non lo e:
       quando si RILASCIA il Maiusc, l'evento KeyUp riporta comunque
       shift = true, perche e lo stato al momento dell'evento e non dopo.
       Fidandosi di quel valore il flag resta acceso per sempre e la rotella
       zooma anche senza premere niente. Per questo, se il tasto rilasciato e
       proprio un modificatore, il suo flag si forza a spento.

    2) Col telefono aperto a tutto schermo i keybind di CBA non arrivano, se
       li prende il dialogo. In quel caso i tasti si gestiscono qui, secondo
       la tabella crutek_dcam_dlgKeys.

    0: ARRAY - parametri dell'evento [display, tasto, maiusc, ctrl, alt]
    1: BOOL  - true se e una pressione, false se e un rilascio
*/

params [["_ev", []], ["_down", true]];
_ev params [["_disp", displayNull], ["_key", -1], ["_shift", false], ["_ctrl", false], ["_alt", false]];

// ---- stato dei modificatori --------------------------------------
private _s = if (_key in [42, 54])  then { _down } else { _shift };
private _c = if (_key in [29, 157]) then { _down } else { _ctrl };
private _a = if (_key in [56, 184]) then { _down } else { _alt };
crutek_dcam_mods = [_s, _c, _a];

if (!_down) exitWith { false };
if (!crutek_dcam_active) exitWith { false };

// ---- tasti col telefono aperto -----------------------------------
// solo se l'evento arriva da un dialogo: sul display di gioco ci pensa CBA,
// e agire anche qui vorrebbe dire eseguire il comando due volte
if (_disp isEqualTo (findDisplay 46)) exitWith { false };

private _hit = false;
{
    _x params ["_k", "_ms", "_mc", "_ma", "_code"];
    if (_key isEqualTo _k && {_s isEqualTo _ms} && {_c isEqualTo _mc} && {_a isEqualTo _ma}) exitWith {
        call _code;
        _hit = true;
    };
} forEach crutek_dcam_dlgKeys;

_hit
