/*
    crutek_fnc_dcamOpen
    Accende un feed sullo schermo del Galaxy.

    0: OBJECT - drone oppure unita con telecamera da casco
    1: STRING - "DRONE" (default) oppure "HCAM"
    2: ARRAY  - percorso torretta scelto dal menu, [] per lasciar decidere
    Ritorna: BOOL
*/

params [["_subject", objNull], ["_kind", "VEH"], ["_scelta", []]];

if (crutek_dcam_active) then { call crutek_fnc_dcamClose };

/*
    Dal menu arriva un tag generico per qualunque mezzo. La distinzione si
    ricava qui dall'oggetto, e serve a una cosa sola: sui droni la torretta si
    puo brandeggiare col tasto destro, sui mezzi con equipaggio la comanda chi
    ci sta seduto dentro.
*/
if (_kind isEqualTo "VEH") then {
    // allUnitsUAV e piu affidabile di isKindOf "UAV": vedi dcamInit
    _kind = if (_subject in allUnitsUAV) then { "DRONE" } else { "PLANE" };
};

if (!isPiPEnabled) exitWith {
    ["DroneCam", localize "STR_crutek_dcam_not_pipOff"] call crutek_fnc_dcamNotify;
    false
};

if (isNull _subject || {!alive _subject}) exitWith {
    ["DroneCam", localize "STR_crutek_dcam_not_gone"] call crutek_fnc_dcamNotify;
    false
};

if !([player] call crutek_fnc_dcamHasItem) exitWith {
    ["DroneCam", localize "STR_crutek_dcam_not_needItem"] call crutek_fnc_dcamNotify;
    false
};

// i memory point servono solo ai droni, ma vanno verificati prima di
// impegnare lo stato: un exitWith dentro un ramo then uscirebbe solo dal ramo
private _posMem = "";
private _dirMem = "";
private _aim    = "";
crutek_dcam_turret   = [];
crutek_dcam_animBody  = "";
crutek_dcam_animGun   = "";
crutek_dcam_armi      = [];
if !(_kind isEqualTo "HCAM") then {
    ([_subject, _scelta] call crutek_fnc_dcamTurret) params ["_p", "_d", "_a", ["_t", []]];
    crutek_dcam_turret = _t;

    /*
        Sorgenti di animazione della postazione scelta, lette una volta sola
        qui e non a ogni fotogramma. Servono a puntare la camera: su parecchi
        mezzi di mod la palla sensore ruota per animazione mentre le volate
        delle armi restano ferme alla fusoliera, e weaponDirection darebbe
        un'immagine immobile. Si leggono solo con un profilo di compatibilita
        acceso, cosi i mezzi di serie non cambiano comportamento.
    */
    if !(_t isEqualTo []) then {
        private _tc = [_subject, _t] call BIS_fnc_turretConfig;
        if (isClass _tc) then {
            crutek_dcam_animBody = getText (_tc >> "animationSourceBody");
            crutek_dcam_animGun  = getText (_tc >> "animationSourceGun");
        };

    };

    /*
        ARMI CHE POSSONO FARE DA RIFERIMENTO DI PUNTAMENTO.

        Non tutto quello che sta in weapons serve a capire dove guarda una
        postazione. Il lanciafumogeni e imbullonato allo scafo e non si muove
        di un grado: sul posto comandante di un mezzo antiaereo e l'unica arma
        dichiarata, e la sua sola presenza bastava a far vincere il ramo
        dell'arma, lasciando l'immagine inchiodata mentre il sensore girava.

        NON basta chiedere se fa danno: lo SmokeShell di ARMA eredita i valori
        della granata, quindi un lanciafumogeni supera un controllo sul danno
        e si riprende il posto che non gli spetta. Il discriminante buono e il
        TIPO di proiettile, la simulation del CfgAmmo, piu l'esclusione per
        classe dei due casi noti. Fuori restano fumogeni, contromisure,
        illuminanti, designatori e clacson.

        Se dopo il filtro non resta niente si punta con le sorgenti di
        animazione, che e esattamente quello che serve a una postazione di
        sola osservazione.

        Il filtro gira una volta all'accensione, non a ogni fotogramma.
    */
    private _cfgW = configFile >> "CfgWeapons";
    private _cfgM = configFile >> "CfgMagazines";
    private _cfgA = configFile >> "CfgAmmo";

    private _scarti = ["shotsmoke", "shotilluminating", "shotcm", "shotlaser"];

    private _grezze = if (_t isEqualTo []) then { weapons _subject } else { _subject weaponsTurret _t };
    private _buone  = [];

    {
        private _arma = _x;
        private _ok   = false;

        if (
            !(_arma isKindOf ["SmokeLauncher", _cfgW])
            && {!(_arma isKindOf ["CMFlareLauncher", _cfgW])}
        ) then {
            {
                private _ammo = getText (_cfgM >> _x >> "ammo");
                if (_ammo != "") then {
                    private _sim = toLower (getText (_cfgA >> _ammo >> "simulation"));
                    if (!(_sim isEqualTo "") && {!(_sim in _scarti)}) exitWith { _ok = true };
                };
            } forEach (getArray (_cfgW >> _arma >> "magazines"));
        };

        if (_ok) then { _buone pushBack _arma };
    } forEach _grezze;

    crutek_dcam_armi = _buone;
    _posMem = _p;
    _dirMem = _d;
    _aim    = _a;
};

