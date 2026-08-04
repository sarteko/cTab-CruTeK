/*
    crutek_fnc_dcamList
    Tutti i mezzi collegabili, secondo le impostazioni della missione.

    I filtri non sono piu scritti qui: fazioni, equipaggio, distanza e quota
    vengono dalle opzioni degli addon (vedi dcamSettings), cosi ogni scenario
    puo avere la sua configurazione.

    Ritorna: ARRAY di OBJECT, ordinati per distanza
*/

/*
    Fazioni ammesse, DUE insiemi distinti: i droni hanno le loro, decise nella
    sezione dedicata. Cosi si puo per esempio guardare i droni civili senza
    per questo poter guardare le torrette dei mezzi civili con equipaggio.
*/
private _fnc_fazioni = {
    params ["_own", "_w", "_e", "_g", "_c"];
    private _out = [];
    if (_own) then { _out pushBackUnique (side group player) };
    if (_w)   then { _out pushBackUnique west };
    if (_e)   then { _out pushBackUnique east };
    if (_g)   then { _out pushBackUnique resistance };
    if (_c)   then { _out pushBackUnique civilian };
    _out
};

private _sides = [crutek_dcam_sideOwn, crutek_dcam_sideWest, crutek_dcam_sideEast,
                  crutek_dcam_sideGuer, crutek_dcam_sideCiv] call _fnc_fazioni;

private _sidesDr = [crutek_dcam_droneSideOwn, crutek_dcam_droneSideWest, crutek_dcam_droneSideEast,
                    crutek_dcam_droneSideGuer, crutek_dcam_droneSideCiv] call _fnc_fazioni;

/*
    ---- equipaggio -------------------------------------------------
    0 player o IA, 1 solo player, 2 solo IA, 3 anche vuoti.

    Il controllo sta in una funzione a parte e non dentro la catena di &&:
    scandendo l'equipaggio la variabile _x diventerebbe il membro e
    coprirebbe il mezzo, che e proprio quello che serve leggere. Sarebbe
    codice valido che filtra la cosa sbagliata in silenzio.
*/
private _fnc_equipaggio = {
    params ["_veh"];
    if (crutek_dcam_crewMode isEqualTo 3) exitWith { true };

    /*
        I DRONI VANNO GUARDATI DIVERSAMENTE.

        Su un mezzo con equipaggio la persona che conta sta dentro, e basta
        scandire crew. Su un drone no: l'equipaggio sono unita IA, e il
        giocatore che lo comanda sta al terminale, fuori dal mezzo. Scandendo
        crew nessun membro risulterebbe mai un player, e con il filtro su
        "solo player" un drone sparirebbe dalla lista anche mentre lo stai
        pilotando tu.

        Qui quindi si guarda chi e COLLEGATO: se c'e un giocatore alla
        torretta il drone conta come guidato da player, altrimenti da IA.
    */
    if (_veh in allUnitsUAV) exitWith {
        private _conPlayer = !isNull ([_veh] call crutek_fnc_dcamOperator);
        switch (crutek_dcam_droneWho) do {
            case 1: { _conPlayer };
            case 2: { !_conPlayer };
            default { true };
        };
    };

    /*
        SOLO LE POSTAZIONI DI TIRO, SUI MEZZI DI TERRA E DI MARE.

        Con l'interruttore acceso non basta che a bordo ci sia qualcuno: deve
        esserci qualcuno seduto in una torretta. Un mezzo col solo autista
        entrava in lista, ma la torretta resta dove l'hanno lasciata e ci si
        collegava a un'immagine immobile.

        allTurrets esclude gia autista e passeggeri, ed e per questo che si
        scandisce quello invece di crew. I mezzi che volano non sono toccati:
        li la sorgente e spesso il pod, che col cannoniere non c'entra.
    */
    private _lista = crew _veh;

    if (crutek_dcam_gunnerOnly && {!(_veh isKindOf "Air")}) then {
        _lista = [];
        {
            private _u = _veh turretUnit _x;
            if (!isNull _u) then { _lista pushBackUnique _u };
        } forEach (allTurrets _veh);
    };

    private _ok = false;
    {
        if (alive _x && {(side group _x) in _sides}) then {
            private _isPlayer = isPlayer _x;
            if (
                (crutek_dcam_crewMode isEqualTo 0)
                || {(crutek_dcam_crewMode isEqualTo 1) && _isPlayer}
                || {(crutek_dcam_crewMode isEqualTo 2) && !_isPlayer}
            ) exitWith { _ok = true };
        };
    } forEach _lista;

    _ok
};

/*
    L'insieme di partenza NON e solo vehicles: i mezzi telecomandati non
    sempre ci compaiono. allUnitsUAV li elenca per definizione.
*/
private _pool = vehicles + allUnitsUAV;
_pool = _pool arrayIntersect _pool;

// la distanza a 0 significa nessun limite, non zero metri
private _lim = crutek_dcam_maxDist;
if (_lim <= 0) then { _lim = 1e10 };

private _limDr = crutek_dcam_droneMaxDist;
if (_limDr <= 0) then { _limDr = 1e10 };

private _uav = allUnitsUAV;

/*
    Droni e mezzi con equipaggio passano da regole diverse: fazioni, distanza
    massima e interruttore generale vengono da due sezioni distinte delle
    opzioni. La quota minima resta comune, perche riguarda l'essere in volo e
    vale per chiunque voli.
*/
private _list = _pool select {
    private _v  = _x;
    private _dr = _v in _uav;

    alive _v
    && {!(_v getVariable ["crutek_dcam_blocked", false])}
    && {!_dr || {crutek_dcam_droneOn}}
    && {(player distance _v) <= (if (_dr) then { _limDr } else { _lim })}
    && {!(_v isKindOf "Air") || {((getPosATL _v) select 2) >= crutek_dcam_minAlt}}
    && {([_v] call crutek_fnc_dcamSide) in (if (_dr) then { _sidesDr } else { _sides })}
    && {[_v] call _fnc_equipaggio}
    && {(([_v] call crutek_fnc_dcamTurret) select 2) != ""}
};

// ordinamento per distanza: lista corta, l'inserimento basta e avanza
private _out = [];
{
    private _v   = _x;
    private _d   = player distance _v;
    private _idx = _out findIf { (player distance _x) > _d };
    if (_idx < 0) then { _out pushBack _v } else { _out insert [_idx, [_v]] };
} forEach _list;

_out
