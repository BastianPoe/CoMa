<?php
error_reporting(E_ERROR);

$_CONFIG["Zutaten"] = 12;

$_CONFIG["ZutatenLength"] = 20;
$_CONFIG["CocktailLength"] = 28;
$_CONFIG["DetailLength"] = 25;

$_CONFIG["ConfigDir"] = "./configs";


session_start();

require ('./xajax/xajax.inc.php');

$xajax = new xajax(); 

$xajax->registerFunction("ResetData");
$xajax->registerFunction("Abort");

$xajax->registerFunction("EditZutaten");
$xajax->registerFunction("SaveZutaten");

$xajax->registerFunction("AddCocktail");
$xajax->registerFunction("EditCocktail");
$xajax->registerFunction("SaveCocktail");
$xajax->registerFunction("DeleteCocktail");

$xajax->registerFunction("Import");
$xajax->registerFunction("ImportAsk");
$xajax->registerFunction("ImportDo");

$xajax->registerFunction("LoadSave");
$xajax->registerFunction("SaveConfig");
$xajax->registerFunction("LoadConfig");


$xajax->processRequests();

function ResetData($confirm = 0) {
    $objResponse = new xajaxResponse();
    
    if( $confirm == 1 ) {
        unset($_SESSION["Zutaten"], $_SESSION["Cocktails"]);
        $objResponse->addAssign("Zutaten", "innerHTML", ListZutaten());
        $objResponse->addAssign("Cocktails", "innerHTML", ListCocktails());
        $objResponse->addAssign("OutputForm", "Output.value", RenderOutput());

        // Das Cocktailform updaten
        $objResponse->call("EmptySelects");
        $objResponse->call("AddOptions", "", -1);
        
        for($h=1; $h<=$_CONFIG["Zutaten"]; $h++) {
            if( strlen($_SESSION["Zutaten"][$h-1]) > 0 ) {
                $objResponse->call("AddOptions", $_SESSION["Zutaten"][$h-1], $h-1);
            }
        }

    } else {
        $objResponse->confirmCommands(1, "Wollen Sie die aktuelle Konfiguration wirklich verwerfen?");
        $objResponse->call("xajax_ResetData", "1");
    }
                
    return $objResponse;
}

function Abort() {
	$objResponse = new xajaxResponse();

    $objResponse->addAssign("ZutatenDiv", "style.display", "none");
    $objResponse->addAssign("CocktailDiv", "style.display", "none");
    $objResponse->addAssign("ImportDiv", "style.display", "none");
    $objResponse->addAssign("LoadSaveDiv", "style.display", "none");
        
	return $objResponse;
}

function EditZutaten() {
    global $_CONFIG;
	$objResponse = new xajaxResponse();

    for($h=0; $h<$_CONFIG["Zutaten"]; $h++) {
        $objResponse->addAssign("ZutatenForm", "Zutat_".($h+1).".value", $_SESSION["Zutaten"][$h]);
    }

    $objResponse->addAssign("ZutatenDiv", "style.display", "block");
        
	return $objResponse;
}

function SaveZutaten($parms) {
    global $_CONFIG;
	$objResponse = new xajaxResponse();

    $Error = "";

    for($h=1; $h<=$_CONFIG["Zutaten"]; $h++) {
        $Key = "Zutat_" . $h;
        
        if( strlen($parms[$Key]) > $_CONFIG["ZutatenLength"] ) {
            $Error .= "Die Zutat " . $parms[$Key] . " hat zu viele Zeichen und wird abgeschnitten.\n";
            $_SESSION["Zutaten"][$h-1] = substr($parms[$Key], 0, $_CONFIG["ZutatenLength"]);
        } else {
            $_SESSION["Zutaten"][$h-1] = $parms[$Key];
        }
    }
    
    if( strlen($Error) > 0 ) {
        $objResponse->addAlert(trim($Error));
    }

    $objResponse->addAssign("ZutatenDiv", "style.display", "none");
    $objResponse->addAssign("Zutaten", "innerHTML", ListZutaten());
    $objResponse->addAssign("Cocktails", "innerHTML", ListCocktails());
    $objResponse->addAssign("OutputForm", "Output.value", RenderOutput());
    
    
    // Das Cocktailform updaten
    $objResponse->call("EmptySelects");
    $objResponse->call("AddOptions", "", -1);
    
    for($h=1; $h<=$_CONFIG["Zutaten"]; $h++) {
        if( strlen($_SESSION["Zutaten"][$h-1]) > 0 ) {
            $objResponse->call("AddOptions", $_SESSION["Zutaten"][$h-1], $h-1);
        }
    }
    
	return $objResponse;
}
    
