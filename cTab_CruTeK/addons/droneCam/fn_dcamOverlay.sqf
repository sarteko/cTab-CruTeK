/*
    crutek_fnc_dcamOverlay
    Crea o rimuove i controlli del feed sopra lo schermo del Galaxy.

    Funziona sia sul telefono aperto (cTab_Android_dlg) sia su quello piccolo
    sempre a schermo (cTab_Android_dsp): hanno la mappa allo stesso IDC 1202,
    quindi il feed si posiziona sopra di essa senza toccare la macchina a
    stati dell'interfaccia di cTab.

    0: STRING - "ON" oppure "OFF"
*/

disableSerialization;
params [["_mode", "ON"]];

/*
    IDC del rilevamento. Sta qui e non in dcamInit perche lo usano soltanto
    questo file e dcamHud: cosi la riga del rilevamento e tutta contenuta e
    non serve toccare altro per averla.
*/
if (isNil "crutek_dcam_idcBrg")   then { crutek_dcam_idcBrg   = 91005; };
if (isNil "crutek_dcam_idcBrgBg") then { crutek_dcam_idcBrgBg = 91006; };
if (isNil "crutek_dcam_idcNam")   then { crutek_dcam_idcNam   = 91007; };

private _fnc_target = {
    if (isNil "cTabIfOpen") exitWith { ["", displayNull] };
    private _n = cTabIfOpen select 1;
    if (count _n < 12) exitWith { ["", displayNull] };
    if !((_n select [0, 12]) isEqualTo "cTab_Android") exitWith { ["", displayNull] };
    [_n, uiNamespace getVariable [_n, displayNull]]
};

private _fnc_strip = {
    private _prev = crutek_dcam_overlayOn;
    if (_prev isEqualTo "") exitWith {};

    private _pd = uiNamespace getVariable [_prev, displayNull];
    if !(isNull _pd) then {
        {
            private _c = _pd displayCtrl _x;
            if !(isNull _c) then { ctrlDelete _c };
        } forEach [crutek_dcam_idcPic, crutek_dcam_idcName, crutek_dcam_idcBrgBg, crutek_dcam_idcTop, crutek_dcam_idcBrg, crutek_dcam_idcBot, crutek_dcam_idcNam, crutek_dcam_idcGrp];

        /*
            Gli indici seguono l'ordine di registrazione qui sotto:
            0 nome, 1 KeyDown, 2 KeyUp, 3 MouseButtonDown, 4 MouseButtonUp,
            5 MouseZChanged.
            Togliendo un gestore dalla registrazione vanno rinumerati anche
            qui, altrimenti si smonta quello sbagliato in silenzio.
        */
        if ((count crutek_dcam_ehDlg) >= 6 && {(crutek_dcam_ehDlg select 0) isEqualTo _prev}) then {
            _pd displayRemoveEventHandler ["KeyDown",         crutek_dcam_ehDlg select 1];
            _pd displayRemoveEventHandler ["KeyUp",           crutek_dcam_ehDlg select 2];
            _pd displayRemoveEventHandler ["MouseButtonDown", crutek_dcam_ehDlg select 3];
            _pd displayRemoveEventHandler ["MouseButtonUp",   crutek_dcam_ehDlg select 4];
            _pd displayRemoveEventHandler ["MouseZChanged",   crutek_dcam_ehDlg select 5];
        };
    };
    crutek_dcam_ehDlg = [];
    crutek_dcam_overlayOn = "";
};

if (_mode isEqualTo "OFF" || {crutek_dcam_hidden}) exitWith { call _fnc_strip };

(call _fnc_target) params ["_name", "_d"];

// nessun telefono aperto: smonta e basta
if (_name isEqualTo "" || {isNull _d}) exitWith { call _fnc_strip };

// gia montato sul display giusto e i controlli ci sono ancora
if (_name isEqualTo crutek_dcam_overlayOn) exitWith {
    if (isNull (_d displayCtrl crutek_dcam_idcPic)) then {
        call _fnc_strip;
    };
};

call _fnc_strip;

