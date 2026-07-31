/*
    crutek_fnc_dcamCrop
    Zoom digitale: ingrandisce il controllo del feed dentro il suo gruppo,
    tenendolo centrato. Il gruppo taglia quello che esce, quindi il risultato
    e un ritaglio ingrandito dell'immagine.

    Serve perche camSetFov non scende sotto 0.01: da li in poi l'unico modo
    per stringere ancora e ritagliare. L'immagine perde nitidezza, perche si
    sta ingrandendo un render target di risoluzione limitata.
*/

disableSerialization;
if (crutek_dcam_overlayOn isEqualTo "") exitWith {};

private _d = uiNamespace getVariable [crutek_dcam_overlayOn, displayNull];
if (isNull _d) exitWith {};

private _pic = _d displayCtrl crutek_dcam_idcPic;
if (isNull _pic) exitWith {};

crutek_dcam_picBox params [["_w", 0], ["_h", 0]];
if (_w <= 0 || {_h <= 0}) exitWith {};

private _z  = crutek_dcam_cropZoom max 1;
private _nw = _w * _z;
private _nh = _h * _z;

// posizione relativa al gruppo: allargato e ricentrato
_pic ctrlSetPosition [(_w - _nw) / 2, (_h - _nh) / 2, _nw, _nh];
_pic ctrlCommit 0;
