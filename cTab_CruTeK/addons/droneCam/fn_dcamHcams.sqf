/*
    crutek_fnc_dcamHcams
    Unita con la telecamera da casco: elmetti che ne includono una, oppure
    ItemcTabHCam in inventario. Stesso filtro che usa cTab per il tablet.

    Ritorna: ARRAY di OBJECT, ordinati per distanza
*/

/*
    Fazioni, distanza e requisito player o IA vengono dalla sezione HelmetCam
    delle opzioni: sono limiti loro, distinti da quelli dei mezzi. Vedere
    dagli occhi di un compagno e una capacita diversa dal guardare in una
    torretta, e va poter essere regolata a parte.
*/
private _sides = [];
if (crutek_dcam_hcamSideOwn)  then { _sides pushBackUnique (side group player) };
if (crutek_dcam_hcamSideWest) then { _sides pushBackUnique west };
if (crutek_dcam_hcamSideEast) then { _sides pushBackUnique east };
if (crutek_dcam_hcamSideGuer) then { _sides pushBackUnique resistance };
if (crutek_dcam_hcamSideCiv)  then { _sides pushBackUnique civilian };

// a 0 nessun limite di distanza, non zero metri
private _lim = crutek_dcam_hcamMaxDist;
if (_lim <= 0) then { _lim = 1e10 };

private _list = allUnits select {
    alive _x
    && {_x != player}
    && {(player distance _x) <= _lim}
    && {(side group _x) in _sides}
    && {!(_x getVariable ["crutek_dcam_blocked", false])}
    // 0 player o IA, 1 solo player, 2 solo IA
    && {
        (crutek_dcam_hcamWho isEqualTo 0)
        || {(crutek_dcam_hcamWho isEqualTo 1) && {isPlayer _x}}
        || {(crutek_dcam_hcamWho isEqualTo 2) && {!(isPlayer _x)}}
    }
    /*
        L'oggetto richiesto e configurabile. Lasciandolo vuoto resta solo il
        controllo sull'elmetto, cosi una missione puo decidere che la cam ce
        l'ha chi indossa il casco giusto invece di chi porta un oggetto.
    */
    && {
        (!isNil "cTab_helmetClass_has_HCam" && {(headgear _x) in cTab_helmetClass_has_HCam})
        || {
            (crutek_dcam_hcamItem != "")
            && {[_x, [crutek_dcam_hcamItem]] call crutek_fnc_dcamHasItem}
        }
    }
};

private _out = [];
{
    private _u   = _x;
    private _d   = player distance _u;
    private _idx = _out findIf { (player distance _x) > _d };
    if (_idx < 0) then { _out pushBack _u } else { _out insert [_idx, [_u]] };
} forEach _list;

_out