function AddCocktail() {
    global $_CONFIG;
	$objResponse = new xajaxResponse();

    $objResponse->addAssign("CocktailDivHeading", "innerHTML", "<b>Cocktail hinzufügen</b>");
    $objResponse->addAssign("CocktailForm", "uid.value", "");
    $objResponse->addAssign("CocktailForm", "Name.value", "");
    $objResponse->addAssign("CocktailForm", "Details.value", "");

    for($h=1; $h<=$_CONFIG["Zutaten"]; $h++) {
        $objResponse->addAssign("CocktailForm", "Zutat_" . $h . ".value", "-1");
        $objResponse->addAssign("CocktailForm", "Menge_" . $h . ".value", "");
    }

    $objResponse->addAssign("CocktailDiv", "style.display", "block");
    
	return $objResponse;
}

function EditCocktail($uid) {
    global $_CONFIG;
	$objResponse = new xajaxResponse();

    $myIndex = -1;
    
    foreach($_SESSION["Cocktails"] as $Index => $Cocktail) {
        if( $Cocktail["Uid"] == $uid ) {
            $myIndex = $Index;
        }
    }
    
    if( $myIndex == -1 ) {
        $objResponse->addAlert("Fehler!!! \n" . print_r($_SESSION["Cocktails"], true));
        
        return $objResponse;
    }
    
    $objResponse->addAssign("CocktailDivHeading", "innerHTML", "<b>Cocktail bearbeiten</b>");
    $objResponse->addAssign("CocktailForm", "uid.value", $uid);
    $objResponse->addAssign("CocktailForm", "Name.value", $_SESSION["Cocktails"][$myIndex]["Name"]);
    $objResponse->addAssign("CocktailForm", "Details.value", $_SESSION["Cocktails"][$myIndex]["Details"]);

    for($h=1; $h<=$_CONFIG["Zutaten"]; $h++) {
        $objResponse->addAssign("CocktailForm", "Zutat_" . $h . ".value", "-1");
        $objResponse->addAssign("CocktailForm", "Menge_" . $h . ".value", "");
    }

    $h = 1;
    
    foreach($_SESSION["Cocktails"][$myIndex]["Rezept"] as $Zutat => $Menge) {
        $objResponse->addAssign("CocktailForm", "Zutat_" . $h . ".value", $Zutat);
        $objResponse->addAssign("CocktailForm", "Menge_" . $h . ".value", $Menge);
        $h++;
    }

    $objResponse->addAssign("CocktailDiv", "style.display", "block");
    
    return $objResponse;
}
   
        

