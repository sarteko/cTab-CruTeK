/*
    crutek_fnc_dcamClose
    Spegne il feed e ripulisce controlli, camera e handler.
*/

if (!crutek_dcam_active) exitWith {};
crutek_dcam_active = false;

crutek_dcam_dragging = false;
crutek_dcam_fullNow  = false;

// se il mondo era ridipinto per la ricetta A3TI, va rimesso a posto
[false] call crutek_fnc_dcamWorld;

// si restituisce la torretta all'IA, altrimenti resta puntata dove l'ho lasciata
if (crutek_dcam_locked && {!isNull crutek_dcam_uav}) then {
    [crutek_dcam_uav, [objNull, [0]]] remoteExec ["lockCameraTo", crutek_dcam_uav];
    crutek_dcam_locked = false;
};

["OFF"] call crutek_fnc_dcamOverlay;

// distanza visiva e oggetti com'erano, e solo se li avevamo alzati noi
if (crutek_dcam_prevVD > 0) then {
    setViewDistance crutek_dcam_prevVD;
    if (crutek_dcam_prevOVD > 0) then { setObjectViewDistance crutek_dcam_prevOVD };
    crutek_dcam_prevVD  = -1;
    crutek_dcam_prevOVD = -1;
};

if !(isNull crutek_dcam_cam) then {
    crutek_dcam_cam cameraEffect ["TERMINATE", "BACK", crutek_dcam_rt];
    camDestroy crutek_dcam_cam;
};
crutek_dcam_cam = objNull;

if !(isNull crutek_dcam_hcamTgt) then {
    detach crutek_dcam_hcamTgt;
    deleteVehicle crutek_dcam_hcamTgt;
    crutek_dcam_hcamTgt = objNull;
};

["crutek_dcam", "onEachFrame"] call BIS_fnc_removeStackedEventHandler;

private _d46 = findDisplay 46;
if !(isNull _d46) then {
    {
        _x params ["_type", "_id"];
        if (_id >= 0) then { _d46 displayRemoveEventHandler [_type, _id] };
    } forEach [
        ["KeyDown",       crutek_dcam_ehKey],
        ["KeyUp",         crutek_dcam_ehKeyUp],
        ["MouseButtonDown", crutek_dcam_ehClick],
        ["MouseButtonUp",   crutek_dcam_ehUp],
        ["MouseZChanged",   crutek_dcam_ehWheel]
    ];
};
crutek_dcam_ehKey   = -1;
crutek_dcam_ehKeyUp = -1;
crutek_dcam_ehClick = -1;
crutek_dcam_ehUp    = -1;
crutek_dcam_ehWheel = -1;

player setVariable ["crutek_dcam_watching", objNull, true];
crutek_dcam_uav   = objNull;
crutek_dcam_effective = "";
crutek_dcam_hasOp     = false;
crutek_dcam_hidden = false;
crutek_dcam_graceT = -1;
