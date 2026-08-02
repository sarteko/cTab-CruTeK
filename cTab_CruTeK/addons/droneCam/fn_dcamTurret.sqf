/*
    crutek_fnc_dcamTurret
    Come si legge il puntamento della camera di questo mezzo.

    Quattro modi possibili:

    "MEM"       memory point uavCameraGunnerPos e Dir, roba dei droni, la
                stessa che usa cTab per le sue UAV cam
    "PILOTCAM"  pod di puntamento, letto con getPilotCameraDirection
    "TURRET"    dove punta l'arma della torretta
    "NOSE"      dritto davanti, ripiego per i soli mezzi che volano

    L'ORDINE DI PRIORITA CAMBIA CON L'AMBIENTE, e non e un dettaglio: diversi
    carri ereditano una classe pilotCamera da un antenato pur non avendo un
    pod vero. Controllando il pod per primo venivano classificati PILOTCAM,
    getPilotCameraDirection non restituiva niente di utile e la camera
    restava piantata. Su un mezzo di terra la vista primaria e la torretta.

        vola:     MEM -> PILOTCAM -> TURRET -> NOSE
        non vola: MEM -> TURRET   -> PILOTCAM

    0: OBJECT - mezzo
    Ritorna: ARRAY - [memoryPointPos, memoryPointDir, modo]
             modo vuoto se non c'e niente da leggere
*/

params [["_veh", objNull]];
if (isNull _veh) exitWith { ["", "", ""] };

private _cfg  = configFile >> "CfgVehicles" >> typeOf _veh;
private _aria = _veh isKindOf "Air";

// ---- candidato: memory point dei droni ---------------------------
private _pos = "";
private _dir = "";
{
    private _p = getText (_cfg >> ("uavCamera" + _x + "Pos"));
    private _d = getText (_cfg >> ("uavCamera" + _x + "Dir"));
    if (_p != "" && {_d != ""}) exitWith {
        _pos = _p;
        _dir = _d;
    };
} forEach ["Gunner", "Driver"];

/*
    I memory point dichiarati dentro pilotCamera valgono solo per chi vola:
    su un mezzo di terra sarebbero quelli ereditati da un antenato, e
    punterebbero da tutt'altra parte.
*/
if (_pos isEqualTo "" && {_aria}) then {
    private _pc = _cfg >> "pilotCamera";
    if (isClass _pc) then {
        {
            _x params ["_kPos", "_kDir"];
            private _p = getText (_pc >> _kPos);
            private _d = getText (_pc >> _kDir);
            if (_p != "" && {_d != ""}) exitWith {
                _pos = _p;
                _dir = _d;
            };
        } forEach [
            ["memoryPointsCamera", "memoryPointsCameraDir"],
            ["memoryPointCamera",  "memoryPointCameraDir"]
        ];
    };
};

// ---- candidato: pod di puntamento --------------------------------
private _pod = isClass (_cfg >> "pilotCamera");
if (!_pod) then {
    private _p = getPilotCameraPosition _veh;
    _pod = (_p isEqualType []) && {(count _p) isEqualTo 3} && {!(_p isEqualTo [0,0,0])};
};

// ---- candidato: torretta armata ----------------------------------
// serve una torretta E un'arma, altrimenti non c'e niente da guardare e il
// mezzo resta fuori dalla lista invece di riempirla di voci inutili
private _tur = ((count (allTurrets _veh)) > 0) && {!((weapons _veh) isEqualTo [])};

// ---- scelta, secondo l'ambiente ----------------------------------
private _modo = "";

if !(_pos isEqualTo "") then {
    _modo = "MEM";
} else {
    if (_aria) then {
        /*
            Su un elicottero la postazione artigliere vince sul pod.

            Il pod e' la vista del pilota; il FLIR e l'ottica vera stanno al
            posto artigliere, ed e' quella che si vuole vedere. Vale solo se
            qualcuno ci siede davvero: a torretta vuota non c'e' niente da
            seguire e si torna al pod.
        */
        /*
            Solo l'artigliere vero, non una panca qualsiasi.

            Le sedute laterali e i posti di tiro contano come torrette, e
            sedendocisi il mezzo risultava presidiato: si sceglieva quella
            postazione e si finiva a inquadrare il sotto del velivolo. Vale
            solo primaryGunner, altrimenti si torna alla vista del pilota.
        */
        private _presidiata = false;
        {
            private _u = _veh turretUnit _x;
            if (!isNull _u && {alive _u}
                && {!((_veh weaponsTurret _x) isEqualTo [])}
                && {(getNumber (([_veh, _x] call BIS_fnc_turretConfig) >> "primaryGunner")) isEqualTo 1}
            ) exitWith {
                _presidiata = true;
            };
        } forEach (allTurrets _veh);

        _modo = if (_tur && {_presidiata}) then { "TURRET" } else {
            if (_pod) then { "PILOTCAM" } else {
                if (_tur) then { "TURRET" } else { "NOSE" }
            }
        };
    } else {
        _modo = if (_tur) then { "TURRET" } else {
            if (_pod) then { "PILOTCAM" } else { "" }
        };
    };
};

/*
    In modo torretta serve anche DA DOVE guardare. Senza un punto si ricade su
    uno scostamento fisso sopra il centro modello: su un elicottero e' il
    rotore, e si finisce a inquadrare le pale. Il punto giusto e' l'ottica del
    cannoniere dichiarata nella torretta.
*/
if (_modo isEqualTo "TURRET" && {_pos isEqualTo ""}) then {
    {
        private _tc = [_veh, _x] call BIS_fnc_turretConfig;
        if (isClass _tc) then {
            {
                private _mp = getText (_tc >> _x);
                if (_mp != "" && {!((_veh selectionPosition _mp) isEqualTo [0,0,0])}) exitWith {
                    _pos = _mp;
                };
            } forEach ["memoryPointGunnerOptics", "memoryPointGunnerOutOptics"];
        };
        if !(_pos isEqualTo "") exitWith {};
    } forEach (allTurrets _veh);

    if (_pos isEqualTo "") then {
        {
            if (!((_veh selectionPosition _x) isEqualTo [0,0,0])) exitWith {_pos = _x};
        } forEach ["pip0_pos", "PiP0_pos", "gunnerview", "commanderview"];
    };
};

[_pos, _dir, _modo]
