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
    private _op = gunner _veh;
    if (isNull _op || {!isPlayer _op}) then { _op = driver _veh };
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