function SaveCocktail($parms) {
    global $_CONFIG;
	$objResponse = new xajaxResponse();
    $Error = "";
    
    if( $parms["uid"] > 0 ) {
        $myIndex = -1;
        
        foreach($_SESSION["Cocktails"] as $Index => $Cocktail) {
            if( $parms["uid"] == $Cocktail["Uid"] ) {
                $myIndex = $Index;
            }
        }
        
        if( $myIndex == -1 ) {
            $objResponse->addAlert("Fehler!!! \n" . print_r($_SESSION["Cocktails"], true));
            
            return $objResponse;
        }
    } else {
        $myIndex = count($_SESSION["Cocktails"]);
    }            

    
    if( strlen($parms["Name"]) > $_CONFIG["CocktailLength"] ) {
        $Error .= "Der Name des Cocktails war zu lang und wurde abgeschnitten.\n";
        $_SESSION["Cocktails"][$myIndex]["Name"] = substr($parms["Name"], 0, $_CONFIG["CocktailLength"]);
    } else {
        $_SESSION["Cocktails"][$myIndex]["Name"] = $parms["Name"];
    }
    
    if( strlen($parms["Details"]) > $_CONFIG["DetailLength"] ) {
        $Error .= "Die Details waren zu lang und wurden abgeschnitten.\n";
        $_SESSION["Cocktails"][$myIndex]["Details"] = $parms["Details"];      
    } else {
        $_SESSION["Cocktails"][$myIndex]["Details"] = $parms["Details"];
    }
    unset($_SESSION["Cocktails"][$myIndex]["Rezept"]);
    
    if( strlen($Error) > 0 ) {
        $objResponse->addAlert(trim($Error));
    }

    for($h=1; $h<=$_CONFIG["Zutaten"]; $h++) {
        $Zutat = $parms["Zutat_".$h];
        $Menge = $parms["Menge_".$h];
        
        if( $Zutat != -1 && $Menge > 0 ) {
            $_SESSION["Cocktails"][$myIndex]["Rezept"][$Zutat] = $Menge;
        }
    }
    
    if( $parms["uid"] < 1 ) {
        if( count($_SESSION["Cocktails"]) > 0 ) {
            $newuid = 0;
            foreach($_SESSION["Cocktails"] as $Cocktail) {
                if( $Cocktail["Uid"] > $newuid ) {
                    $newuid = $Cocktail["Uid"];
                }
            }
            $newuid ++;
        } else {
            $newuid = 1;
        }
    } else {
        $newuid = $parms["uid"];
    }
    
    $_SESSION["Cocktails"][$myIndex]["Uid"] = $newuid;
        

    $objResponse->addAssign("CocktailDiv", "style.display", "none");
    $objResponse->addAssign("Cocktails", "innerHTML", ListCocktails());
    $objResponse->addAssign("OutputForm", "Output.value", RenderOutput());
    
	return $objResponse;
}

function DeleteCocktail($uid, $confirm = 0) {
	$objResponse = new xajaxResponse();

    if( $confirm != 1 ) {
        $objResponse->confirmCommands(1, "Wollen Sie den Cocktail wirklich endgültig löschen?");
        $objResponse->call("xajax_DeleteCocktail", $uid, 1);
    } else {
        $myIndex = -1;
        
        foreach($_SESSION["Cocktails"] as $Index => $Cocktail) {
            if( $Cocktail["Uid"] == $uid ) {
                $myIndex = $Index;
            }
        }
        
        unset($_SESSION["Cocktails"][$myIndex]);        
    
        $objResponse->addAssign("Cocktails", "innerHTML", ListCocktails());
        $objResponse->addAssign("OutputForm", "Output.value", RenderOutput());
    }
    
    return $objResponse;
}

function Import() {
	$objResponse = new xajaxResponse();
    
    $objResponse->addAssign("ImportForm", "Daten.value", "");
    $objResponse->addAssign("ImportDiv", "style.display", "block");
    
    return $objResponse;
}

function ImportAsk($parms) {
    $objResponse = new xajaxResponse();
    
    $objResponse->confirmCommands(1, "Wollen Sie wirklich diese Daten importieren und dabei die bisherige Konfiguration verwerfen?");
    $objResponse->call("xajax_ImportDo", $parms["Daten"]);
    
    return $objResponse;
}

function ImportDo($Daten) {
    global $_CONFIG;
    $objResponse = new xajaxResponse();
    
    ImportData($Daten);
    
    $objResponse->addAssign("ImportDiv", "style.display", "none");

    // Das Cocktailform updaten
    $objResponse->call("EmptySelects");
    $objResponse->call("AddOptions", "", -1);
    
    for($h=1; $h<=$_CONFIG["Zutaten"]; $h++) {
        if( strlen($_SESSION["Zutaten"][$h-1]) > 0 ) {
            $objResponse->call("AddOptions", $_SESSION["Zutaten"][$h-1], $h-1);
        }
    }
    
    $objResponse->addAssign("Zutaten", "innerHTML", ListZutaten());
    $objResponse->addAssign("Cocktails", "innerHTML", ListCocktails());
    $objResponse->addAssign("OutputForm", "Output.value", RenderOutput());
    
    return $objResponse;
}

function LoadSave() {
    global $_CONFIG;
    $objResponse = new xajaxResponse();

    $objResponse->addAssign("LoadSaveDiv", "style.display", "block");
    $objResponse->addAssign("loadDiv", "innerHTML", "verfügbare Konfigurationen: <br />".listConfigs());
    $objResponse->addAssign("SaveForm", "Filename.value", date("Y-m-d") . " - aktuelle Konfiguration");
    
    return $objResponse;
}

