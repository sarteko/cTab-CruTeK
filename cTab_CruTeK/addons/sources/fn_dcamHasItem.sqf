/*
    crutek_fnc_dcamHasItem
    Verifica che l'unita abbia addosso uno degli item indicati.

    0: OBJECT - unita
    1: ARRAY  - classi da cercare (default: il Galaxy)
    Ritorna: BOOL
*/

params [["_unit", objNull], ["_wanted", []]];
if (isNull _unit) exitWith { false };
/*
    I dispositivi arrivano dalle due caselle nelle opzioni. La seconda puo'
    restare vuota, e in quel caso conta solo la prima.
*/
if (_wanted isEqualTo []) then {
    _wanted = [];
    {
        private _c = missionNamespace getVariable [_x, ""];
        if (_c isEqualType "" && {!(_c isEqualTo "")}) then { _wanted pushBackUnique _c };
    } forEach ["crutek_dcam_item1", "crutek_dcam_item2"];
    if (_wanted isEqualTo []) then { _wanted = [crutek_dcam_item] };
};

/*
    Ogni dispositivo di cTab ha due classi: quella dello slot terminali
    (ItemAndroid, ItemcTab) e la gemella Misc che si mette in uniforme,
    giubbetto o zaino (ItemAndroidMisc, ItemcTabMisc). Se l'opzione e'
    accesa vale anche la seconda.
*/
if (missionNamespace getVariable ["crutek_dcam_itemMisc", true]) then {
    private _piu = [];
    {
        _piu pushBackUnique _x;
        if (count _x > 4 && {(_x select [(count _x) - 4]) != "Misc"}) then {
            _piu pushBackUnique (_x + "Misc");
        };
    } forEach _wanted;
    _wanted = _piu;
};

if (!isNil "cTab_fnc_checkGear") exitWith {
    [_unit, _wanted] call cTab_fnc_checkGear
};

private _gear = (items _unit) + (assignedItems _unit);
_gear pushBack (goggles _unit);

({_x in _gear} count _wanted) > 0