if (!(_kind isEqualTo "HCAM") && {_aim isEqualTo ""}) exitWith {
    ["DroneCam", localize "STR_crutek_dcam_not_noTurret"] call crutek_fnc_dcamNotify;
    false
};

crutek_dcam_kind      = _kind;
crutek_dcam_uav       = _subject;
crutek_dcam_posMem    = _posMem;
crutek_dcam_dirMem    = _dirMem;
crutek_dcam_aim       = _aim;
crutek_dcam_mode      = 0;
crutek_dcam_effective = "";
crutek_dcam_hasOp     = false;
crutek_dcam_hidden    = false;
crutek_dcam_graceT    = -1;
crutek_dcam_cropZoom  = 1;
crutek_dcam_dragging  = false;
crutek_dcam_mods      = [false, false, false];
crutek_dcam_locked    = false;
crutek_dcam_lastDir   = [];
crutek_dcam_lastRate  = [0, 0, 0];

private _cam = objNull;

if (_kind isEqualTo "HCAM") then {
    /*
        Telecamera da casco: stessa costruzione del tablet di cTab. La camera
        si aggancia al memory point della testa e guarda una sfera nascosta
        appesa otto metri davanti, quindi segue lo sguardo da sola senza
        bisogno di aggiornarla a ogni frame.
    */
    crutek_dcam_ladder = [crutek_dcam_hcamFov];
    crutek_dcam_fov    = crutek_dcam_hcamFov;

    private _tgt = "Sign_Sphere10cm_F" createVehicleLocal (position player);
    hideObject _tgt;
    _tgt attachTo [_subject, [0, 8, 1]];
    crutek_dcam_hcamTgt = _tgt;

    _cam = "camera" camCreate (getPosATL _subject);
    _cam camPrepareFov crutek_dcam_hcamFov;
    _cam camPrepareTarget _tgt;
    _cam camCommitPrepared 0;

    if ((vehicle _subject) isEqualTo _subject) then {
        _cam attachTo [_subject, [0.12, 0, 0.15], "Head"];
    } else {
        _cam attachTo [_subject, [0.12, 0, 0.15]];
    };

    _cam cameraEffect ["INTERNAL", "BACK", crutek_dcam_rt];
} else {
    crutek_dcam_ladder = [_subject] call crutek_fnc_dcamFov;

    private _shared = _subject getVariable ["crutek_dcam_fov", -1];
    crutek_dcam_fov = if (_shared > 0) then {
        _shared
    } else {
        crutek_dcam_ladder select (floor ((count crutek_dcam_ladder) / 2))
    };

    _cam = "camera" camCreate (getPosATL _subject);

    /*
        Col pod di puntamento non ci sono memory point da agganciare: la sua
        posizione si legge a runtime ed e gia in coordinate modello, quindi si
        usa direttamente come scostamento.
    */
    if (_aim isEqualTo "PILOTCAM") then {
        private _off = getPilotCameraPosition _subject;
        if (!(_off isEqualType []) || {(count _off) != 3}) then { _off = [0, 0, 0] };
        _cam attachTo [_subject, _off];
    } else {
    if (_aim isEqualTo "NOSE") then {
        // un po' avanti e sotto il baricentro, per non inquadrare il proprio muso
        _cam attachTo [_subject, [0, 3, -0.5]];
    } else {
    if (_aim isEqualTo "TURRET" && {_posMem isEqualTo ""}) then {
        // ripiego: sopra lo scafo, se la config non dichiara un punto ottica
        _cam attachTo [_subject, [0, 0, 1.5]];
    } else {
        _cam attachTo [_subject, [0, 0, 0], _posMem];
    };
    };
    };
    _cam cameraEffect ["INTERNAL", "BACK", crutek_dcam_rt];
    _cam camSetFov (crutek_dcam_fov * crutek_dcam_fovScale);
    _cam camCommit 0;
};

