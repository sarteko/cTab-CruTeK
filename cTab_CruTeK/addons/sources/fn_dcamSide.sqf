/*
    crutek_fnc_dcamSide
    Lato affidabile di un drone (senza equipaggio torna sideEmpty).

    0: OBJECT - drone
    Ritorna: SIDE
*/

params [["_uav", objNull]];
if (isNull _uav) exitWith { civilian };

private _side = side _uav;
if (_side in [west, east, resistance, civilian]) exitWith { _side };

private _crew = crew _uav;
if (_crew isEqualTo []) exitWith { civilian };

side (group (_crew select 0))
