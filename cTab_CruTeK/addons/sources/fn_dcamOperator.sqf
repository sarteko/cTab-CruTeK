/*
    crutek_fnc_dcamOperator
    Chi sta comandando la TORRETTA del mezzo.

    Due casi diversi:

    - aerei ed elicotteri con equipaggio: l'operatore e semplicemente il
      gunner, sta fisicamente a bordo

    - droni: UAVControl accetta solo un oggetto, la sintassi ad array non
      esiste. Dalla 1.96 pero la sintassi normale restituisce tutti i
      collegati in coppie [unita, ruolo, unita2, ruolo2], quindi si scandisce.
      E lo stesso approccio che usa A3TI in fn_getCurrentControlledUnit.

    0: OBJECT - drone, aereo o elicottero
    Ritorna: OBJECT - il player al posto torretta, objNull se non c'e
*/

params [["_veh", objNull]];
if (isNull _veh) exitWith { objNull };

/*
    ---- mezzi con equipaggio a bordo -------------------------------
    Non basta guardare il gunner: su molti aerei il pod di puntamento e una
    pilotCamera, cioe per definizione la usa chi sta ai comandi. L'A-10 non ha
    proprio un posto artigliere, quindi cercando solo li non si troverebbe mai
    nessun operatore e il feed resterebbe a rispecchiare il vuoto.

    Il gunner ha comunque la precedenza: dove esiste, e lui che punta.
*/
if !(_veh in allUnitsUAV) exitWith {
    /*
        L'ORDINE CONTA.

        1. Se il feed sta guardando una postazione precisa di QUESTO mezzo,
           l'operatore e chi ci sta seduto: e la sua vista che si sta
           riproducendo, e sono il suo zoom e la sua termica che vanno
           rispecchiati.
        2. Poi il cannoniere primario.
        3. Poi un giocatore in una torretta qualunque. gunner restituisce solo
           la primaria, quindi senza questo passaggio un comandante, o chi
           siede su un mezzo dove nessuna torretta e dichiarata primaria, non
           verrebbe trovato affatto e il feed resterebbe senza operatore.
        4. In ultimo chi guida, che serve a chi vola: li il pod lo punta chi e
           ai comandi, e un posto artigliere a volte non esiste nemmeno.
    */
    private _op   = objNull;
    private _vist = missionNamespace getVariable ["crutek_dcam_turret", []];
    private _sorg = missionNamespace getVariable ["crutek_dcam_uav", objNull];

    if (!(_vist isEqualTo []) && {_veh isEqualTo _sorg}) then {
        private _u = _veh turretUnit _vist;
        if (!isNull _u && {alive _u} && {isPlayer _u}) then { _op = _u };
    };

    if (isNull _op) then {
        private _g = gunner _veh;
        if (!isNull _g && {alive _g} && {isPlayer _g}) then { _op = _g };
    };

    if (isNull _op) then {
        {
            private _u = _veh turretUnit _x;
            if (!isNull _u && {alive _u} && {isPlayer _u}) exitWith { _op = _u };
        } forEach (allTurrets _veh);
    };

    if (isNull _op) then {
        private _d = driver _veh;
        if (!isNull _d && {alive _d} && {isPlayer _d}) then { _op = _d };
    };

    if (!isNull _op && {isPlayer _op}) then { _op } else { objNull }
};

// ---- droni --------------------------------------------------------
private _all = UAVControl _veh;
if !(_all isEqualType []) exitWith { objNull };

private _res = objNull;
private _n   = count _all;
private _i   = 0;

while { _i < (_n - 1) } do {
    private _u = _all select _i;
    private _r = _all select (_i + 1);

    if (
        _u isEqualType objNull
        && {!isNull _u}
        && {isPlayer _u}
        && {_r isEqualType ""}
        && {(toUpper _r) isEqualTo "GUNNER"}
    ) then {
        _res = _u;
        _i = _n;
    } else {
        _i = _i + 2;
    };
};

_res
