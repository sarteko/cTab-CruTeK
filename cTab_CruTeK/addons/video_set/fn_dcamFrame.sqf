/*
    crutek_fnc_dcamFrame
    Ogni frame: puntamento della camera, modo effettivo, zoom dell'operatore,
    manutenzione dei controlli sullo schermo del telefono.
*/

if (!crutek_dcam_active) exitWith {};

private _uav = crutek_dcam_uav;
private _cam = crutek_dcam_cam;

// ---- tolleranza prima di mollare il collegamento ------------------
private _bad = (isNull _uav)
    || {!alive _uav}
    || {isNull _cam}
    || {!alive player}
    || {!([player] call crutek_fnc_dcamHasItem)};

private _drop = false;
if (_bad) then {
    if (crutek_dcam_graceT < 0) then { crutek_dcam_graceT = diag_tickTime };
    _drop = (diag_tickTime - crutek_dcam_graceT) > crutek_dcam_grace;
} else {
    crutek_dcam_graceT = -1;
};

if (_drop) exitWith { call crutek_fnc_dcamClose };
if (_bad) exitWith {};

/*
    Sulle telecamere da casco non c'e niente da fare qui: la camera e appesa
    alla testa e guarda una sfera agganciata davanti, quindi segue lo sguardo
    da sola. Puntamento, specchio dei filtri e zoom valgono solo per i droni.
*/
if (crutek_dcam_kind isEqualTo "HCAM") then {
    call crutek_fnc_dcamRefresh;
} else {
    // ---- puntamento con stabilizzazione ------------------------------
    /*
        Il comando grezzo si prende dai memory point della torretta e si porta in
        coordinate MONDO: il tremolio nasce dal telaio del drone, e in coordinate
        modello il telaio e fermo per definizione, quindi li non si vedrebbe.

        Il filtro non e un semplice passa-basso. Un passa-basso, davanti a un
        ingresso che cambia a velocita costante (e mentre il drone vola la
        direzione verso il bersaglio fa proprio cosi), accumula un ritardo fisso
        che a schermo diventa errore di mira: era il difetto del primo tentativo.
        Qui si stima anche la velocita del movimento e la si compensa in avanti,
        quindi su un brandeggio regolare l'errore a regime e zero mentre le
        scosse casuali restano smorzate.

        La costante di tempo cresce con l'ingrandimento: a 50x la stessa scossa
        si vede cinquanta volte tanto.
    */
    /*
        Il puntamento grezzo arriva da due sorgenti diverse:
    
        MEM       differenza fra due memory point, gia in coordinate modello
        PILOTCAM  getPilotCameraDirection, che e in coordinate MONDO e va
                  riportata in modello, visto che la camera e agganciata al mezzo

        Le conversioni seguono crutek_dcam_aimVisual.

        Il motore tiene due stati del mezzo: quello simulato, che avanza a
        passi fissi, e quello VISUALE, interpolato, che e quello che finisce
        davvero a schermo. Convertendo con l'orientamento simulato mentre la
        camera viene disegnata con quello visuale, fra i due resta uno scarto
        di frazioni di grado: invisibile a inquadratura larga, ma a 2 gradi di
        campo visivo diventa il tremolio che si vede al massimo
        dell'ingrandimento. Con le varianti Visual i due stati sono lo stesso.
    */
    private _tgtModel = switch (crutek_dcam_aim) do {
        case "PILOTCAM": {
            /*
                getPilotCameraDirection restituisce gia' coordinate MODELLO, come
                getPilotCameraPosition che in dcamOpen si usa tal quale. Passarla
                per vectorWorldToModel la ruotava della prua del mezzo: sull'A-10
                si vedeva dietro, sull'F/A-181 di traverso, e cambiava a seconda
                di come era parcheggiato.
            */
            private _pd = getPilotCameraDirection _uav;
            if (!(_pd isEqualType []) || {(count _pd) != 3} || {(vectorMagnitude _pd) < 0.001}) then {
                _pd = [0, 1, 0];
            };
            _pd
        };
        // dove punta l'arma della torretta, in mondo, riportata in modello
        case "TURRET": {
            /*
                PUNTAMENTO DELLA POSTAZIONE.

                Prima le sorgenti di animazione, se la torretta le dichiara:
                azimut dal body, elevazione dal gun, gia relativi al mezzo e
                quindi gia in coordinate modello. Positivo sul body gira a
                SINISTRA e positivo sul gun ALZA, che e la convenzione di
                animateSource: da li i segni qui sotto.

                Serve perche su parecchi mezzi di mod la palla sensore ruota
                per animazione mentre le volate delle armi restano ferme alla
                fusoliera. In quel caso weaponDirection da un'immagine
                immobile per quanto si brandeggi.

                Le sorgenti vengono riempite solo con un profilo di
                compatibilita acceso, quindi qui i mezzi di serie cadono
                sempre nel ramo di sotto, come hanno sempre fatto.
            */
            private _ab = crutek_dcam_animBody;

            if !(_ab isEqualTo "") then {
                private _az = deg (_uav animationSourcePhase _ab);
                private _el = if (crutek_dcam_animGun isEqualTo "") then {
                    0
                } else {
                    deg (_uav animationSourcePhase crutek_dcam_animGun)
                };
                private _cs = cos _el;
                [-((sin _az) * _cs), (cos _az) * _cs, sin _el]
            } else {
                /*
                    L'arma va presa dalla torretta SCELTA. weapons del mezzo le
                    impasta tutte insieme: su un cannoniere con tre bocche da
                    fuoco si pescava la prima dell'elenco, che non e per forza
                    quella della postazione che si sta guardando.
                */
                private _tp = crutek_dcam_turret;
                private _w  = if (_tp isEqualTo []) then {
                    (weapons _uav) param [0, ""]
                } else {
                    private _cur = _uav currentWeaponTurret _tp;
                    if (_cur isEqualTo "") then { (_uav weaponsTurret _tp) param [0, ""] } else { _cur }
                };

                if (_w isEqualTo "") then {
                    [0, 1, 0]
                } else {
                    if (crutek_dcam_aimVisual) then {
                        _uav vectorWorldToModelVisual (_uav weaponDirection _w)
                    } else {
                        _uav vectorWorldToModel (_uav weaponDirection _w)
                    };
                };
            };
        };
        // in coordinate modello +Y e il davanti: camera fissa sul muso
        case "NOSE":     { [0, 1, 0] };
        default {
            (_uav selectionPosition crutek_dcam_posMem) vectorFromTo (_uav selectionPosition crutek_dcam_dirMem)
        };
    };
    private _dir = _tgtModel;

    if (crutek_dcam_smooth > 0) then {
        private _t  = if (crutek_dcam_aimVisual) then {
            _uav vectorModelToWorldVisual _tgtModel
        } else {
            _uav vectorModelToWorld _tgtModel
        };
        private _s  = crutek_dcam_lastDir;
        private _v  = crutek_dcam_lastRate;
        private _dt = (diag_deltaTime) max 1e-4;

        if ((count _s) < 3) then { _s = _t; _v = [0, 0, 0]; };

        // scarto grosso: la torretta ha saltato, ci si aggancia secco
        if ((_s vectorDotProduct _t) < 0.9) then {
            _s = _t;
            _v = [0, 0, 0];
        } else {
            private _wide = if (crutek_dcam_ladder isEqualTo []) then { 0.75 } else { crutek_dcam_ladder select 0 };
            private _mag  = ((_wide / (crutek_dcam_fovApplied max 0.001)) * crutek_dcam_cropZoom) max 1;
            private _tau  = (crutek_dcam_smooth * ((_mag / 8) max 1)) min 1.2;

            private _al = (_dt / (_tau + _dt)) min 1;   // guadagno sulla posizione
            private _be = (_al * _al) / 2;              // guadagno sulla velocita

            private _pred = _s vectorAdd (_v vectorMultiply _dt);
            private _err  = _t vectorDiff _pred;

            _s = vectorNormalized (_pred vectorAdd (_err vectorMultiply _al));
            _v = _v vectorAdd (_err vectorMultiply (_be / _dt));
        };

        crutek_dcam_lastDir  = _s;
        crutek_dcam_lastRate = _v;

        _dir = if (crutek_dcam_aimVisual) then {
            _uav vectorWorldToModelVisual _s
        } else {
            _uav vectorWorldToModel _s
        };
    };

    /*
        Scarto di ricentratura, in coordinate modello: azimut misurato da +Y
        (avanti) verso +X (destra), elevazione da +Z (alto). Serve perche i
        memory point del modello non sempre coincidono con l'asse ottico.
    */

    // la camera e agganciata al drone, quindi dir e up vanno in coordinate modello
    _cam setVectorDirAndUp [
        _dir,
        _dir vectorCrossProduct [-(_dir select 1), _dir select 0, 0]
    ];

    // ---- chi comanda la torretta -------------------------------------
    // vale anche se l'operatore sei tu: il tuo stesso Galaxy si aggancia
    private _op = [_uav] call crutek_fnc_dcamOperator;
    crutek_dcam_hasOp = !isNull _op;

    call crutek_fnc_dcamRefresh;

    if (crutek_dcam_dragging) then { call crutek_fnc_dcamDrag };

    // ---- zoom --------------------------------------------------------
    // se c'e un operatore lo zoom e sempre il suo, qualunque sia il selettore
    (_uav getVariable ["crutek_dcam_view", []]) params ["", "", ["_opZoom", -1]];

    /*
        Dallo zoom dell'operatore si ricava la FOV per QUESTA superficie:
        0.75 e la FOV di riferimento a 1x su un 4:3, che e la forma del
        riquadro del feed. Cosi il rapporto di ingrandimento e lo stesso
        senza dipendere dallo schermo dell'operatore.
    */
    private _fov = if (crutek_dcam_hasOp && {_opZoom > 0}) then {
        crutek_dcam_fovBase / _opZoom
    } else {
        _uav getVariable ["crutek_dcam_fov", crutek_dcam_fov]
    };

    if (_fov > 0 && {abs (_fov - crutek_dcam_fov) > 0.0005}) then {
        crutek_dcam_fov = _fov;
        call crutek_fnc_dcamApplyFov;
    };
};

// ---- schermo del telefono a 10 Hz --------------------------------
/*
    Rete di sicurezza. La riaffermazione vera e agganciata agli stessi eventi
    di ACE, in dcamInit; questo controllo ogni due secondi copre i casi che
    quegli eventi non vedono, per esempio un cambio delle impostazioni ACE a
    partita in corso.
*/
if (crutek_dcam_prevVD > 0 && {diag_tickTime > crutek_dcam_vdTick}) then {
    crutek_dcam_vdTick = diag_tickTime + 2;
    call crutek_dcam_applyVD;
};

if (diag_tickTime > crutek_dcam_hudTick) then {
    crutek_dcam_hudTick = diag_tickTime + 0.1;
    ["ON"] call crutek_fnc_dcamOverlay;
    call crutek_fnc_dcamHud;
};