function SaveConfig($parms, $overwrite = false) {
    global $_CONFIG;
    $objResponse = new xajaxResponse();

    if( strlen($parms["Filename"]) == 0 ) {
        $objResponse->addAlert("Sie müssen einen Dateinamen angeben");
    } elseif( is_file($_CONFIG["ConfigDir"] . "/" . $parms["Filename"]) && !$overwrite ) {
        $objResponse->confirmCommands(1, "Eine Datei mit dem angegebenen Namen existiert bereits, wollen Sie diese überschreiben?");
        $objResponse->call("xajax_SaveConfig", $parms, true);
    } else {
        $fp = fopen($_CONFIG["ConfigDir"] . "/" . $parms["Filename"], "w");
        
        fputs($fp, RenderOutput());

        fclose($fp);

        $objResponse->addAssign("LoadSaveDiv", "style.display", "none");
    }

    return $objResponse;
}

function LoadConfig($Filename, $confirm = false) {
    global $_CONFIG;
    $objResponse = new xajaxResponse();
  
  
    if( ereg("[a-zA-Z0-9 -]+", $Filename) ) {
        if( $confirm == false ) {
            $objResponse->confirmCommands(1, "Wollen Sie diese Konfiguration wirklich laden und damit die aktuelle verwerfen?");
            $objResponse->call("xajax_LoadConfig", $Filename, true);
        } else {
            $fp = fopen($_CONFIG["ConfigDir"] . "/" . $Filename, "r");
            
            while($dat = fgets($fp, 1024)) {
                $Input .= $dat;
            }
            
            fclose($fp);
        
            $Return = ImportData($Input);
    
            $objResponse->addAssign("LoadSaveDiv", "style.display", "none");

            // Das Cocktailform updaten
            $objResponse->call("EmptySelects");
            $objResponse->call("AddOptions", "", -1);
            
            for($h=1; $h<=$_CONFIG["Zutaten"]; $h++) {
                if( strlen($_SESSION["Zutaten"][$h-1]) > 0 ) {
                    $objResponse->call("AddOptions", $_SESSION["Zutaten"][$h-1], $h-1);
                }
            }

            $objResponse->addAssign("Zutaten", "innerHTML", ListZutaten());
            $objResponse->addAssign("Cocktails", "innerHTML", ListCocktails());
            $objResponse->addAssign("OutputForm", "Output.value", RenderOutput());
        }
    } 
    
    return $objResponse;
}        

?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="de" lang="de">
<head>
    <script type="text/javascript">
        function EmptySelects() {
            <?
            for($h=1; $h<=$_CONFIG["Zutaten"]; $h++) {
                echo 'EmptySelect(document.CocktailForm.Zutat_' . $h . '); ';
            }
            ?>
        }  
        
        function EmptySelect(object) {
            while( object.length > 0 ) {
                object.options[0] = null;
            }
        }

        function AddOptions(option, value) {
            <?
            for($h=1; $h<=$_CONFIG["Zutaten"]; $h++) {
                echo 'AddOption(document.CocktailForm.Zutat_' . $h . ', option, value); ';
            }
            ?>
        }        
        
        function AddOption(object, option, value) {
            NeuerEintrag = new Option(option, value, false, true);
            object.options[object.length] = NeuerEintrag;
        }
    
    </script>

	<?php $xajax->printJavascript('./xajax/'); ?>
    <link href="style.css" rel="stylesheet" type="text/css" />
    <meta http-equiv="Content-Type" content="text/html;charset=utf-8" />
</head>
<body>
<div class="Info">
    <h3>CoMa Cocktaileingabe</h3>
    
    Optionen: <input type=button onClick="xajax_Import();" value="Daten aus Basic importieren"> <input type=button onClick="xajax_ResetData();" value="aktuelle Konfiguration löschen"> <input type=button onClick="xajax_LoadSave();" value="Konfiguration laden/speichern">
</div>
&nbsp;<br />

<div class="Info" id="Zutaten">
    <? echo ListZutaten(); ?>
</div>
&nbsp; <br />

<div class="Info" id="Cocktails">
    <? echo ListCocktails(); ?>
</div>
&nbsp; <br />

