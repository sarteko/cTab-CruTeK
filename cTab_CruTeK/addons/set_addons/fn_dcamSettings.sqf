/*
    crutek_fnc_dcamSettings
    Registra le impostazioni della Cam on Galaxy nelle opzioni degli addon.

    VIENE CHIAMATA DALL'EVENTO preInit DI CBA, non da CfgFunctions.

    E' la differenza fra funzionare e non comparire affatto: il preInit di
    CfgFunctions gira dentro l'inizializzazione di Bohemia, che avviene DOPO
    che CBA ha gia costruito il menu delle impostazioni. Registrate li, le
    voci arrivano a menu chiuso e non si vedono da nessuna parte.

    L'aggancio sta nel config, in Extended_PreInit_EventHandlers.

    Tutte GLOBALI (isGlobal true): si impostano per scenario dall'editor,
    schede SERVER e MISSIONE, e valgono uguali per tutti in partita. E' quello
    che serve per avere configurazioni diverse da missione a missione.

    ATTENZIONE: i nomi qui sotto diventano variabili globali vere. Nessun
    altro file deve assegnarle, o sovrascriverebbe la scelta della missione.
*/

/*
    La categoria e una coppia: il primo elemento e la voce nella tendina degli
    addon, il secondo l'intestazione di sezione dentro la pagina. Cambiando
    solo il secondo si ottengono piu sezioni sotto la stessa voce, che e come
    sono fatte le opzioni di SSS e di ACE.
*/
#define CAT_FAZIONI   [localize "STR_crutek_dcam_cat_main", localize "STR_crutek_dcam_sec_fazioni"]
#define CAT_MEZZI     [localize "STR_crutek_dcam_cat_main", localize "STR_crutek_dcam_sec_mezzi"]
#define CAT_BORDO     [localize "STR_crutek_dcam_cat_main", localize "STR_crutek_dcam_sec_bordo"]
#define CAT_LIMITI    [localize "STR_crutek_dcam_cat_main", localize "STR_crutek_dcam_sec_limiti"]
#define CAT_MISC      [localize "STR_crutek_dcam_cat_main", localize "STR_crutek_dcam_sec_misc"]

/*
    Categoria a se per i droni. Non e pignoleria: su un drone chi lo comanda
    sta al TERMINALE, non a bordo, quindi il filtro "chi deve essere a bordo"
    dei mezzi con equipaggio li non significa niente. E sono anche gli unici
    su cui si puo brandeggiare la torretta. Tenerli separati permette di
    dosarli senza toccare i mezzi con equipaggio.
*/
#define CAT_DR_FAZ    [localize "STR_crutek_dcam_cat_dr", localize "STR_crutek_dcam_sec_fazioni"]
#define CAT_DR_LIM    [localize "STR_crutek_dcam_cat_dr", localize "STR_crutek_dcam_sec_hc_lim"]

/*
    Categoria a se per la compatibilita con i mod di terze parti. Sta fuori
    dalle altre di proposito: non e una regola di missione ma una dichiarazione
    su COME e fatto un mod, e va spenta se quel mod non e caricato o se il suo
    profilo dovesse dare fastidio.
*/
#define CAT_COMP      [localize "STR_crutek_dcam_cat_comp", localize "STR_crutek_dcam_sec_comp"]

// categoria a se: la helmet cam e una capacita diversa, con i suoi limiti
#define CAT_HC_FAZ    [localize "STR_crutek_dcam_cat_hc", localize "STR_crutek_dcam_sec_fazioni"]
#define CAT_HC_LIM    [localize "STR_crutek_dcam_cat_hc", localize "STR_crutek_dcam_sec_hc_lim"]

private _fnc_si = {
    params ["_nome", "_titolo", "_aiuto", "_def", "_sez"];
    [_nome, "CHECKBOX", [_titolo, _aiuto], _sez, _def, true, {}, false] call CBA_fnc_addSetting;
};

/*
    La casella accanto al cursore accetta il numero scritto a mano, ma un
    valore fuori dal minimo o dal massimo viene riportato dentro.

    Le distanze di OSSERVAZIONE arrivano a 100000, cioe di fatto senza tetto:
    decidere fin dove si puo guardare e una scelta di missione.

    Le distanze di DISEGNO si fermano a 12000. Li il tetto ha un senso: oltre
    una certa soglia si paga in prestazioni senza vedere niente di piu, e il
    feed resta acceso finche il telefono e a schermo.
*/
private _fnc_num = {
    params ["_nome", "_titolo", "_aiuto", "_min", "_max", "_def", "_dec", "_sez"];
    [_nome, "SLIDER", [_titolo, _aiuto], _sez, [_min, _max, _def, _dec], true, {}, false] call CBA_fnc_addSetting;
};

