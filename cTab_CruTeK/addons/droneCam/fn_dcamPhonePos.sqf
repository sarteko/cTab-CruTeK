/*
    crutek_fnc_dcamPhonePos
    Appoggia il dispositivo cTab a un bordo dello schermo.

    Su schermi ultralarghi la finestra del telefono resta tagliata dal bordo,
    perche' la sua posizione la decide cTab e non tiene conto di proporzioni
    estreme. Qui si misura l'ingombro di tutti i suoi controlli e lo si sposta
    in blocco, senza toccarne nessuno singolarmente: cosi' la disposizione
    interna resta quella loro e cambia solo dove sta il tutto.

    0: DISPLAY - il display del telefono
*/

/*
    Non si tocca MAI la visibilita' dei controlli di cTab.

    cTab ha un cartello "Loading" che mostra durante i suoi aggiornamenti e
    nasconde alla fine. Riaccendendo tutti i controlli dopo lo spostamento lo
    riaccendevamo anche noi, dopo che loro l'avevano tolto: restava sopra la
    mappa per sempre, e sembrava che la mappa non caricasse.

    Qui si spostano e basta.
*/

params [["_d", displayNull]];
if (isNull _d) exitWith {};

/*
    Riposizionamento del telefono.

    Spostare i controlli della schermata cTab fa ricaricare la sua mappa, che
    resta in "Loading..." e non finisce piu'. Provato a spostare a ogni
    fotogramma, una volta sola, nascondendo e riaccendendo i controlli: in
    tutti i casi la mappa non si apre.

    Il controllo mappa di ARMA si ricarica quando viene riposizionato: e' il
    gioco a farlo, e da fuori non si evita.

    Percio' si sposta UNA VOLTA SOLA per apertura: la mappa si ricarica quel
    tanto che serve e poi finisce. Ritentare a ogni fotogramma la faceva
    ripartire da capo all'infinito, ed e' li' che restava in "Loading...".
*/
if !(missionNamespace getVariable ["crutek_dcam_pos", false]) exitWith {};
private _dove = missionNamespace getVariable ["crutek_dcam_posLato", 1];

private _tutti = allControls _d;
if (_tutti isEqualTo []) exitWith {};

// ingombro complessivo
private _x1 = 1e6; private _y1 = 1e6;
private _x2 = -1e6; private _y2 = -1e6;
/*
    I NOSTRI controlli restano fuori dalla misura.

    Il quadro del feed e' allargato di 1.88 e sborda dal gruppo: contandolo,
    l'ingombro risulta molto piu' largo del telefono e lo spostamento va fuori
    scala. Vanno misurati solo i controlli di cTab, cioe' quelli con idc fuori
    dalla nostra fascia 91000-91999.
*/
{
    private _idc = ctrlIDC _x;
    (ctrlPosition _x) params ["_cx", "_cy", "_cw", "_ch"];
    if (_cw > 0 && {_ch > 0} && {_idc < 91000 || {_idc > 91999}}) then {
        if (_cx < _x1) then {_x1 = _cx};
        if (_cy < _y1) then {_y1 = _cy};
        if ((_cx + _cw) > _x2) then {_x2 = _cx + _cw};
        if ((_cy + _ch) > _y2) then {_y2 = _cy + _ch};
    };
} forEach _tutti;

private _w = _x2 - _x1;
private _h = _y2 - _y1;
if (_w <= 0 || {_h <= 0}) exitWith {};

/*
    Margini dal bordo.

    Tutti e due misurati sull'ALTEZZA, non sulla larghezza: l'altezza e' la
    dimensione stabile fra i formati, mentre la larghezza cambia molto fra un
    16:9 e un ultralargo. Misurando sulla larghezza, lo stesso numero darebbe
    uno stacco enorme su uno schermo largo e minuscolo su uno normale.
    Cosi' invece il distacco dal bordo si vede uguale per tutti.
*/
private _mx = missionNamespace getVariable ["crutek_dcam_posMx", -0.022];
private _my = missionNamespace getVariable ["crutek_dcam_posMy", -0.2];
private _bordo = _mx * safeZoneH;

private _nx = switch (_dove) do {
    case 0: { safeZoneX + _bordo };
    case 2: { safeZoneX + safeZoneW - _w - _bordo };
    default { safeZoneX + (safeZoneW - _w) / 2 };
};
/*
    Ancoraggio verticale: 0 appoggia in basso, 1 appoggia in alto. Il margine
    resta lo stesso, cambia solo da quale bordo si misura.
*/
private _ny = if ((missionNamespace getVariable ["crutek_dcam_posVert", 0]) isEqualTo 1) then {
    safeZoneY + (_my * safeZoneH)
} else {
    safeZoneY + safeZoneH - _h - (_my * safeZoneH)
};

private _dx = _nx - _x1;
private _dy = _ny - _y1;

/*
    Gia' al posto giusto: si riaccende comunque e si segnala, cosi' il
    controllo smette di ricalcolare. Il riaccendere qui e' obbligatorio: chi
    chiama ha spento tutto prima, e uscendo senza riaccendere il telefono
    resterebbe invisibile.
*/
if ((abs _dx) < 0.0005 && {(abs _dy) < 0.0005}) exitWith {
        crutek_dcam_posOk = true;
};

{
    (ctrlPosition _x) params ["_cx", "_cy", "_cw", "_ch"];
    _x ctrlSetPosition [_cx + _dx, _cy + _dy, _cw, _ch];
    _x ctrlCommit 0;
} forEach _tutti;

crutek_dcam_posOk = true;

/*
    Il feed va ricostruito.

    I nostri controlli vengono creati una volta sola, misurando dove sta la
    mappa del telefono in quel momento, e poi l'overlay non ci torna piu' sopra.
    Spostandoli a mano restano allineati per un attimo, ma il ritaglio e le
    bande continuano a fare i conti sulla posizione vecchia. Azzerando il
    segnaposto, alla prossima passata l'overlay si rifa' da capo sulla
    posizione nuova.
*/
if (crutek_dcam_active && {!(crutek_dcam_overlayOn isEqualTo "")}) then {
    /*
        Si smonta chiamando OFF, non azzerando il segnaposto: quel valore serve
        proprio a ritrovare i controlli da cancellare. Azzerandolo, lo smontaggio
        esce subito senza togliere niente e la ricostruzione si sovrappone alla
        precedente - a schermo diventa un riquadro dentro l'altro.
    */
    ["OFF"] call crutek_fnc_dcamOverlay;
};
