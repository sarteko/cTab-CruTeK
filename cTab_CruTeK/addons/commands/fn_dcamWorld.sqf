/*
    crutek_fnc_dcamWorld
    Accende o spegne il trattamento del MONDO che A3TI usa per le sue termiche:
    secondo sole e ridipintura di mezzi e uomini con la texture rossa.

    Sono due terzi della sua ricetta; il terzo, i pesi colore, sta sul render
    target in fn_dcamVision. Vanno accesi e spenti insieme.

    IL ROSSO CHE SI VEDE A OCCHIO NUDO.
    La ridipintura e una modifica al mondo su questo client, non alla sola
    camera: sul telefono i pesi colore la trasformano in bianco caldo, fuori
    resta rossa. A3TI non offre modo di scegliere quali oggetti trattare, la
    sua lista e cablata a vehicles + allUnits.

    Si aggira col suo stesso registro: A3TI tiene in A3TI_obj_used gli oggetti
    gia trattati e li salta, sia in accensione sia in ripristino (li riconosce
    perche non hanno texture salvate). Registrando in anticipo quelli vicini a
    te, resteranno normali mentre tutto il resto viene ridipinto.

    Limite onesto: e una fotografia scattata al momento dell'accensione. Chi
    era lontano e poi ti si avvicina resta rosso finche non cambi modo.

    0: BOOL - acceso
*/

params [["_on", false]];

if (isNil "A3TI_fnc_setObjects" || {isNil "A3TI_fnc_createSecondSun"}) exitWith {
    diag_log "[crutek_dcam] " + (localize "STR_crutek_dcam_not_a3ti");
};

if (_on isEqualTo crutek_dcam_worldOn) exitWith {};
crutek_dcam_worldOn = _on;

if (!_on) exitWith {
    call A3TI_fnc_destroySecondSun;
    ["OFF"] call A3TI_fnc_setObjects;
};

/*
    Si protegge quello che hai intorno: la tua squadra sempre, piu tutto
    quello che in questo momento sta entro crutek_dcam_paintKeep metri.
    Con 0 si disattiva la protezione e viene ridipinto tutto, come fa A3TI.
*/
if (crutek_dcam_paintKeep > 0) then {
    private _keep = +(units group player);
    _keep append ((vehicles + allUnits) select {
        (_x distance player) < crutek_dcam_paintKeep
    });
    _keep = _keep arrayIntersect _keep;

    // il registro di A3TI: quello che c'e dentro non viene toccato
    missionNamespace setVariable ["A3TI_obj_used", _keep];
};

call A3TI_fnc_createSecondSun;
["ON", nil, nil, "A3TI_Thermal_Texture_Red"] call A3TI_fnc_setObjects;