// ---- chi si puo osservare ----------------------------------------
["crutek_dcam_sideOwn", localize "STR_crutek_dcam_set_sideOwn", localize "STR_crutek_dcam_set_sideOwn_t",
    true, CAT_FAZIONI] call _fnc_si;

["crutek_dcam_sideWest", localize "STR_crutek_dcam_set_sideWest", "", true, CAT_FAZIONI] call _fnc_si;
["crutek_dcam_sideEast", localize "STR_crutek_dcam_set_sideEast", "", false, CAT_FAZIONI] call _fnc_si;
["crutek_dcam_sideGuer", localize "STR_crutek_dcam_set_sideGuer", "", false, CAT_FAZIONI] call _fnc_si;
["crutek_dcam_sideCiv",  localize "STR_crutek_dcam_set_sideCiv", "", true, CAT_FAZIONI] call _fnc_si;

// ---- cosa si puo osservare ---------------------------------------
["crutek_dcam_catAir",  localize "STR_crutek_dcam_set_catAir", localize "STR_crutek_dcam_set_catAir_t", true, CAT_MEZZI] call _fnc_si;
["crutek_dcam_catLand", localize "STR_crutek_dcam_set_catLand", localize "STR_crutek_dcam_set_catLand_t", true, CAT_MEZZI] call _fnc_si;
["crutek_dcam_catSea",  localize "STR_crutek_dcam_set_catSea", localize "STR_crutek_dcam_set_catSea_t", true, CAT_MEZZI] call _fnc_si;


// ---- droni -------------------------------------------------------
["crutek_dcam_droneOn", localize "STR_crutek_dcam_set_drOn", localize "STR_crutek_dcam_set_drOn_t",
    true, CAT_DR_LIM] call _fnc_si;

/*
    Distanza di visuale col feed di un drone aperto. Ha la precedenza su
    quella della categoria: un drone in quota guarda molto piu' lontano di un
    mezzo con equipaggio della stessa famiglia. A 0 vale quella di categoria.
*/
["crutek_dcam_vdDrone", localize "STR_crutek_dcam_set_vd_drone", localize "STR_crutek_dcam_set_vd_drone_t",
    0, 12000, 0, 0, CAT_DR_LIM] call _fnc_num;

/*
    Chi comanda il drone: 0 player o IA, 1 solo player, 2 solo IA.
    Si guarda chi e COLLEGATO col terminale, non l'equipaggio: quello di un
    drone e sempre IA, anche mentre lo piloti tu.
*/
[
    "crutek_dcam_droneWho",
    "LIST",
    [localize "STR_crutek_dcam_set_drWho", localize "STR_crutek_dcam_set_drWho_t"],
    CAT_DR_LIM,
    [[0, 1, 2], [localize "STR_crutek_dcam_set_crew_0", localize "STR_crutek_dcam_set_crew_1", localize "STR_crutek_dcam_set_crew_2"], 0],
    true,
    {},
    false
] call CBA_fnc_addSetting;

["crutek_dcam_allowDrag", localize "STR_crutek_dcam_set_drag", localize "STR_crutek_dcam_set_drag_t",
    true, CAT_DR_LIM] call _fnc_si;

["crutek_dcam_droneMaxDist", localize "STR_crutek_dcam_set_maxDist", localize "STR_crutek_dcam_set_maxDist_t",
    0, 100000, 6000, 0, CAT_DR_LIM] call _fnc_num;

["crutek_dcam_droneSideOwn",  localize "STR_crutek_dcam_set_sideOwn", localize "STR_crutek_dcam_set_sideOwn_t", true,  CAT_DR_FAZ] call _fnc_si;
["crutek_dcam_droneSideWest", localize "STR_crutek_dcam_set_sideWest", "", true,  CAT_DR_FAZ] call _fnc_si;
["crutek_dcam_droneSideEast", localize "STR_crutek_dcam_set_sideEast", "", false, CAT_DR_FAZ] call _fnc_si;
["crutek_dcam_droneSideGuer", localize "STR_crutek_dcam_set_sideGuer", "", false, CAT_DR_FAZ] call _fnc_si;
["crutek_dcam_droneSideCiv",  localize "STR_crutek_dcam_set_sideCiv", "", true,  CAT_DR_FAZ] call _fnc_si;



