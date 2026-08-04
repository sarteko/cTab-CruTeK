/*
    crutek_fnc_dcamStations
    Elenca le postazioni di un mezzo che si possono guardare dal Galaxy.

    PERCHE SERVE UN ELENCO E NON UNA SOLA SCELTA.

    Fino a ieri di un mezzo si guardava una cosa sola: la camera finiva sul
    primo punto ottica trovato e puntava lungo la prima arma dell'elenco. Su
    un carro funzionava per combinazione, perche l'ottica del cannoniere e il
    cannone sono la stessa cosa. Sul posto comandante no, e infatti non lo si
    poteva guardare affatto.

    Qui invece ogni postazione vale per se. Non serve che sia armata: un posto
    comandante spesso e solo di osservazione, e va benissimo. Serve che
    dichiari un punto ottica risolvibile sul modello, altrimenti non si
    saprebbe da dove guardare.

    CHI ENTRA NELL'ELENCO.
    Solo le postazioni occupate da qualcuno di vivo. Una torretta vuota resta
    dove l'hanno lasciata e non c'e nessuna vista da riprodurre.

    Il ruolo non lo scrivo io: e gunnerName dichiarato nella torretta, quindi
    e la dicitura del gioco ed e gia tradotta.

    I mezzi coperti da un profilo di compatibilita non passano di qui: quelli
    hanno un elenco di postazioni dichiarato a mano, e comanda quello.

    0: OBJECT - il mezzo
    Ritorna: ARRAY - una voce per postazione, [percorso, punto ottica, unita, ruolo]
*/

params [["_veh", objNull]];
if (isNull _veh) exitWith { [] };

private _out = [];

{
    private _path = _x;
    private _u    = _veh turretUnit _path;

    if (!isNull _u && {alive _u}) then {
        private _tc = [_veh, _path] call BIS_fnc_turretConfig;

        if (isClass _tc) then {
            private _mp = "";
            {
                private _q = getText (_tc >> _x);
                if (_q != "" && {!((_veh selectionPosition _q) isEqualTo [0,0,0])}) exitWith {
                    _mp = _q;
                };
            } forEach ["memoryPointGunnerOptics", "memoryPointGunnerOutOptics"];

            if !(_mp isEqualTo "") then {
                private _ruolo = getText (_tc >> "gunnerName");
                if ((_ruolo select [0,1]) isEqualTo "$") then {
                    _ruolo = localize (_ruolo select [1]);
                };
                if (_ruolo isEqualTo "") then { _ruolo = configName _tc };
                _out pushBack [_path, _mp, _u, _ruolo];
            };
        };
    };
} forEach (allTurrets _veh);

_out
