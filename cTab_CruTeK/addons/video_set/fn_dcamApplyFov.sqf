/*
    crutek_fnc_dcamApplyFov
    Unico punto in cui si decide l'inquadratura.

    Il FOV dell'operatore va prima corretto per la forma del riquadro
    (fovAuto), poi rifinito a mano se serve (fovScale). Finche il valore
    risultante sta sopra il minimo di camSetFov (0.01) si stringe
    otticamente. Sotto quel muro la camera resta al minimo e il resto lo fa il
    ritaglio digitale, che ingrandisce ma non aggiunge dettaglio.
*/

if (!crutek_dcam_active || {isNull crutek_dcam_cam}) exitWith {};

private _want = crutek_dcam_fov * crutek_dcam_fovAuto * crutek_dcam_fovScale;

private _f = (_want max crutek_dcam_fovMin) min 2;
crutek_dcam_fovApplied = _f;

// quello che l'ottica non riesce a stringere lo recupera il ritaglio
/*
    Il ritaglio recupera quello che l'ottica non riesce a stringere, ma non
    oltre il tetto: sopra quello l'immagine si sfalsa piu di quanto valga il
    guadagno di ingrandimento.
*/
crutek_dcam_cropZoom = if (crutek_dcam_crop) then {
    ((_f / (_want max 1e-6)) max 1) min (crutek_dcam_cropMax max 1)
} else {
    1
};

crutek_dcam_cam camSetFov _f;
crutek_dcam_cam camCommit 0;

call crutek_fnc_dcamCrop;
