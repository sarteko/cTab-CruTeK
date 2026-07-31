/*
    crutek_fnc_dcamHasItem
    Verifica che l'unita abbia addosso uno degli item indicati.

    0: OBJECT - unita
    1: ARRAY  - classi da cercare (default: il Galaxy)
    Ritorna: BOOL
*/

params [["_unit", objNull], ["_wanted", []]];
if (isNull _unit) exitWith { false };
if (_wanted isEqualTo []) then { _wanted = [crutek_dcam_item] };

if (!isNil "cTab_fnc_checkGear") exitWith {
    [_unit, _wanted] call cTab_fnc_checkGear
};

private _gear = (items _unit) + (assignedItems _unit);
_gear pushBack (goggles _unit);

({_x in _gear} count _wanted) > 0