private _map = _d displayCtrl 1202;
if (isNull _map) exitWith {};

(ctrlPosition _map) params ["_mx", "_my", "_mw", "_mh"];
if (_mw <= 0 || {_mh <= 0}) exitWith {};

// riquadro ricavato dal controllo mappa secondo crutek_dcam_frameRect
crutek_dcam_frameRect params [["_rx", 0], ["_ry", 0], ["_rw", 1], ["_rh", 1]];
private _px = _mx + (_mw * _rx);
private _py = _my + (_mh * _ry);
private _pw = _mw * _rw;
private _ph = _mh * _rh;
if (_pw <= 0 || {_ph <= 0}) exitWith {};

(getResolution) params ["_resX", "_resY"];

/*
    Il riquadro viene incassato nella forma richiesta, restando centrato.
    Con il 4:3 del FLIR sul telefono avanzano due bande ai lati, ed e il
    prezzo per avere la stessa inquadratura invece dell'effetto grandangolo.
*/
if (crutek_dcam_frameAspect > 0) then {
    private _cur = (_pw * _resX) / ((_ph * _resY) max 1);
    if (_cur > crutek_dcam_frameAspect) then {
        // troppo largo: si stringe in orizzontale
        private _nw = _pw * (crutek_dcam_frameAspect / _cur);
        _px = _px + ((_pw - _nw) / 2);
        _pw = _nw;
    } else {
        // troppo alto: si stringe in verticale
        private _nh = _ph * (_cur / crutek_dcam_frameAspect);
        _py = _py + ((_ph - _nh) / 2);
        _ph = _nh;
    };
};

private _ratio = (_pw * _resX) / ((_ph * _resY) max 1);

// nessuna correzione: la forma del riquadro ora coincide con quella del FLIR
crutek_dcam_fovAuto = 1;

/*
    Il feed sta dentro un gruppo di controlli: quello che esce dai bordi del
    gruppo viene tagliato, ed e cosi che funziona lo zoom digitale oltre il
    limite di camSetFov. La posizione del quadro la decide dcamCrop.
*/
private _grp = _d ctrlCreate ["cTab_RscControlsGroup", crutek_dcam_idcGrp];
_grp ctrlSetPosition [_px, _py, _pw, _ph];
_grp ctrlCommit 0;

private _pic = _d ctrlCreate ["cTab_RscPicture", crutek_dcam_idcPic, _grp];
_pic ctrlSetTextColor [1, 1, 1, 1];
_pic ctrlSetText format [
    "#(argb,%1,%2,1)r2t(%3,%4)",
    crutek_dcam_rtSize, crutek_dcam_rtSize,
    crutek_dcam_rt, _ratio
];
_pic ctrlCommit 0;

// dimensioni della finestra visibile, servono a dcamCrop per ricentrare
crutek_dcam_picBox  = [_pw, _ph];
// rettangolo a schermo, serve a capire se il cursore e sopra il video
crutek_dcam_picRect = [_px, _py, _pw, _ph];

/*
    Targhetta scura dietro al nome, per le sole telecamere da casco.

    Va creata PRIMA della riga di testo: i controlli si disegnano nell'ordine
    in cui nascono, quindi questo finisce sotto e il nome ci resta sopra.
    Nasce nascosta e la misura gliela da dcamHud, che e l'unico posto che sa
    quanto e lungo il nome.
*/
private _targa = _d ctrlCreate ["cTab_RscText", crutek_dcam_idcName];
_targa ctrlSetBackgroundColor [0, 0, 0, 0.45];
_targa ctrlShow false;
_targa ctrlCommit 0;

/*
    Targhetta scura dietro al rilevamento, stessa idea di quella del nome.
    Nasce qui, insieme all'altra e prima dei due testi: cosi entrambe le
    targhette restano sotto e nessuna finisce sopra a una scritta. La misura
    e la posizione gliele da dcamHud, che e l'unico posto che sa quanto e
    largo il numero.
*/
private _brgBg = _d ctrlCreate ["cTab_RscText", crutek_dcam_idcBrgBg];
_brgBg ctrlSetBackgroundColor [0, 0, 0, 0.45];
_brgBg ctrlShow false;
_brgBg ctrlCommit 0;

