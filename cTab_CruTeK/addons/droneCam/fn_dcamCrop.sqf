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

/*
    Correzione delle proporzioni.

    Il gioco renderizza dentro il render target con la forma della vista
    principale, il pannello del telefono e' 1128x616 cioe' 1.83, e la
    differenza fra i due schiaccia le figure. Il fattore 1.88 e' quel rapporto,
    trovato provando a schermo e poi confermato dal conto.

    Si allarga solo in orizzontale. In verticale si resta a 1: alzarlo faceva
    comparire le barre del gruppo, che ora comunque non ci sono piu'.
*/
private _fx = missionNamespace getVariable ["crutek_dcam_aspX", 1.88];
private _fy = missionNamespace getVariable ["crutek_dcam_aspY", 1];

private _z  = crutek_dcam_cropZoom max 1;
private _nw = _w * _z * _fx;
private _nh = _h * _z * _fy;

// posizione relativa al gruppo: allargato e ricentrato
_pic ctrlSetPosition [(_w - _nw) / 2, (_h - _nh) / 2, _nw, _nh];
_pic ctrlCommit 0;
