/*
    crutek_fnc_dcamCompTurret
    Dichiara come va trattato ogni mezzo del mod USAF.

    LA TABELLA E LA CONFIGURAZIONE DEL MOD.

    Ogni riga dice: prefisso del nome classe, postazioni ammesse sul Galaxy,
    e se il pod del pilota vale come sorgente. Tutti i mezzi USAF stanno qui,
    anche quelli che di torrette non ne hanno: cosi la scelta e scritta e non
    dedotta, e si legge in un posto solo.

        USAF_AC130   IR, TV ed Electronic Warfare. Fuori la FCO, il pod del
                     pilota, copilota, motorista e navigatore.
        USAF_A10     monoposto, nessuna torretta: la sorgente e il pod TGP.
        USAF_F35     stessa cosa, sorgente il pod.
        USAF_MQ9     drone: dichiara la coppia uavCameraGunner, che e la
                     strada giusta e segue gia la palla sensore.
        USAF_RQ4A    idem.

    La terza colonna dice da dove guardare quando non c'e una postazione
    ammessa da usare: "POD" il pod del pilota, "MEM" i memory point camera del
    mezzo, stringa vuota nessun ripiego e mezzo fuori dalla lista.

    Un mezzo che compare in tabella e non ha nessuna sorgente utilizzabile
    viene BLOCCATO, non ripiega sulle regole generiche: altrimenti
    sull'AC-130U tornerebbe a spuntare il pod del pilota, che e proprio quello
    che non si vuole. Un mezzo USAF non ancora in tabella invece non viene
    toccato e passa dalle regole di sempre.

    QUALE POSTAZIONE, FRA QUELLE AMMESSE.
    Vince quella dove sei seduto tu: stai brandeggiando quel sensore ed e
    quello che ti aspetti di vedere. Altrimenti la prima ammessa con qualcuno
    dentro, e in ultimo la prima ammessa e basta.

    0: OBJECT - il mezzo
    Ritorna: ARRAY - [esito, percorso torretta, punto ottica]
        "OK"    postazione trovata
        "POD"   sorgente dichiarata: il pod del pilota
        "MEM"   sorgente dichiarata: i memory point camera del mezzo
        "BLOCK" mezzo in tabella ma nessuna sorgente utilizzabile
        "NONE"  mezzo non in tabella, valgono le regole generiche
*/

params [["_veh", objNull]];
if (isNull _veh) exitWith { ["NONE", "", ""] };

private _tabella = [
    ["USAF_AC130", ["IRTurret", "TVTurret", "EWOTurret"], ""],
    ["USAF_A10",   [],                                    "POD"],
    ["USAF_F35",   [],                                    "POD"],
    ["USAF_MQ9",   [],                                    "MEM"],
    ["USAF_RQ4A",  [],                                    "MEM"]
];

private _tipo = toUpper (typeOf _veh);
private _ammesse = [];
private _inTabella = false;

private _ripiego = "";

{
    _x params ["_pref", "_lista", "_sorg"];
    if ((_tipo find (toUpper _pref)) isEqualTo 0) exitWith {
        _ammesse   = _lista apply { toUpper _x };
        _ripiego   = _sorg;
        _inTabella = true;
    };
} forEach _tabella;

if (!_inTabella) exitWith { ["NONE", "", ""] };

// mezzo dichiarato senza postazioni: si va diritti alla sorgente di ripiego
if (_ammesse isEqualTo []) exitWith {
    if (_ripiego isEqualTo "") then { ["BLOCK", "", ""] } else { [_ripiego, "", ""] }
};

/*
    Il punto ottica va verificato sul modello, non solo letto dal config: un
    nome dichiarato ma assente dal p3d restituisce l'origine, e la camera
    finirebbe dentro la fusoliera.
*/
private _fnc_ottica = {
    params ["_path"];
    private _tc = [_veh, _path] call BIS_fnc_turretConfig;
    private _mp = "";
    if (isClass _tc) then {
        {
            private _p = getText (_tc >> _x);
            if (_p != "" && {!((_veh selectionPosition _p) isEqualTo [0,0,0])}) exitWith { _mp = _p };
        } forEach ["memoryPointGunnerOptics", "memoryPointGunnerOutOptics"];
    };
    _mp
};

private _mia    = [];
private _abitata = [];
private _prima  = [];

{
    private _path = _x;
    private _tc   = [_veh, _path] call BIS_fnc_turretConfig;
    private _nome = toUpper (configName _tc);

    if (_nome in _ammesse) then {
        private _mp = [_path] call _fnc_ottica;

        if !(_mp isEqualTo "") then {
            private _u = _veh turretUnit _path;

            if (_prima isEqualTo []) then { _prima = [_path, _mp] };
            if (_abitata isEqualTo [] && {!isNull _u} && {alive _u}) then { _abitata = [_path, _mp] };
            if (_mia isEqualTo [] && {_u isEqualTo player}) then { _mia = [_path, _mp] };
        };
    };
} forEach (allTurrets _veh);

private _scelta = _mia;
if (_scelta isEqualTo []) then { _scelta = _abitata };
if (_scelta isEqualTo []) then { _scelta = _prima };

if (_scelta isEqualTo []) exitWith {
    if (_ripiego isEqualTo "") then { ["BLOCK", "", ""] } else { [_ripiego, "", ""] }
};

_scelta params ["_path", "_mp"];
["OK", _path, _mp]