crutek_dcam_cam    = _cam;
/*
    Distanza visiva: si alza solo se l'impostazione lo chiede e solo se la tua
    e piu bassa. Il valore di partenza si salva per rimetterlo alla chiusura,
    -1 vuol dire che non l'abbiamo toccata.
*/
crutek_dcam_prevVD  = -1;
crutek_dcam_prevOVD = -1;
// Distanza di visuale: un valore per categoria, 0 vuol dire non toccare niente.
private _vd = if (_kind isEqualTo "HCAM") then {
    missionNamespace getVariable ["crutek_dcam_hcViewDist", 0]
} else {
    // un drone ha il suo valore, che vince su quello della categoria
    private _v = 0;
    if (_subject in allUnitsUAV) then {
        _v = missionNamespace getVariable ["crutek_dcam_vdDrone", 0];
    };
    if (_v <= 0) then {
        private _cat = switch (true) do {
            case (_subject isKindOf "Air"):  {"crutek_dcam_vdAir"};
            case (_subject isKindOf "Ship"): {"crutek_dcam_vdSea"};
            default {"crutek_dcam_vdLand"};
        };
        _v = missionNamespace getVariable [_cat, 0];
    };
    _v
};
crutek_dcam_vdAttiva = _vd;

if (_vd > 0) then {
    private _tetto = missionNamespace getVariable ["ace_viewdistance_limitViewDistance", 12000];
    private _vuole = _vd min _tetto;
    if (viewDistance < _vuole) then {
        crutek_dcam_prevVD  = viewDistance;
        crutek_dcam_prevOVD = (getObjectViewDistance select 0);

        // si conserva il rapporto fra oggetti e terreno che c'era prima
        crutek_dcam_ovdRatio = ((crutek_dcam_prevOVD / (crutek_dcam_prevVD max 1)) min 1) max 0;

        call crutek_dcam_applyVD;
    };
};

crutek_dcam_active = true;

// ricontrollo del flag anche lato osservatore, stessa ragione del publisher
crutek_dcam_hasA3TI = !isNil "A3TI_fnc_getA3TIVision";

diag_log format [
    "[crutek_dcam] apertura %1 | A3TI rilevata %2 | setObjects %3 | secondSun %4 | modalita %5",
    typeOf _subject,
    crutek_dcam_hasA3TI,
    !isNil "A3TI_fnc_setObjects",
    !isNil "A3TI_fnc_createSecondSun",
    crutek_dcam_a3ti
];

// mi segnalo come osservatore: serve al publisher dell'operatore
player setVariable ["crutek_dcam_watching", _subject, true];

call crutek_fnc_dcamRefresh;

["crutek_dcam", "onEachFrame", { call crutek_fnc_dcamFrame }] call BIS_fnc_addStackedEventHandler;

private _d46 = findDisplay 46;
crutek_dcam_ehKey   = _d46 displayAddEventHandler ["KeyDown",         { [_this, true]  call crutek_fnc_dcamInput }];
crutek_dcam_ehKeyUp = _d46 displayAddEventHandler ["KeyUp",           { [_this, false] call crutek_fnc_dcamInput }];
crutek_dcam_ehClick = _d46 displayAddEventHandler ["MouseButtonDown", { [_this, "down"] call crutek_fnc_dcamClick }];
crutek_dcam_ehUp    = _d46 displayAddEventHandler ["MouseButtonUp",   { [_this, "up"]   call crutek_fnc_dcamClick }];
/*
    La rotella serve anche col telefonino sempre a schermo, dove non c'e
    nessun dialogo che possa raccogliere l'evento: qui si aggancia al display
    di gioco. Quando invece il telefono e aperto, l'evento lo prende il
    dialogo, e dcamWheel scarta la chiamata doppia se dovessero arrivare
    tutte e due.
*/
crutek_dcam_ehWheel = _d46 displayAddEventHandler ["MouseZChanged",   { [_this select 1] call crutek_fnc_dcamWheel }];

["DroneCam", format ["Collegato a %1", [_subject] call crutek_fnc_dcamName]] call crutek_fnc_dcamNotify;

true