// ---- helmet cam --------------------------------------------------
["crutek_dcam_catOpCam", localize "STR_crutek_dcam_set_hcOn", localize "STR_crutek_dcam_set_hcOn_t",
    true, CAT_HC_LIM] call _fnc_si;

/*
    Distanza di visuale minima col feed acceso, per la helmet cam.
    Stessa logica di quella dei mezzi ma valore suo: una camera da casco sta a
    terra e non ha bisogno degli stessi chilometri di un drone in quota.
*/
["crutek_dcam_hcViewDist", localize "STR_crutek_dcam_set_hcViewDist", localize "STR_crutek_dcam_set_hcViewDist_t",
    0, 12000, 0, 0, CAT_HC_LIM] call _fnc_num;

[
    "crutek_dcam_hcamItem",
    "EDITBOX",
    [localize "STR_crutek_dcam_set_hcItem", localize "STR_crutek_dcam_set_hcItem_t"],
    CAT_HC_LIM,
    "ItemcTabHCam",
    true,
    {},
    false
] call CBA_fnc_addSetting;

["crutek_dcam_hcamMaxDist", localize "STR_crutek_dcam_set_hcDist", localize "STR_crutek_dcam_set_hcDist_t",
    0, 100000, 2000, 0, CAT_HC_LIM] call _fnc_num;

/*
    0 player o IA, 1 solo player, 2 solo IA.

    Non c'e "nessuno": una helmet cam senza qualcuno che la porta non esiste.
*/
[
    "crutek_dcam_hcamWho",
    "LIST",
    [localize "STR_crutek_dcam_set_hcWho", localize "STR_crutek_dcam_set_hcWho_t"],
    CAT_HC_LIM,
    [[0, 1, 2], [localize "STR_crutek_dcam_set_hcWho_0", localize "STR_crutek_dcam_set_hcWho_1", localize "STR_crutek_dcam_set_hcWho_2"], 0],
    true,
    {},
    false
] call CBA_fnc_addSetting;

["crutek_dcam_hcamSideOwn",  localize "STR_crutek_dcam_set_sideOwn", "", true,  CAT_HC_FAZ] call _fnc_si;
["crutek_dcam_hcamSideWest", localize "STR_crutek_dcam_set_sideWest", "", true,  CAT_HC_FAZ] call _fnc_si;
["crutek_dcam_hcamSideEast", localize "STR_crutek_dcam_set_sideEast", "", false, CAT_HC_FAZ] call _fnc_si;
["crutek_dcam_hcamSideGuer", localize "STR_crutek_dcam_set_sideGuer", "", false, CAT_HC_FAZ] call _fnc_si;
["crutek_dcam_hcamSideCiv",  localize "STR_crutek_dcam_set_sideCiv", "", false, CAT_HC_FAZ] call _fnc_si;

// ---- chi deve essere a bordo -------------------------------------
/*
    0  player o IA      1  solo player      2  solo IA      3  anche vuoti

    Un mezzo vuoto non ha nessuno che ne punti la torretta, quindi il suo
    feed guarda dove capita: e il motivo per cui "anche vuoti" non e il
    default.
*/
["crutek_dcam_gunnerOnly", localize "STR_crutek_dcam_set_gunnerOnly", localize "STR_crutek_dcam_set_gunnerOnly_t",
    true, CAT_BORDO] call _fnc_si;

[
    "crutek_dcam_crewMode",
    "LIST",
    [localize "STR_crutek_dcam_set_crew", localize "STR_crutek_dcam_set_crew_t"],
    CAT_BORDO,
    [[0, 1, 2, 3], [localize "STR_crutek_dcam_set_crew_0", localize "STR_crutek_dcam_set_crew_1", localize "STR_crutek_dcam_set_crew_2", localize "STR_crutek_dcam_set_crew_3"], 0],
    true,
    {},
    false
] call CBA_fnc_addSetting;

// ---- limiti di gioco ---------------------------------------------
["crutek_dcam_maxDist", localize "STR_crutek_dcam_set_maxDist", localize "STR_crutek_dcam_set_maxDist_t",
    0, 100000, 4000, 0, CAT_LIMITI] call _fnc_num;

