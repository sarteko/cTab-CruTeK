/*
    crutek_fnc_dcamVision
    Applica un modo al render target.

    IL RENDER TARGET TIENE UN EFFETTO SOLO: VINCE L'ULTIMA CHIAMATA.

    Questa e la conclusione, pagata con parecchi giri a vuoto. Non si possono
    sovrapporre gradazioni al modo base: qualunque setPiPEffect successivo lo
    SOSTITUISCE, non ci si somma. Le prove:

    - applicando una correzione colore dopo il modo termico, la termica
      spariva e restava un'immagine diurna in scala di grigi. Sembrava
      plausibile e per questo non me ne ero accorto subito
    - la stessa cosa con la correzione invertita dava un'immagine diurna
      rovesciata, cioe quasi nera: era il famoso "schermo nero"
    - una chiamata di spegnimento messa DOPO il modo notturno cancellava il
      notturno e lasciava l'immagine a colori

    Di conseguenza sono fuori portata sia il contrasto in piu sulle termiche
    sia il nero caldo (che richiederebbe una inversione), e la resa di A3TI
    a maggior ragione, visto che le servono i pesi colore.

    Resta una sola chiamata utile: il modo base. La correzione colore e
    appiccicosa, quindi va spenta PRIMA, mai dopo.

    0: STRING - "DTV", "NVG", "THERM1", "THERM2"
*/

params [["_mode", "DTV"]];
private _rt = crutek_dcam_rt;

// spegnimento di un'eventuale correzione rimasta appesa, sempre e solo prima
_rt setPiPEffect [3, 0, 1, 1, 0, [0,0,0,0], [1,1,1,0], [0.299,0.587,0.114,0]];

// modo base: 0 normale, 1 notturno, 2 termico. Ultima chiamata, non si tocca
// piu niente dopo questa riga
private _i    = crutek_dcam_baseFx find _mode;
private _base = if (_i >= 0) then { crutek_dcam_baseFx select (_i + 1) } else { 0 };

/*
    Lista COMPLETA, non il solo numero.

    Le termiche vogliono tutti i parametri: passando solo l'indice il motore
    risponde "1 elemento fornito, 5 attesi", l'effetto non viene applicato e
    resta quello di prima. E' il motivo per cui THERM1 e THERM2 sembravano non
    fare niente anche dopo essere state messe in tabella.
*/
/*
    Bianco caldo e nero caldo sono lo STESSO effetto: cambia solo l'ordine dei
    due colori. Il primo e' il freddo, il secondo il caldo. Scambiandoli la
    scala si ribalta, e si ottiene il nero caldo senza bisogno di un modo
    diverso ne' di sovrapporre una inversione, che tanto non si potrebbe.
*/
/*
    Bianco caldo e nero caldo sono due EFFETTI diversi, il 2 e il 7, non lo
    stesso con i colori scambiati: su un effetto termico il motore usa la sua
    palette e i due colori passati vengono ignorati. Provato a schermo.
*/
_rt setPiPEffect [_base, 0, 1, 1, 0, [0,0,0,0], [1,1,1,0], [0.299,0.587,0.114,0]];

if (crutek_dcam_debug) then {
    diag_log format ["[crutek_dcam] vision %1 | base %2", _mode, _base];
};
