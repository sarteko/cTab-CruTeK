/*
    crutek_fnc_dcamCycle
    Cicla il selettore.

    Droni:        AUTO, NV, TH1, TH2
    Helmet cam:   D-TV, NV e basta, non c'e nessuna termica da mostrare

    Cambiare selettore non tocca in nessun modo cosa vede l'operatore: i
    filtri del render target vivono solo su questo client.

    0: NUMBER - +1 avanti, -1 indietro
*/

params [["_delta", 1]];
if (!crutek_dcam_active) exitWith {};

private _list = if (crutek_dcam_kind isEqualTo "HCAM") then {
    crutek_dcam_modesHcam
} else {
    crutek_dcam_modes
};

private _n = count _list;
if (_n < 1) exitWith {};

crutek_dcam_mode = (crutek_dcam_mode + _delta + _n) mod _n;
call crutek_fnc_dcamRefresh;