/*
    Le righe di servizio stanno appiccicate ai bordi del video: margine
    dell'1 per cento invece del 3, e altezza del controllo ridotta da 0.16 a
    0.12. L'altezza conta: un controllo alto lascia il testo a mezz'aria
    dentro il riquadro, e con un controllo basso il testo finisce dove lo
    metti a prescindere da come il motore lo allinea in verticale.

    Il rilevamento al centro segue la riga alta, ed e l'unico che resta
    dov'era: li si legge bene.
*/
private _top = _d ctrlCreate ["cTab_RscStructuredText", crutek_dcam_idcTop];
_top ctrlSetPosition [_px + (_pw * 0.01), _py + (_ph * 0.01), _pw * 0.98, _ph * 0.12];
_top ctrlCommit 0;

/*
    Rilevamento, in alto al centro.

    Occupa la stessa riga del nome ma con il testo centrato, quindi il nome
    resta a sinistra e il numero finisce in mezzo. Nasce DOPO la riga del
    nome perche i controlli si disegnano nell'ordine in cui nascono: cosi
    con un nome lungo il rilevamento resta leggibile sopra.
*/
private _brg = _d ctrlCreate ["cTab_RscStructuredText", crutek_dcam_idcBrg];
_brg ctrlSetPosition [_px + (_pw * 0.01), _py + (_ph * 0.01), _pw * 0.98, _ph * 0.12];
_brg ctrlCommit 0;

private _bot = _d ctrlCreate ["cTab_RscStructuredText", crutek_dcam_idcBot];
_bot ctrlSetPosition [_px + (_pw * 0.01), _py + (_ph * 0.87), _pw * 0.98, _ph * 0.12];
_bot ctrlCommit 0;

/*
    Il nome della sorgente sta sulla stessa riga bassa ma allineato a destra.
    Serve un controllo suo: dentro un testo strutturato l'allineamento vale
    per tutto il paragrafo, quindi sinistra e destra sulla stessa riga non si
    ottengono con un controllo solo.
*/
private _nam = _d ctrlCreate ["cTab_RscStructuredText", crutek_dcam_idcNam];
_nam ctrlSetPosition [_px + (_pw * 0.01), _py + (_ph * 0.87), _pw * 0.98, _ph * 0.12];
_nam ctrlCommit 0;

crutek_dcam_overlayOn = _name;
call crutek_fnc_dcamCrop;

// una riga nel .rpt con i numeri delle proporzioni, utile se la taratura
// a mano non basta e serve capire da dove viene la differenza
/*
    Riga di controllo nel .rpt. Il riquadro e riportato in PIXEL A SCHERMO,
    cosi si confronta al volo con una misura fatta a occhio su uno screenshot.
*/
diag_log format [
    "[crutek_dcam] %1 | riquadro %2 x %3 px | forma %4 (richiesta %5) | schermo %6 x %7 | fovScale %8",
    _name,
    round (_pw * _resX),
    round (_ph * _resY),
    (round (_ratio * 1000)) / 1000,
    crutek_dcam_frameAspect,
    _resX,
    _resY,
    crutek_dcam_fovScale
];

// se e il telefono aperto (dialogo) prende lui l'input: aggancio anche li
if ([_name] call cTab_fnc_isDialog) then {
    crutek_dcam_ehDlg = [
        _name,
        _d displayAddEventHandler ["KeyDown",       { [_this, true]  call crutek_fnc_dcamInput }],
        _d displayAddEventHandler ["KeyUp",         { [_this, false] call crutek_fnc_dcamInput }],
        _d displayAddEventHandler ["MouseButtonDown", { [_this, "down"] call crutek_fnc_dcamClick }],
        _d displayAddEventHandler ["MouseButtonUp",   { [_this, "up"]   call crutek_fnc_dcamClick }],
        _d displayAddEventHandler ["MouseZChanged",   { [_this select 1] call crutek_fnc_dcamWheel }]
    ];
};