/*
    Distanza visiva minima mentre un feed e acceso.

    0 = non toccare niente, ed e come il mod si comporta di serie.

    Con un valore, all'apertura del feed la distanza visiva viene portata
    almeno a quel numero e alla chiusura torna com'era. Serve quando il
    limitatore ACE tiene la visiva bassa per chi sta a piedi e il drone
    guarda a tre chilometri: la foschia da distanza mangia l'immagine.

    Due cose da sapere prima di usarla, perche non sono dettagli.

    La distanza visiva e UNA SOLA per tutto il rendering: alzandola per il
    feed si alza anche la tua vista reale, finche il feed resta aperto.

    E il limitatore ACE rimette il suo valore a ogni cambio di stato, per
    esempio quando sali o scendi da un mezzo. Il mod riafferma il proprio
    ogni due secondi, quindi vince, ma sono due mod che comandano lo stesso
    numero: se vi serve una cosa pulita, la strada giusta e alzare il valore
    ACE per chi fa da operatore droni.

    Non abbassa mai: se la tua visiva e gia piu alta, resta la tua.
*/
/*
    Un valore per categoria, senza un limitatore generale sopra di loro: un
    aereo in quota e una torretta a terra non hanno bisogno della stessa
    distanza, e un valore unico farebbe pagare a tutti quanto serve al piu'
    esigente. A 0 la categoria non tocca niente.
*/
/*
    I dispositivi che aprono il feed. Due caselle perche' i mezzi ne accettano
    due: il telefono e il tablet. Lasciando vuota la seconda vale solo la prima.
*/
[
    "crutek_dcam_item1", "EDITBOX",
    [localize "STR_crutek_dcam_set_item1", localize "STR_crutek_dcam_set_item1_t"],
    CAT_LIMITI, "ItemAndroid", true, {}, false
] call CBA_fnc_addSetting;

[
    "crutek_dcam_item2", "EDITBOX",
    [localize "STR_crutek_dcam_set_item2", localize "STR_crutek_dcam_set_item2_t"],
    CAT_LIMITI, "ItemcTab", true, {}, false
] call CBA_fnc_addSetting;

["crutek_dcam_vdAir", localize "STR_crutek_dcam_set_vd_air", localize "STR_crutek_dcam_set_vd_air_t",
    0, 12000, 0, 0, CAT_LIMITI] call _fnc_num;
["crutek_dcam_vdLand", localize "STR_crutek_dcam_set_vd_land", localize "STR_crutek_dcam_set_vd_land_t",
    0, 12000, 0, 0, CAT_LIMITI] call _fnc_num;
["crutek_dcam_vdSea", localize "STR_crutek_dcam_set_vd_sea", localize "STR_crutek_dcam_set_vd_sea_t",
    0, 12000, 0, 0, CAT_LIMITI] call _fnc_num;



["crutek_dcam_minAlt", localize "STR_crutek_dcam_set_minAlt", localize "STR_crutek_dcam_set_minAlt_t",
    -500, 5000, 0, 0, CAT_LIMITI] call _fnc_num;

// ---- compatibilita con i mod ---------------------------------------
["crutek_dcam_compUSAF", localize "STR_crutek_dcam_set_compUSAF", localize "STR_crutek_dcam_set_compUSAF_t",
    true, CAT_COMP] call _fnc_si;

/*
    Forma del menu ACE. Il menu di autointerazione si apre a raggiera, e piu
    e profondo l'albero piu i rami finiscono lontano dal cursore: basta uscire
    di poco e si richiude prima di arrivarci. Con "Breve" le postazioni salgono
    di un livello e si raggiungono con un movimento solo.
*/
[
    "crutek_dcam_menuMode",
    "LIST",
    [localize "STR_crutek_dcam_set_menuMode", localize "STR_crutek_dcam_set_menuMode_t"],
    CAT_MISC,
    [[0, 1], [localize "STR_crutek_dcam_set_menuMode_0", localize "STR_crutek_dcam_set_menuMode_1"], 0],
    true,
    {},
    false
] call CBA_fnc_addSetting;

// ---- varie, in fondo -----------------------------------------------

["crutek_dcam_itemMisc", localize "STR_crutek_dcam_set_itemMisc", localize "STR_crutek_dcam_set_itemMisc_t",
    true, CAT_MISC] call _fnc_si;

[
    "crutek_dcam_pos",
    "CHECKBOX",
    [localize "STR_crutek_dcam_set_pos", localize "STR_crutek_dcam_set_pos_t"],
    CAT_MISC,
    false,
    false,
    {},
    false
] call CBA_fnc_addSetting;

diag_log "[crutek_dcam] impostazioni registrate: cTab-Cam on Galaxy e cTab-HelmetCam";
