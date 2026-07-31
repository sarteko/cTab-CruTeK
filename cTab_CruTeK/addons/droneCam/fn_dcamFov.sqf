/*
    crutek_fnc_dcamFov
    Costruisce la scaletta di zoom del feed.

    GLI SCATTI SONO QUELLI VERI DELL'OTTICA.

    In Arma un pod di puntamento non ha uno zoom continuo: ha un elenco di
    ottiche, una per ingrandimento, ognuna con il suo campo visivo. Il pod
    che si monta sull'UH-80 e fatto cosi:

        pilotCamera >> OpticsIn >> Wide     initFov = 30/120 = 0.25
                                >> Medium   initFov =  6/120 = 0.05
                                >> Narrow   initFov =  2/120 = 0.0167

    Quelli sono i tre scatti che ha chi sta al pod, e sono esattamente i tre
    che deve avere il feed. Prima invece si leggevano opticsZoomMin e
    opticsZoomMax, che sono gli estremi della corsa, e fra i due si spalmava
    una scaletta a tot passi: numeri plausibili ma che non corrispondevano a
    nessuna posizione reale dell'ottica.

    Si guarda in due posti, perche i mezzi non sono tutti uguali:
      pilotCamera >> OpticsIn      pod di aerei ed elicotteri, e i droni che
                                   puntano col muso
      Turrets >> ... >> OpticsIn   ottiche del posto artigliere

    Se il mezzo non dichiara ottiche discrete si torna al vecchio metodo, che
    resta l'unica strada per chi ha davvero uno zoom continuo.

    0: OBJECT - il mezzo
    Ritorna: ARRAY - campi visivi dal piu largo al piu stretto
*/

params [["_uav", objNull]];

private _passi = [];

// ---- scatti dichiarati da un elenco di ottiche --------------------
private _fnc_discreti = {
    params ["_opticsIn"];
    private _out = [];
    if !(isClass _opticsIn) exitWith { _out };
    {
        /*
            initFov e il valore con cui l'ottica si presenta. Alcune classi lo
            lasciano a zero e dichiarano solo la coppia min/max: in quel caso
            si prende il piu largo dei due, che e la posizione di riposo.
        */
        private _f = getNumber (_x >> "initFov");
        if (_f <= 0) then { _f = getNumber (_x >> "maxFov") };
        if (_f <= 0) then { _f = getNumber (_x >> "minFov") };
        if (_f > 0 && {_f <= 1.5}) then { _out pushBack _f };
    } forEach (configProperties [_opticsIn, "isClass _x", true]);
    _out
};

if (!isNull _uav) then {
    private _root = configFile >> "CfgVehicles" >> typeOf _uav;

    /*
        L'ordine conta: se il mezzo si punta col pod, gli scatti buoni sono
        quelli del pod. Le ottiche delle torrette si guardano dopo, e solo se
        il pod non ha detto niente.
    */
    if (crutek_dcam_aim isEqualTo "PILOTCAM") then {
        _passi = [_root >> "pilotCamera" >> "OpticsIn"] call _fnc_discreti;
    };

    if (_passi isEqualTo []) then {
        {
            _passi append ([_x >> "OpticsIn"] call _fnc_discreti);
        } forEach (
            if (isClass (_root >> "Turrets")) then {
                configProperties [_root >> "Turrets", "isClass _x", true]
            } else { [] }
        );
    };

    if (_passi isEqualTo []) then {
        _passi = [_root >> "pilotCamera" >> "OpticsIn"] call _fnc_discreti;
    };
};

// ---- ripulitura: doppioni via, dal piu largo al piu stretto -------
if !(_passi isEqualTo []) then {
    _passi sort false;
    private _puliti = [];
    {
        private _v = _x;
        if ((_puliti findIf { abs (_x - _v) < 0.0005 }) < 0) then { _puliti pushBack _v };
    } forEach _passi;
    _passi = _puliti;
};

if ((count _passi) >= 2) exitWith {
    diag_log format [
        "[crutek_dcam] scaletta zoom di %1: %2 scatti reali %3",
        typeOf _uav, count _passi, _passi
    ];
    _passi
};

/*
    ---- ripiego: zoom continuo --------------------------------------

    Nessuna ottica discreta dichiarata. Si prende la corsa dello zoom e si
    spalma una scaletta a passo costante, che e quello che si faceva prima
    per tutti i mezzi.
*/
private _min   = 0.0;
private _max   = 0.0;
private _found = false;

private _fnc_take = {
    params ["_a", "_b"];
    if (_a <= 0 || {_b <= 0}) exitWith {};
    private _lo = _a min _b;
    private _hi = _a max _b;
    if (!_found) then {
        _min = _lo;
        _max = _hi;
        _found = true;
    } else {
        _min = _min min _lo;
        _max = _max max _hi;
    };
};

if (!isNull _uav) then {
    private _root = configFile >> "CfgVehicles" >> typeOf _uav;

    {
        private _optics = _x >> "OpticsIn";
        if (isClass _optics) then {
            {
                [getNumber (_x >> "opticsZoomMin"), getNumber (_x >> "opticsZoomMax")] call _fnc_take;
            } forEach (configProperties [_optics, "isClass _x", true]);
        };
    } forEach (
        if (isClass (_root >> "Turrets")) then {
            configProperties [_root >> "Turrets", "isClass _x", true]
        } else { [] }
    );

    if (!_found) then {
        private _pc = _root >> "pilotCamera";
        if (isClass _pc) then {
            [getNumber (_pc >> "minFov"), getNumber (_pc >> "maxFov")] call _fnc_take;
        };
    };
};

if (!_found) then {
    _min = 0.035;
    _max = 0.70;
};

// clamp di sicurezza: sotto 0.01 il rendering fa i capricci
_min = _min max 0.012;
_max = _max min 1.20;
if (_max <= _min) then { _max = _min * 4 };

private _steps  = (crutek_dcam_zoomSteps max 2);
private _ladder = [];
private _ratio  = _min / _max;

for "_i" from 0 to (_steps - 1) do {
    _ladder pushBack (_max * (_ratio ^ (_i / (_steps - 1))));
};

diag_log format [
    "[crutek_dcam] scaletta zoom di %1: nessuna ottica discreta, %2 passi fra %3 e %4",
    typeOf _uav, _steps, _max, _min
];

_ladder
