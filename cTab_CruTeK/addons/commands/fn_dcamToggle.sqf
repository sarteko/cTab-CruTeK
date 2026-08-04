/*
    crutek_fnc_dcamToggle
    Nasconde o rimostra il feed sullo schermo del Galaxy senza scollegare
    il drone: la camera resta viva, torna solo visibile la mappa sotto.
*/

if (!crutek_dcam_active) exitWith {};

crutek_dcam_hidden = !crutek_dcam_hidden;

if (crutek_dcam_hidden) then {
    ["OFF"] call crutek_fnc_dcamOverlay;
    ["DroneCam", localize "STR_crutek_dcam_not_hidden"] call crutek_fnc_dcamNotify;
} else {
    ["DroneCam", localize "STR_crutek_dcam_not_shown"] call crutek_fnc_dcamNotify;
};