<div class="Info">  
    <b>Die Ausgabe ist:</b><br />
    <form name="OutputForm" id="OutputForm">
        <textarea name="Output" cols=100 rows=20><? echo RenderOutput(); ?></textarea>
    </form>
</div>

<div id="ZutatenDiv" class="overlaydiv">
    <b>Zutaten</b>
    <form name="ZutatenForm" id="ZutatenForm" onsubmit="xajax_SaveZutaten(xajax.getFormValues('ZutatenForm')); return false;" method="post">
    <table border=0>
    <?
    for($h=1; $h<=$_CONFIG["Zutaten"]; $h++) {
        ?>
        <tr>
            <td><? echo $h; ?></td>
            <td><input name="Zutat_<? echo $h; ?>" size=50 maxlength="<? echo $_CONFIG["ZutatenLength"]; ?>"></td>
        </tr>
        <?
    }
    ?>
    <tr>
        <td colspan=2 align=center><input type=submit value="Speichern"> <input type=button onClick="xajax_Abort();" value="Abbrechen"></td>
    </tr>
    </table>
    </form>
</div>

<div id="CocktailDiv" class="overlaydiv">
    <div id="CocktailDivHeading">Überschrift</div>
    <form name="CocktailForm" id="CocktailForm" onsubmit="xajax_SaveCocktail(xajax.getFormValues('CocktailForm')); return false;" method="post">
    <input type="hidden" name="uid" value="-1">
    <table border=0>
    
    <tr>
        <td>Name:</td>
        <td><input name="Name" size=50 maxlength="<? echo $_CONFIG["CocktailLength"]; ?>"></td>
    </tr>
    
    <tr>
        <td>Details:</td>
        <td><input name="Details" size=50 maxlength="<? echo $_CONFIG["DetailLength"]; ?>"></td>
    </tr>
    
    <?
    for($h=1; $h<=$_CONFIG["Zutaten"]; $h++) {
        ?>
        <tr>
            <td><select name="Zutat_<? echo $h; ?>" size=1>
                <option value="-1"></option>
                <?
                foreach($_SESSION["Zutaten"] as $Index => $Zutat) {
                    ?>
                    <option value="<? echo $Index; ?>"><? echo $Zutat; ?></option>
                    <?
                }
                ?></td>
            <td><input name="Menge_<? echo $h; ?>" size=4> ml</td>
        </tr>
        <?
    }
    ?>    
    
    <tr>
        <td colspan=2 align=center><input type=submit value="Speichern"> <input type=button onClick="xajax_Abort();" value="Abbrechen"></td>
    </tr>
    </table>
    </form>
</div>

<div id="ImportDiv" class="overlaydiv">
    <b>Daten aus Basic importieren</b>
    <form name="ImportForm" id="ImportForm" onsubmit="xajax_ImportAsk(xajax.getFormValues('ImportForm')); return false;" method="post">

    <table>
    
    <tr>
        <td>Daten:</td>
        <td><textarea name="Daten" rows=10 cols=50></textarea></td>
    </tr>
    
    <tr>
        <td colspan=2 align=center><input type=submit value="OK"> <input type=button onClick="xajax_Abort();" value="Abbrechen"></td>
    </tr>
    </table>
    </form>
</div>

<div id="LoadSaveDiv" class="overlaydiv">
    <b>Konfigurationen laden / speichern</b><br />
    &nbsp; <br />
    
    <div id="loadDiv"></div>
    &nbsp; <br />
    
    <form name="SaveForm" id="SaveForm" onsubmit="xajax_SaveConfig(xajax.getFormValues('SaveForm')); return false;" method="post">
    <input name="Filename" size=40 maxlength=40 value="" /> <input type=submit value="Speichern">
    </form>
    
    <div style="text-align: center;">
        <input type=button onClick="xajax_Abort();" value="Abbrechen">
    </div>
</div>

</body>        
</html>
<?


function ListZutaten() {
    $String = '
        <b>Folgende Zutaten sind eingegeben:</b>
        <ul>';
    foreach($_SESSION["Zutaten"] as $Zutat) {
        if( strlen($Zutat) > 0 ) {
            $String .= "<li>" . $Zutat . "</li>";
        }
    }

    $String .= '
        </ul>
        <input type=button onCLick="xajax_EditZutaten()" value="Zutaten bearbeiten">';
    
    return $String;
}

