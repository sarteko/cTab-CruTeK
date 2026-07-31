/*
    crutek_fnc_dcamDiag
    Dice perche il mezzo su cui sei non compare in lista.

    ATTENZIONE A format: in Arma gli indici oltre %9 NON vengono risolti, il
    parser legge %1 e poi la cifra come testo. Per questo il messaggio e
    spezzato in piu chiamate da meno di dieci argomenti l'una, invece di una
    sola lunga: e esattamente l'errore che aveva reso illeggibile la riga piu
    importante di questa diagnostica.
*/

private _v = vehicle player;

/*
    Fuori da un mezzo non c'e niente da diagnosticare, ma la VERSIONE serve
    sempre: e la prima cosa da controllare dopo un repack, e un drone lo si
    comanda da terra col terminale, quindi qui ci si finisce spesso.
*/
if (_v isEqualTo player) exitWith {
    hintSilent parseText format [
        "<t size='0.9'>Cam on Galaxy</t><br/>"
        + "<t size='0.8' color='#a0a0a0'>versione %1</t><br/><br/>"
        + "feed acceso: %2<br/>"
        + "sorgente: %3<br/>"
        + "puntamento: %4<br/>"
        + "ritaglio: %5<br/><br/>"
        + "<t color='#8fa389'>Sali su un mezzo per sapere perche non compare in lista</t>",
        crutek_dcam_version,
        if (crutek_dcam_active) then { "si" } else { "no" },
        if (isNull crutek_dcam_uav) then { "nessuna" } else { [crutek_dcam_uav] call crutek_fnc_dcamName },
        if (crutek_dcam_aim isEqualTo "") then { "nessuno" } else { crutek_dcam_aim },
        if (crutek_dcam_crop) then { "attivo" } else { "disattivato" }
    ];
};

// stesse fazioni ammesse della lista mezzi, decise dalle impostazioni
private _sides = [];
if (crutek_dcam_sideOwn)  then { _sides pushBackUnique (side group player) };
if (crutek_dcam_sideWest) then { _sides pushBackUnique west };
if (crutek_dcam_sideEast) then { _sides pushBackUnique east };
if (crutek_dcam_sideGuer) then { _sides pushBackUnique resistance };
if (crutek_dcam_sideCiv)  then { _sides pushBackUnique civilian };

private _alt  = (getPosATL _v) select 2;
private _lato = [_v] call crutek_fnc_dcamSide;
([_v] call crutek_fnc_dcamTurret) params ["_pos", "_dir", "_modo"];

private _cfg  = configFile >> "CfgVehicles" >> typeOf _v;
private _hasP = isClass (_cfg >> "pilotCamera");
// lo Stomper usa il punto Driver, non il Gunner: mostrarne uno solo
// faceva sembrare incoerente un modo MEM legittimo
private _memG = getText (_cfg >> "uavCameraGunnerPos");
if (_memG isEqualTo "") then { _memG = getText (_cfg >> "uavCameraDriverPos") };
private _pcd  = getPilotCameraDirection _v;
private _pcp  = getPilotCameraPosition _v;

private _si = { if (_this) then { "SI" } else { "NO" } };

private _t1 = format [
    "<t size='0.9'>%1</t><br/><t size='0.8' color='#a0a0a0'>versione %2</t><br/><br/>"
    + "vivo: %3<br/>mezzo aereo: %4<br/>quota %5 su soglia %6: %7<br/>escluso a mano: %8",
    typeOf _v,
    crutek_dcam_version,
    (alive _v) call _si,
    (_v isKindOf "Air") call _si,
    round _alt,
    crutek_dcam_minAlt,
    (_alt >= crutek_dcam_minAlt) call _si,
    (_v getVariable ["crutek_dcam_blocked", false]) call _si
];

private _t2 = format [
    "<br/>lato %1 fra %2: %3<br/>equipaggio a bordo: %9<br/><br/>"
    + "<t color='#e0a94a'>camera trovata: %4</t><br/>"
    + "classe pilotCamera: %5<br/>memory point drone: %6<br/>"
    + "getPilotCameraDirection: %7<br/>getPilotCameraPosition: %8",
    _lato,
    _sides,
    (_lato in _sides) call _si,
    if (_modo isEqualTo "") then { "NESSUNA" } else { _modo },
    _hasP call _si,
    if (_memG isEqualTo "") then { "no" } else { _memG },
    _pcd,
    _pcp,
    if (crutek_dcam_crewMode isEqualTo 3) then { "non richiesto" } else {
        if (({alive _x && {(side group _x) in _sides}} count (crew _v)) > 0) then { "SI" } else { "NO" }
    }
];

/*
    I due test per riconoscere un drone, mostrati separati: se il mezzo finisce
    nel ramo sbagliato e perche entrambi dicono NO.
*/
private _t3 = format [
    "<br/><br/>in allUnitsUAV: %1<br/>isKindOf UAV: %2<br/>in vehicles: %3<br/>"
    + "<br/><t color='#b6d3ad'>in lista: %4</t>",
    (_v in allUnitsUAV) call _si,
    (_v isKindOf "UAV") call _si,
    (_v in vehicles) call _si,
    (_v in (call crutek_fnc_dcamList)) call _si
];

hintSilent parseText (_t1 + _t2 + _t3);

diag_log format [
    "[crutek_dcam] diag %1 | modo '%2' | pilotCamera %3 | memG '%4' | dir %5",
    typeOf _v, _modo, _hasP, _memG, _pcd
];
