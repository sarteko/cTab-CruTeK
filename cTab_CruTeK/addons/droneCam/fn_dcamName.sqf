/*
    crutek_fnc_dcamName
    Nome leggibile di un drone per lista e schermo.

    0: OBJECT - drone
    Ritorna: STRING
*/

params [["_uav", objNull]];
if (isNull _uav) exitWith { "sconosciuto" };

private _custom = _uav getVariable ["crutek_dcam_name", ""];
if (_custom != "") exitWith { _custom };

if (_uav isKindOf "CAManBase") exitWith { name _uav };

private _label = vehicleVarName _uav;
if (_label isEqualTo "") then {
    _label = getText (configFile >> "CfgVehicles" >> typeOf _uav >> "displayName");
};
if (_label isEqualTo "") then { _label = typeOf _uav };

_label