function ListCocktails() {
    $String = '
        <b>Folgende Cocktails sind eingegeben:</b>
        <ul>';
        
    foreach($_SESSION["Cocktails"] as $Cocktail) {
        $String .= '
            <li>' . RenderCocktail($Cocktail) . '<br />
                <input type=button onClick="xajax_DeleteCocktail(' . $Cocktail["Uid"] . ');" value="Cocktail löschen">
                <input type=button onClick="xajax_EditCocktail(' . $Cocktail["Uid"] . ');" value="Cocktail bearbeiten"><br />&nbsp;</li>';
    }

    $String .= '
        </ul>
        <input type=button onClick="xajax_AddCocktail()" value="Cocktail hinzufügen">';
    
    return $String;
}
    
function RenderCocktail($Cocktail) {
    $Gesamt = 0;
    foreach($Cocktail["Rezept"] as $Zutat => $Menge) {
      $Gesamt += $Menge;
    }

    $String  = "<b>" . $Cocktail["Name"] . "</b> (" . $Cocktail["Details"] . ") [" . Mengendisplay($Gesamt) . "]<br />";
    $String .= "<ul>";
    
    foreach($Cocktail["Rezept"] as $Zutat => $Menge) {
        $String .= "<li>" . Mengendisplay($Menge) . "   " . $_SESSION["Zutaten"][$Zutat] . "</li>";
    }
    
    $String .= "</ul>";
    
    return $String;
}

function Mengendisplay($Menge) {
    if( $Menge < 10 ) {
        $Output = $Menge . " ml";
    } else {
        $Output = ($Menge / 10) . " cl";
    }
    
    return $Output;
}

function RenderOutput() {
    global $_CONFIG;
    
    $Output = "Zutaten: \nData \"\", ";
    
    for($h=1; $h<=$_CONFIG["Zutaten"]; $h++) {
        $Output .= "\"" . DisplayChars(trim($_SESSION["Zutaten"][$h-1])) . "\" , ";
    }
    
    $Output = substr($Output, 0, strlen($Output) - 2) . "\n\n";
    
    
    $Output .= "Namen: \nData ";

    foreach($_SESSION["Cocktails"] as $Cocktail) {
        $Output .= "\"" . StringLength(DisplayChars($Cocktail["Name"]), 27) . "\" , ";
    }
    
    if( count($_SESSION["Cocktails"]) > 0 ) {
        $Output = substr($Output, 0, strlen($Output) - 2) . "\n\n";
    } else {
        $Output .= "\n\n";
    }
    
    
    $Output .= "Kommentare: \nData ";
    
    foreach($_SESSION["Cocktails"] as $Cocktail) {
        $Output .= "\"" . StringLength(DisplayChars($Cocktail["Details"]), 24) . "\" , ";
    }

    if( count($_SESSION["Cocktails"]) > 0 ) {
        $Output = substr($Output, 0, strlen($Output) - 2) . "\n\n";
    } else {
        $Output .= "\n\n";
    }
    
    
    $Output .= "Mengen: \nData ";
    
    foreach($_SESSION["Cocktails"] as $Cocktail) {
        for($h=0; $h<$_CONFIG["Zutaten"]; $h++) {
            $Menge = $Cocktail["Rezept"][$h];
            
            if( $Menge < 1 ) {
                $Menge = 0;
            }
            
            $Output .= $Menge . "%, ";
        }
    }

    if( count($_SESSION["Cocktails"]) > 0 ) {
        $Output = substr($Output, 0, strlen($Output) - 2) . "\n\n";
    } else {
        $Output .= "\n\n";
    }
    
        
    return trim($Output);
}
    
    
    
function StringLength($String, $Len, $Fill = " ") {
    while( strlen($String) < $Len ) {
        $String .= $Fill;
    }
    
    $String = substr($String, 0, $Len);
    
    return $String;
}

