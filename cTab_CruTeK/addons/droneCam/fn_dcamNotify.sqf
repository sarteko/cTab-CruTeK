/*
    crutek_fnc_dcamNotify
    Messaggio breve. Usa le notifiche di cTab se disponibili.

    0: STRING - titolo
    1: STRING - testo
*/

params [["_title", "DroneCam"], ["_text", ""]];
if (_text isEqualTo "") exitWith {};

if (!isNil "cTab_fnc_addNotification") exitWith {
    [_title, _text, 4] call cTab_fnc_addNotification;
};

hintSilent parseText format ["<t size='0.9'>%1</t><br/><t size='0.8' color='#a0a0a0'>%2</t>", _title, _text];
