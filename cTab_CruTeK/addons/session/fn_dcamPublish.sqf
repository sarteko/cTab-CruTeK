/*
    crutek_fnc_dcamPublish
    Gira su ogni client. Se sto comandando io la torretta di un mezzo,
    pubblico sul mezzo cosa sto vedendo: modo vista, modo A3TI e zoom. Chi
    guarda dal Galaxy lo rispecchia.

    Due sorgenti diverse: il terminale di un drone, oppure il posto torretta
    di un aereo o elicottero su cui sono fisicamente seduto.

    Si pubblica lo ZOOM, non la FOV: CBA_fnc_getFov misura rispetto allo
    schermo di chi la misura, mentre lo zoom e un rapporto puro e non dipende
    dalla forma dello schermo di nessuno.
*/

if (!crutek_dcam_hasA3TI) then {
    crutek_dcam_hasA3TI = !isNil "A3TI_fnc_getA3TIVision";
};

private _veh   = getConnectedUAV player;
private _isUav = !isNull _veh;

/*
    ---- posto di comando di un aereo o elicottero -------------------
    Vale sia il posto artigliere sia quello di pilotaggio: dove il pod e una
    pilotCamera lo punta chi sta ai comandi, e su certi aerei un posto
    artigliere non esiste nemmeno.
*/
if (!_isUav) then {
    private _v = vehicle player;
    if (
        !(_v isEqualTo player)
        && {_v isKindOf "Air"}
        && {
            ((gunner _v) isEqualTo player)
            || {(driver _v) isEqualTo player}
            || {
                !(([_v] call crutek_fnc_dcamCompMod) isEqualTo "")
                && {((allTurrets _v) findIf {(_v turretUnit _x) isEqualTo player}) >= 0}
            }
        }
    ) then {
        _veh = _v;
    };
};

if (isNull _veh) exitWith {};

// ---- sui droni serve verificare di essere al posto torretta ------
if (_isUav) then {
    private _all = UAVControl _veh;
    private _ok  = false;
    if (_all isEqualType []) then {
        private _idx = _all find player;
        if (_idx >= 0 && {(_idx + 1) < (count _all)}) then {
            private _role = _all select (_idx + 1);
            _ok = (_role isEqualType "") && {(toUpper _role) isEqualTo "GUNNER"};
        };
    };
    if (!_ok) exitWith { _veh = objNull };
};

if (isNull _veh) exitWith {};

// a bordo la vista da leggere e la mia, sia che piloti sia che punti
private _g      = if (_isUav) then { gunner _veh } else { player };
private _vision = if (isNull _g) then { 0 } else { currentVisionMode _g };

private _a3ti = "";
if (crutek_dcam_hasA3TI) then {
    private _v = call A3TI_fnc_getA3TIVision;
    if (!isNil "_v") then { _a3ti = _v };
};

private _fov = ([] call CBA_fnc_getFov) select 1;
if (_fov <= 0) then { _fov = -1 };

// indice della termica, letto dall'evento: 0 bianco caldo, 1 nero caldo
private _ti = missionNamespace getVariable ["crutek_dcam_tiIdx", 0];

private _same = false;
private _old  = _veh getVariable ["crutek_dcam_view", []];
if (count _old isEqualTo 4) then {
    _old params ["_ov", "_oa", "_of", "_ot"];
    _same = (_ov isEqualTo _vision) && {_oa isEqualTo _a3ti}
        && {abs (_of - _fov) < 0.0015} && {_ot isEqualTo _ti};
};
if (_same) exitWith {};

_veh setVariable ["crutek_dcam_view", [_vision, _a3ti, _fov, _ti], true];
