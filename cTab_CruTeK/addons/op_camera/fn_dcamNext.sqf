/*
    crutek_fnc_dcamNext
    Passa alla telecamera da casco successiva o precedente.

    Vale SOLO per gli operatori: sui mezzi la sorgente si sceglie dal menu
    ACE, perche li l'elenco e diviso per categoria e scorrerlo alla cieca non
    avrebbe senso.

    L'elenco e lo stesso del menu, quindi rispetta i filtri della missione:
    fazioni ammesse e distanza massima. Se l'operatore che stai guardando nel
    frattempo e uscito dall'elenco, si riparte dal primo invece di piantarsi.

    0: NUMBER - +1 avanti, -1 indietro
*/

params [["_delta", 1]];

if (!crutek_dcam_active) exitWith {};
if !(crutek_dcam_kind isEqualTo "HCAM") exitWith {};

private _lista = call crutek_fnc_dcamHcams;
private _n = count _lista;
if (_n isEqualTo 0) exitWith {};

private _i = _lista findIf { _x isEqualTo crutek_dcam_uav };
private _next = if (_i < 0) then { 0 } else { (_i + _delta + _n) mod _n };

private _sub = _lista select _next;
// un solo operatore in lista: non c'e niente da cambiare
if (_sub isEqualTo crutek_dcam_uav) exitWith {};

[_sub, "HCAM"] call crutek_fnc_dcamOpen;
