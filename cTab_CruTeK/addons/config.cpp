/*
	cTab CruTeK - Camera
	Feed remoto delle torrette e delle helmet cam sul Galaxy di cTab.

	NIENTE macro e niente #include, e non e una svista.

	La versione con lo stile a componente CBA non parte se impacchettata con
	PBO Manager: quel packer il prefisso nell'header non lo scrive, e tutti i
	percorsi \z\ctab\addons\camera\... restano senza risposta - da qui
	l'errore "Script ... not found" all'avvio.

	Questa versione ricalca invece la struttura del cTab CruTeK che con quel
	packer funzionava: prefisso semplice nel file $prefix$, funzioni caricate
	con CfgFunctions, percorsi che partono da \ctab_camera\.

	Resta comunque un pbo a se: dichiara la propria classe, dipende dai loro
	e non sovrascrive niente di cTAB Advanced.
*/
class CfgPatches
{
	class ctab_camera
	{
		name="cTab CruTeK - Camera";
		units[]={};
		weapons[]={};
		requiredVersion=2.02;
		/*
			Il pbo delle schermate si chiama ctab_cTab.pbo ma la classe che
			dichiara e "ctab": qui vanno i nomi delle CLASSI, non dei file.
		*/
		requiredAddons[]=
		{
			"ctab_main",
			"ctab_core",
			"ctab",
			"ace_interact_menu"
		};
		author="ArTeK & Cruiser";
		version=1.0;
		versionStr="1.0";
		versionAr[]={1,0,0,0};
	};
};
class cfgFunctions
{
	class crutek
	{
		class droneCam
		{
			file="ctab_camera\droneCam";
			class dcamApplyFov
			{
			};
			class dcamClick
			{
			};
			class dcamClose
			{
			};
			class dcamCrop
			{
			};
			class dcamCycle
			{
			};
			class dcamDiag
			{
			};
			class dcamDrag
			{
			};
			class dcamFov
			{
			};
			class dcamFrame
			{
			};
			class dcamHasItem
			{
			};
			class dcamHcams
			{
			};
			class dcamHud
			{
			};
			class dcamInit
			{
				postInit=1;
			};
			class dcamInput
			{
			};
			class dcamList
			{
			};
			class dcamName
			{
			};
			class dcamNext
			{
			};
			class dcamNotify
			{
			};
			class dcamOpen
			{
			};
			class dcamOperator
			{
			};
			class dcamOverlay
			{
			};
			class dcamPhonePos
			{
			};
			class dcamPublish
			{
			};
			class dcamRefresh
			{
			};
			class dcamSettings
			{
			};
			class dcamSide
			{
			};
			class dcamToggle
			{
			};
			class dcamTurret
			{
			};
			class dcamVision
			{
			};
			class dcamWheel
			{
			};
			class dcamWorld
			{
			};
		};
	};
};
class Extended_PreInit_EventHandlers
{
	class ctab_camera
	{
		/*
			Le impostazioni si registrano in preInit, prima che CBA legga i
			valori salvati nello scenario.
		*/
		init="call compile preprocessFileLineNumbers '\ctab_camera\droneCam\fn_dcamSettings.sqf'";
	};
};
class Extended_DisplayLoad_EventHandlers
{
	class RscDisplayArsenal
	{
		ctab_camera="if (crutek_dcam_active) then { call crutek_fnc_dcamClose };";
	};
	class ace_arsenal_display
	{
		ctab_camera="if (crutek_dcam_active) then { call crutek_fnc_dcamClose };";
	};
	class RscDisplayGarage
	{
		ctab_camera="if (crutek_dcam_active) then { call crutek_fnc_dcamClose };";
	};
	class RscDisplayCurator
	{
		ctab_camera="if (crutek_dcam_active) then { call crutek_fnc_dcamClose };";
	};
};
