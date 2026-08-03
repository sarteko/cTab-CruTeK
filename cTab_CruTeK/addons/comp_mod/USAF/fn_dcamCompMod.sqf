/*
    crutek_fnc_dcamCompMod
    Dice se un mezzo appartiene a un mod per cui esiste un profilo di
    compatibilita, e se quel profilo e acceso nelle opzioni.

    PERCHE UN PROFILO E NON UNA REGOLA UNICA.

    Le regole normali del feed sono tarate sui mezzi di serie, dove la torretta
    principale dichiara primaryGunner e il pod di puntamento e la vista del
    pilota. Diversi mod di aerei e mezzi non seguono quella convenzione: un
    AC-130U ha sette postazioni, nessuna dichiarata primaria, i cannoni su una
    sola e il pod del pilota che con il puntamento non c'entra niente.

    Allargare le regole per tutti farebbe cambiare comportamento anche ai mezzi
    di serie, che oggi funzionano. Ogni profilo e quindi separato e si accende
    da solo, dalla sezione delle opzioni degli addon.

    Per aggiungere un mod basta una riga nella tabella qui sotto piu la
    relativa impostazione in dcamSettings: identificativo, nome della variabile
    che lo accende, elenco dei prefissi da riconoscere.

    Il riconoscimento guarda in due posti. Prima il nome di classe del mezzo,
    che nella pratica quasi sempre porta il prefisso del mod; poi gli addon che
    dichiarano quella classe, letti con configSourceAddonList, che e la strada
    buona anche quando i nomi di classe non seguono nessuna regola.

    0: OBJECT - il mezzo
    Ritorna: STRING - identificativo del profilo attivo, vuoto se nessuno
*/

params [["_veh", objNull]];
if (isNull _veh) exitWith { "" };

private _profili = [
    ["USAF", "crutek_dcam_compUSAF", ["USAF_"]]
];

private _tipo  = toUpper (typeOf _veh);
private _addon = configSourceAddonList (configFile >> "CfgVehicles" >> typeOf _veh);
if !(_addon isEqualType []) then { _addon = [] };
_addon = _addon apply { toUpper _x };

private _res = "";

{
    _x params ["_id", "_var", "_prefissi"];

    if (missionNamespace getVariable [_var, false]) then {
        private _pref = _prefissi apply { toUpper _x };

        private _hit = (_pref findIf { (_tipo find _x) isEqualTo 0 }) >= 0;

        if (!_hit) then {
            {
                private _nome = _x;
                if ((_pref findIf { (_nome find _x) isEqualTo 0 }) >= 0) exitWith { _hit = true };
            } forEach _addon;
        };

        if (_hit) exitWith { _res = _id };
    };
} forEach _profili;

_res
