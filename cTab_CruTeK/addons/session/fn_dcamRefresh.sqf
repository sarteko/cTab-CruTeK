/*
    crutek_fnc_dcamRefresh
    Risolve il selettore in un modo effettivo e lo applica solo se cambia.

    AUTO   -> segue l'operatore della torretta (D-TV, NV, TH1 o TH2)
    NV     -> visore notturno, sempre
    TH1    -> termica 1, sempre
    TH2    -> termica 2, sempre

    Sulle telecamere da casco non c'e niente da rispecchiare e nessuna
    termica da mostrare: il selettore ha due sole posizioni, D-TV e visore
    notturno.
*/

if (!crutek_dcam_active) exitWith {};

if (crutek_dcam_kind isEqualTo "HCAM") exitWith {
    private _last = (count crutek_dcam_modesHcam) - 1;
    private _eff  = crutek_dcam_modesHcam select ((crutek_dcam_mode max 0) min _last);
    if !(_eff isEqualTo crutek_dcam_effective) then {
        crutek_dcam_effective = _eff;
        [_eff] call crutek_fnc_dcamVision;
    };
};

private _sel = crutek_dcam_modes select crutek_dcam_mode;
private _eff = _sel;

/*
    Scegliendo una termica a mano, AUTO se la ricorda.

    ARMA espone solo tre visioni - normale, notturno, termico - e non dice se
    la termica in corso e' bianco caldo o nero caldo. AUTO quindi non puo'
    indovinarlo: con A3TI la variante arriva e viene seguita, senza A3TI ogni
    termica finirebbe sempre su TH1. Ricordando l'ultima scelta a mano, chi
    preferisce il nero caldo lo imposta una volta e AUTO glielo tiene.
*/
if (_sel in ["THERM1", "THERM2"]) then {
    crutek_dcam_bhot = (_sel isEqualTo "THERM2");
};

if (_sel isEqualTo "AUTO") then {
    // senza operatore o senza dati si resta sulla vista a colori
    _eff = "DTV";

    if (crutek_dcam_hasOp) then {
        (crutek_dcam_uav getVariable ["crutek_dcam_view", []]) params [["_vision", -1], ["_a3ti", ""], "", ["_ti", -1]];
        if (_vision >= 0) then {
            _eff = switch (true) do {
                case (_a3ti in ["WHOT", "WHOT/LLTV"]): { "THERM1" };
                case (_a3ti in ["BHOT", "BHOT/LLTV"]): { "THERM2" };
                /*
                    ARMA non dice quale termica sia attiva, quindi si usa quella
                    indicata nelle opzioni. Si legge DIRETTAMENTE l'opzione: la
                    variabile di appoggio che c'era prima veniva riscritta
                    dall'inizializzazione subito dopo, e la spunta non aveva
                    alcun effetto. Con A3TI la variante vera arriva ed e' il ramo
                    qui sopra a occuparsene.
                */
                // indice pubblicato da chi comanda: 1 e' nero caldo
                case (_vision isEqualTo 2 && {_ti isEqualTo 1}): { "THERM2" };
                case (_vision isEqualTo 2 && {_ti isEqualTo 0}): { "THERM1" };
                case (_vision isEqualTo 2): {
                    if (missionNamespace getVariable ["crutek_dcam_bhot", false]) then {
                        "THERM2"
                    } else {
                        "THERM1"
                    }
                };
                case (_vision isEqualTo 1):            { "NVG" };
                default { "DTV" };
            };
        };
    };
};

/*
    La ricetta A3TI piena si accende secondo crutek_dcam_a3ti:
      "OFF"     mai, termica del motore
      "DIALOG"  solo col telefono aperto a tutto schermo
      "ALWAYS"  sempre, anche col telefono piccolo

    "DIALOG" e il compromesso: la ridipintura del mondo si vede a occhio nudo,
    ma col telefono aperto stai guardando il feed, non combattendo.
*/
private _full = false;
if (crutek_dcam_hasA3TI && {!(crutek_dcam_a3ti isEqualTo "OFF")}) then {
    _full = if (crutek_dcam_a3ti isEqualTo "ALWAYS") then {
        true
    } else {
        (crutek_dcam_overlayOn != "") && {[crutek_dcam_overlayOn] call cTab_fnc_isDialog}
    };
};

// si riapplica anche quando cambia solo la disponibilita della ricetta piena,
// per esempio aprendo o chiudendo il telefono a tutto schermo
if (!(_eff isEqualTo crutek_dcam_effective) || {!(_full isEqualTo crutek_dcam_fullNow)}) then {
    crutek_dcam_effective = _eff;
    crutek_dcam_fullNow   = _full;
    [_eff] call crutek_fnc_dcamVision;

    diag_log format [
        "[crutek_dcam] modo %1 | ricetta A3TI %2 | dialogo %3 | A3TI rilevata %4 | operatore %5 | stringa A3TI '%6'",
        _eff, _full,
        (crutek_dcam_overlayOn != "") && {[crutek_dcam_overlayOn] call cTab_fnc_isDialog},
        crutek_dcam_hasA3TI,
        crutek_dcam_hasOp,
        ((crutek_dcam_uav getVariable ["crutek_dcam_view", []]) param [1, ""])
    ];
};