function listConfigs() {
    global $_CONFIG;
    
    if( !isset($_CONFIG["ConfigDir"]) ) {
        return;
    }
    
    if( !is_dir($_CONFIG["ConfigDir"]) ) {
        mkdir($_CONFIG["ConfigDir"]);
    }
    
    $Output = "<ul>";
    
    $fp = opendir($_CONFIG["ConfigDir"]);
    
    while( $dat = readdir($fp) ) {
        if( $dat != "." && $dat != ".." ) {
            $Output .= "<li><input type=button onClick='xajax_LoadConfig(\"" . $dat . "\");' value='" . $dat . "'></li>\n";
            $Cnt ++;
        }
    }
    
    if( $Cnt == 0 ) {
        $Output .= "<li>momentan keine Konfigurationen vorhanden</li>";
    }
    
    closedir($fp);
    
    $Output .= "</ul>";
    
    return $Output;
}

function SanitizeSpecialChars($String) {
    $Drin = false;
    $DrinString = "";
    $Output = "";
    
    for($h=0; $h<strlen($String); $h++) {
        $Char = substr($String, $h, 1);
        
        if( $Char == "\"" ) {
            if( $Drin ) {
                $Drin = false;
                
                $Output .= str_replace(",", "KOMMA", $DrinString);
            } else {
                $Drin = true;
                $DrinString = "";
            }
        } else {
            if( $Drin ) {
                $DrinString .= $Char;
            } else {
                $Output .= $Char;
            }
        }
    }
    
    return $Output;
}     

function DisplayChars($String) {
    $Replaces = Array(   "ä" => "ae",
                        "ö" => "oe",
                        "ü" => "ue",
                        "ß" => "ss",
                        "Ä" => "Ae",
                        "Ö" => "Oe",
                        "Ü" => "Ue");
    
    foreach($Replaces as $Search => $Replace) {
        $String = str_replace($Search, $Replace, $String);
    }
    
    for($h=0; $h<strlen($String); $h++) {
        $Char = substr($String, $h, 1);
        
        if( ereg("[a-zA-Z0-9 ,\(\).-]", $Char) ) {
            $Output .= $Char;
        }
    }
    
    return $Output;
}      

function ImportData($Daten) {
    global $_CONFIG;
    
    $Daten = str_replace("\r\n",  "\n", stripslashes($Daten));
    
    $Zeilen = explode("\n", $Daten);
    
    foreach($Zeilen as $Index => $Zeile) {
        if( strlen(trim($Zeile)) == 0 || substr($Zeile, 0, 1) == "'" ) {
            unset($Zeilen[$Index]);
        } else {
            $Zeilen[$Index] = trim($Zeile);
        }
    }
    
    foreach($Zeilen as $Index => $Zeile) {
        if( eregi("([a-zA-Z]+)\:", $Zeile, $out) ) {
            $myZeile = $Zeilen[$Index + 1];
            
            $myZeile = trim(substr($myZeile, 4, strlen($myZeile)));
            
            $Data[$out[1]] = $myZeile;
        }
    }

    $Data["Mengen"] = str_replace("%", "", $Data["Mengen"]);
    $Data["Namen"] = str_replace("\"", "", $Data["Namen"]);
    $Data["Zutaten"] = str_replace("\"", "", $Data["Zutaten"]);
    $Data["Kommentare"] = str_replace("\"", "", SanitizeSpecialChars($Data["Kommentare"]));


    unset($_SESSION["Zutaten"], $_SESSION["Cocktails"]);
    
    $Zutaten = explode(",", $Data["Zutaten"]);
    for($h=1; $h<=$_CONFIG["Zutaten"]; $h++) {
        $_SESSION["Zutaten"][$h-1] = trim($Zutaten[$h]);
    }
    
    $Namen = explode(",", $Data["Namen"]);
    $Details = explode(",", $Data["Kommentare"]);
    $Mengen = explode(",", $Data["Mengen"]);
    
    foreach($Namen as $Index => $Name) {
        if( strlen($Name) > 0 ) {
            $Cocktail = Array(  "Name" => trim($Name),
                                "Details" => str_replace("KOMMA", ",", trim($Details[$Index])),
                                "Uid" => $Index + 1,
                                "Rezept" => Array());
            
            for($h=0; $h<$_CONFIG["Zutaten"]; $h++) {
                $Menge = trim($Mengen[12 * $Index + $h]);
                if( $Menge > 0 ) {
                    $Cocktail["Rezept"][$h] = $Menge;
                }
            }
            $_SESSION["Cocktails"][] = $Cocktail;
        }
    }
}
