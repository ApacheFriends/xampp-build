<?php

    // Remove all warning messages
    error_reporting(E_ALL & ~E_DEPRECATED & ~E_STRICT & ~E_WARNING & ~E_NOTICE);
    $array = $slashrootreal = $backslashrootreal = $doublebackslashrootreal = array();

		/*
	#### Installer PHP  1.5 ####
	#### Author: Kay Vogelgesang & Carsten Wiedmann for www.apachefriends.org 2005 ####
	*/

	/// Where I stand? ///
	$curdir = getcwd();
  $usbstick="0";

  if ( $_SERVER["argv"][1] == "usb" ) {
            // echo   $_SERVER["argv"][1];
            $usbstick="1";
            echo "\r\n  ########################################################################\n";
	echo "  #                                                                      #\r\n";
	echo "  #                  XAMPP USB Stick Installation                        #\r\n";;
	echo "  #                                                                      #\r\n";
	echo "  ########################################################################\r\n\r\n";
  }



	list($partition, $nonpartition) = preg_split ("/:/", $curdir); //Fix by Wiedmann
	$partwampp = substr(realpath(__FILE__), 0, strrpos(dirname(realpath(__FILE__)), '\\'));

	$directorwampp = NULL;
	if ($usbstick == "1" ) {
	   $dirpartwampp=$nonpartition;
  } else {
  	$dirpartwampp=$partwampp;
  }

	$awkpart = str_replace("&", "\\\\&", preg_replace ("/\\\\/i", "\\\\\\\\", $dirpartwampp)); //Fix by Wiedmann
	$awkpartdoublebackslash = str_replace("&", "\\\\&", preg_replace ("/\\\\/i", "\\\\\\\\\\\\\\\\", $dirpartwampp)); //Fix by Wiedmann
	$awkpartslash = str_replace("&", "\\\\&", preg_replace ("/\\\\/", "/", $dirpartwampp)); //Fix by Wiedmann


	// Only debug
  // echo $partition."\n";
	// 	echo $nonpartition."\n";
	//		echo $partwampp."\n\n";
          // echo $awkpart."\n";
				    // echo $awkpartslash."\n";
				          // exit;

  $phpdir = $partwampp;
	$dir = preg_replace("/\\\\/", "/", $partwampp);
	$ppartition = "$partition:";

	/// I need the install.sys + update.sys for more xampp informations
	$installsys = "install.sys";
	$installsysroot = $partwampp."\install\\".$installsys;

	/// Some addon|update.sys files
	$perlupdatesys = "perlupdate.sys";
	$pythonupdatesys = "pythonupdate.sys";
	$serverupdatesys = "serverupdate.sys";
	$utilsupdatesys = "utilsupdate.sys";
	$javaupdatesys = "javaupdate.sys";
	$otherupdatesys = "otherupdate.sys";

	/// XAMPP main directrory is ...
	$substit = "\\\\\\\\xampp";
	$doublesubstit = "\\\\\\\\\\\\\\\\xampp";
	$substitslash = "/xampp";

	/// Globale variables
	$BS = 0;
	$CS = 0;
	$slashi = 1;
	$bslashi = 1;
	$awkexe = ".\install\awk.exe";
	$awk = ".\install\config.awk";
	$awknewdir = "\"".$awkpart."\"";
	$awkdoublebackslashdir = "\"".$awkpartdoublebackslash."\"";
	$awkslashdir = "\"".$awkpartslash."\"";
	if (file_exists("$partwampp\htdocs\\xampp\.version")) {
	$handle = fopen("$partwampp\htdocs\\xampp\.version","r");
  $xamppversion = fgets($handle);
  fclose($handle);
	} else {
		$xamppversion = "?.?.?";
    // include_once "$partwampp\install\.version";
  }
  date_default_timezone_set('UTC');
	echo "\r\n  ########################################################################\n";
	echo "  # ApacheFriends XAMPP setup win32 Version                              #\r\n";
	echo "  #----------------------------------------------------------------------#\r\n";
	echo "  # Copyright (c) 2002-".date("Y")." Apachefriends $xamppversion                          #\r\n";
	echo "  #----------------------------------------------------------------------#\r\n";
	echo "  # Authors: Kay Vogelgesang <kvo@apachefriends.org>                     #\r\n";
	echo "  #          Carsten Wiedmann <webmaster@wiedmann-online.de>             #\r\n";
	echo "  ########################################################################\r\n\r\n";

	$confhttpdroot = $partwampp."\apache\\conf\\httpd.conf";

	// Find the install status for xampp basic package in the install.sys file
	if (file_exists($installsysroot)) {
		$i = 0;
		$datei = fopen($installsysroot, 'r');
		while (!feof($datei)) {
			$zeile = fgets($datei, 255);
			if ( $zeile == "usbstick = 1" ) {
        echo "  USB stick installation found! Using relative paths by default ($nonpartition).";
          $dirpartwampp=$nonpartition;
          $usbstick="1";
          $partwampp=$nonpartition;
        //exit;
      }
			$sysroot[] = $zeile;
			$i += 1;
		}
		fclose($datei);

		$sysroot[2] = str_replace('perl', 'server', $sysroot[2]); // Fix by Wiedmann
		file_put_contents($installsysroot, implode('', $sysroot));

		list($left, $right) = preg_split ("/ = /", $sysroot[0]);
		$right = preg_replace ("/\r\n/i", "", $right);
		if (strtolower($partwampp) == strtolower($right)) {
			$xamppinstaller = "nothingtodo";
		} else {
			$xamppinstaller = "newpath";
			$substit = preg_replace ("/\\\\/i", "\\\\\\\\\\\\\\\\", $right);
			$doublesubstit = preg_replace ("/\\\\/i", "\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\", $right);
			$substitslash = preg_replace("/\\\\/i", "/", $right);
		}
	} else {
		$installsys = fopen($installsysroot, 'w');
		if ( $usbstick == "1" ) {
		$wamppinfo = "DIR = $nonpartition\r\nxampp = $xamppversion\r\nserver = 0\r\nperl = 0\r\npython = 0\r\nutils = 0\r\njava = 0\r\nother = 0\r\nusbstick = $usbstick";
		} else {
    $wamppinfo = "DIR = $partwampp\r\nxampp = $xamppversion\r\nserver = 0\r\nperl = 0\r\npython = 0\r\nutils = 0\r\njava = 0\r\nother = 0\r\nusbstick = $usbstick";
    }
    fputs($installsys, $wamppinfo);
		fclose($installsys);
		$xamppinstaller = "newinstall";
	}

	/// Find some *update.sys files and modify the install.sys ...
	$path = $partwampp."\install\\";
	$hdl = opendir($path);
	while ($res = readdir($hdl)) { //Searching all xampp sys files
		$array[] = $res;
	 }
	closedir($hdl);
	$werte = count($array);
	for ($q = 2; $q < $werte; $q++) {
		if (($array[$q] == $perlupdatesys) || ($array[$q] == $pythonupdatesys) || ($array[$q] == $serverupdatesys) || ($array[$q] == $utilsupdatesys) || ($array[$q] == $javaupdatesys) || ($array[$q] == $otherupdatesys)) {
			$updatesysroot = $partwampp."\install\\".$array[$q];
			if (file_exists($updatesysroot)) {
				$datei = fopen($updatesysroot, 'r');
				unset($updatezeile);

				$i = 0;
				while (!feof($datei)) {
					$zeile = fgets($datei, 255);
					$updatezeile[] = $zeile;
					@list($left, $right) = preg_split("/=/", $updatezeile[0]);
					$left = preg_replace("/\s/i", "", $left);
					$left = preg_replace("/\r\n/i", "", $left);
					$right = preg_replace("/\r\n/i", "", $right);
					$update = $left;
					$update = strtolower($update);
					$updateversion = trim($right);
					$updateversionzahl = preg_split('|[.-]|', $updateversion); // Fix by Wiedmann
					if (!isset($updateversionzahl[3])) {
						$updateversionzahl[3] = '';
					}
					$updateinc = "xampp".$update.".inc";
					$updateconf = $update.".conf";

					$i++;
				}
				fclose($datei);
        // echo "  Configure for $update $updateversion\r\n";
        // echo "  Configure for Version $xamppversion\r\n";
				if (file_exists($installsysroot)) {
					$datei = fopen($installsysroot, 'r');
					unset($newzeile);
					$i = 0;
					while (!feof($datei)) {
						$zeile = fgets($datei, 255);
						$newzeile[] = $zeile;
						$i++;
					}
					fclose($datei);

		/// Analyze install.sys to *update.syse for todo

		//// Vogelgesang 28.12.2005 => Must take old Section for addon functality
		$datei = fopen($installsysroot,'w');
        if($datei)
            {
                for($z=0;$z<$i+1;$z++)
                {
					if (0 === stripos(trim($newzeile[$z]), trim($update))) // Fix by Wiedmann

					{
						list ($left, $right) = preg_split ("/=/", $newzeile[$z]);

						$left = preg_replace ("/\s/i","",$left);
						$left = preg_replace ("/\r\n/i","",$left);
						$right = trim(preg_replace ("/\r\n/i","",$right));
						$currentversionzahl = preg_replace ("/\./i","",sprintf('%0-6s',$right)); // Fix by Wiedmann
						if ($currentversionzahl == 0 )
						{
							$updatemake="makenew"; // New installation
							$putnew="$update = $updateversion\r\n";
							fputs($datei, $putnew);
						}
						elseif ($currentversionzahl < $updateversionzahl)
						{
							$updatemake="update";  // Update installation
							$putnew="$update = $updateversion\r\n";  //Fix by Wiedmann
							fputs($datei, $putnew);
						}
						else
						{
							$updatemake="doppelt"; // Installation is current
							fputs($datei,$newzeile[$z]);
						}

					}
					else
					{
					fputs($datei,$newzeile[$z]);
					}
				}
			}
	fclose($datei);
//// Vogelgesang 28.12.2005 => Old Section for addon functality end here


					if (($updatemake == "makenew") || ($updatemake=="doppelt")) {
						include_once "$partwampp\install\\$updateinc";
					}
				}
				// httpd.conf modification for Perl, Python or Java (only single)
				////// PATH CHANGING SINCE APACHE 2.2
				/* if ($update == "perl") {
					$includehttpdconf = "\r\n\r\nInclude conf/extra/perl.conf";
				} */
				if ($update == "python") {
					$includehttpdconf = "\r\n\r\nInclude conf/extra/python.conf";
				}
				/* if ($update == "java") {
					$includehttpdconf = "\r\n\r\nInclude conf/extra/java.conf";
				} */
		if ((($update == "perl") || ($update == "python") || ($update == "java")) && ($updatemake == "makenew")) {
					$datei = fopen($confhttpdroot, 'a');
					if ($datei) {
						fputs($datei, $includehttpdconf);
					}
					@fclose($datei);
					/* $datei = fopen($confhttpd2root, 'a');
					if ($datei) {
						fputs($datei, $includehttpdconf);
					}
					fclose($datei);
					$datei = fopen($confhttpd3root, 'a');
					if ($datei) {
						fputs($datei, $includehttpdconf);
					}
					fclose($datei); */ //Vogelgesang 28.12.06 because obsolet
				}

				unlink($updatesysroot);
			}
		}
	}

	if (($xamppinstaller == "newinstall") || ($xamppinstaller == "newpath")) {
		if ($xamppinstaller == "newinstall") {
			/// First initialization only main packages
			if (file_exists("$partwampp\install\\xamppbasic.inc")) {
				include_once "$partwampp\install\\xamppbasic.inc";
			}
			if (file_exists("$partwampp\install\\xamppserver.inc")) { // Fix by Wiedmann
				include_once "$partwampp\install\\xamppserver.inc";
			}
		} else {
			/// Find all the packages
			if (file_exists("$partwampp\install\\xamppbasic.inc")) {
				include_once "$partwampp\install\\xamppbasic.inc";
			}
			if (file_exists("$partwampp\install\\xamppserver.inc")) {
				include_once "$partwampp\install\\xamppserver.inc";
			}
			if (file_exists("$partwampp\install\\xamppperl.inc")) {
				include_once "$partwampp\install\\xamppperl.inc";
			}
			if (file_exists("$partwampp\install\\xampppython.inc")) {
				include_once "$partwampp\install\\xampppython.inc";
			}
			if (file_exists("$partwampp\install\\xampputils.inc")) {
				include_once "$partwampp\install\\xampputils.inc";
			}
			if (file_exists("$partwampp\install\\xamppjava.inc")) {
				include_once "$partwampp\install\\xamppjava.inc";
			}
			if (file_exists("$partwampp\install\\xamppother.inc")) {
				include_once "$partwampp\install\\xamppother.inc";
			}
			$updatemake = "nothingtodo";
		}
	}

	$scount = count($slashrootreal);
	$bcount = count($backslashrootreal);
	$dbcount = count($doublebackslashrootreal);

	/////////////////// xampp path is changing ///////////////////
	if ($xamppinstaller == "newpath") {
		set_time_limit(0);
		define('NEWSTDIN', fopen("php://stdin", "r")); // Fix by Wiedmann
		while ($BS == "0") {
			echo "\n  Do you want to refresh the XAMPP installation?\n";
			echo "  Soll die XAMPP Installation jetzt aktualisiert werden?\n\n";
			echo "  1) Refresh now! (Jetzt aktualisieren!)\n";
			echo "  x) Exit (Beenden)\n";

			switch (trim(fgets(NEWSTDIN, 256))) { // Fix by Wiedmann
				case 1:
					$BS = 1;
					echo "\r\n  XAMPP is refreshing now ...\r\n";
					echo "  XAMPP wird nun aktualisiert ...\r\n\r\n";
					sleep(1);
					break;

				case "x":
					echo "\r\n  The refresh is terminating on demand ...  exit\r\n";
					echo "  Die Aktualisierung wurde auf Wunsch abgebrochen ...\r\n";
					sleep(3);
					exit;

				default:
					exit;
			}
		}
		fclose(NEWSTDIN); // Fix by Wiedmann
	}

	/////////////////// You can configure the addon modules for httpd ///////////////////
	if (file_exists($installsysroot)) {
		$datei = fopen($installsysroot, 'r');
		unset($newzeile);
		$i = 0;
		while (!feof($datei)) {
			$zeile = fgets($datei, 255);
			@list($left, $right) = preg_split ("/=/", $zeile);
			$left = preg_replace("/\s/i", "", $left);
			$left = preg_replace("/\r\n/i", "", $left);
			$right = preg_replace("/\r\n/i", "", $right);
			$right = preg_replace("/\./i", "", $right);
			if (strtolower($right) > 0) {
				if (strtolower($left) == "perl") {
					$perlactive = "yes";
				}
				if (strtolower($left) == "python") {
					$pythonactive = "yes";
				}
				if (strtolower($left) == "java") {
					$javaactive = "yes";
				}
			}
		}
		fclose($datei);
	}

	/////////////////// Case new install ///////////////////
	if (($xamppinstaller == "newinstall") || ($BS == 1) || ($updatemake == "makenew") || ($updatemake == "doppelt")) {
		if ($BS == "1") {
			echo "  Refreshing all paths in config files ... \r\n\r\n";
		}

		echo "  Configure XAMPP with awk for ";
		$system = system("echo '%os%'");
		if ($system != "'Windows_NT'") {
			$system = "Windows";
			echo "  $system 98/ME/HOME";
		}
		echo "  Updating configuration files ... please wait ...";
		if ($xamppinstaller == "newinstall") {
			if ($system == "Windows") {
				$confhttpdroot = $partwampp."\apache\\conf\\httpd.conf";
				$includewin = "Win32DisableAcceptEx\r\n";
				echo "\r\n  Disable AcceptEx Winsocks v2 support";
				$datei = fopen($confhttpdroot, 'r');
				unset($newzeile);
				$i = 0;
				while (!feof($datei)) {
					$zeile = fgets($datei, 255);
					$newzeile[] = $zeile;
					$i++;
				}
				fclose($datei);
				$datei = fopen($confhttpdroot, 'w');
				if ($datei) {
					for ($z = 0; $z < $i + 1; $z++) {
						if (preg_match("/Win32DisableAcceptEx/i", $newzeile[$z])) {
							fputs($datei, $includewin);
						} else {
							fputs($datei, $newzeile[$z]);
						}
					}
				}
				fclose($datei);
			} else {
				$confhttpdroot = $partwampp."\apache\\conf\\httpd.conf";
				$includewin = "# Win32DisableAcceptEx\r\n";
				// echo "\r\n  Enable AcceptEx Winsocks v2 support";
				$datei = fopen($confhttpdroot, 'r');
				$i = 0;
				unset($newzeile);
				while (!feof($datei)) {
					$zeile = fgets($datei, 255);
					$newzeile[] = $zeile;
					$i++;
				}
				fclose($datei);
				$datei = fopen($confhttpdroot, 'w');
				if ($datei) {
					for ($z = 0; $z < $i + 1; $z++) {
						if (preg_match("/Win32DisableAcceptEx/i", $newzeile[$z])) {
							fputs($datei, $includewin);
						} else {
							fputs($datei, $newzeile[$z]);
						}
					}
				}
				fclose($datei);
			}
		}

		$substit = "\"".$substit."\"";
		$trans = array(
			"^" => "\\\\^",
			"." => "\\\\.",
			"[" => "\\\\[",
			"$" => "\\\\$",
			"(" => "\\\\(",
			")" => "\\\\)",
			"+" => "\\\\+",
			"{" => "\\\\{"
		);
		$substit = strtr($substit, $trans);
		for ($i = 0; $i <= $bcount; $i++) {
			///// 08.08.05 Vogelgesang: For all files with identical file names /////
			if ($backslash[$i] == "") {
				$upbackslashrootreal = $backslashrootreal[$i];
			} else {
				$configname = $backslash[$i];
				$upbackslashrootreal = $backslashrootreal[$configname].$configname;

			}
			$backslashawk = preg_replace("/\\\\/i", "\\\\\\\\", $upbackslashrootreal);
			$backslashawk = "\"".$backslashawk;

			$awkconfig = $backslashawk."\"";
			$awkconfigtemp = $backslashawk."temp\"";
			$configreal = $upbackslashrootreal;
			$configtemp = $upbackslashrootreal."temp";

			///////////// Section SET  NEW configfiles for addons/update OR DELETE /////////////
			$configrealnew = $upbackslashrootreal.".new";
			if (!file_exists($configreal) && file_exists($configrealnew)) {
				if (!@copy($configrealnew, $configreal)) {
				} else {
					unlink($configrealnew);
				}
			} elseif (file_exists($configrealnew)) {
				unlink($configrealnew);
			}

			if ($updatemake == "doppelt") {;
				break;
			}
      // echo "DEBUG: Working with $awkconfig now ... \r\n";
			$awkrealm = $awkexe." -v DIR=".$awknewdir." -v CONFIG=".$awkconfig. " -v CONFIGNEW=".$awkconfigtemp. "  -v SUBSTIT=".$substit." -f ".$awk;
			if (file_exists($awk) && file_exists($awkexe) && file_exists($configreal)) {
				$handle = popen($awkrealm, 'w'); // Fix by Wiedmann
				pclose($handle);
			}

			if (file_exists($configtemp) && file_exists($configreal)) {
				if (!@copy($configtemp, $configreal)) {
				} else {
					unlink($configtemp);
				}
			}
		}

		$doublesubstit = "\"".$doublesubstit."\"";
		$trans = array(
			"^" => "\\\\^",
			"." => "\\\\.",
			"[" => "\\\\[",
			"$" => "\\\\$",
			"(" => "\\\\(",
			")" => "\\\\)",
			"+" => "\\\\+",
			"{" => "\\\\{"
		);
		$doublesubstit = strtr($doublesubstit, $trans);
		for ($i = 0; $i <= $dbcount; $i++) {
			///// 08.08.05 Vogelgesang: For all files with identical file names /////
			if ($doublebackslash[$i] == "") {
				$updoublebackslashrootreal = $doublebackslashrootreal[$i];
			} else {
				$configname = $doublebackslash[$i];
				$updoublebackslashrootreal = $doublebackslashrootreal[$configname].$configname;

			}
			$doublebackslashawk = preg_replace("/\\\\/i", "\\\\\\\\", $updoublebackslashrootreal);
			$doublebackslashawk = "\"".$doublebackslashawk;

			$awkconfig = $doublebackslashawk."\"";
			$awkconfigtemp = $doublebackslashawk."temp\"";
			$configreal = $updoublebackslashrootreal;
			$configtemp = $updoublebackslashrootreal."temp";

			///////////// Section SET  NEW configfiles for addons/update OR DELETE /////////////
			$configrealnew = $updoublebackslashrootreal.".new";
			if (!file_exists($configreal) && file_exists($configrealnew)) {
				if (!@copy($configrealnew, $configreal)) {
				} else {
					unlink($configrealnew);
				}
			} elseif (file_exists($configrealnew)) {
				unlink($configrealnew);
			}

			if ($updatemake == "doppelt") {
				break;
			}
      // echo "DEBUG: Working with $awkconfig now ... \r\n";
			$awkrealm = $awkexe." -v DIR=".$awkdoublebackslashdir." -v CONFIG=".$awkconfig. " -v CONFIGNEW=".$awkconfigtemp. "  -v SUBSTIT=".$doublesubstit." -f ".$awk;

			if (file_exists($awk) && file_exists($awkexe) && file_exists($configreal)) {
				$handle = popen($awkrealm, 'w'); // Fix by Wiedmann
				pclose($handle);
			}

			if (file_exists($configtemp) && file_exists($configreal)) {
				if (!@copy($configtemp, $configreal)) {
				} else {
					unlink($configtemp);
				}
			}
		}

		$substitslash = "\"".$substitslash."\"";
		$trans = array(
			"^" => "\\\\^",
			"." => "\\\\.",
			"[" => "\\\\[",
			"$" => "\\\\$",
			"(" => "\\\\(",
			")" => "\\\\)",
			"+" => "\\\\+",
			"{" => "\\\\{"
		);
		$substitslash = strtr($substitslash, $trans);
		for ($i = 0; $i <= $scount; $i++) {
			///// 08.08.05 Vogelgesang: For all files with identical file names /////
			if ($slash[$i] == "") {
				$upslashrootreal = $slashrootreal[$i];
			} else {
				$configname = $slash[$i];
				$upslashrootreal = $slashrootreal[$configname].$configname;
			}
			$slashawk = preg_replace("/\\\\/i", "\\\\\\\\", $upslashrootreal);
			$slashawk = "\"".$slashawk;
			$awkconfig = $slashawk."\"";
			$awkconfigtemp = $slashawk."temp\"";
			$configreal = $upslashrootreal;
			$configtemp=$upslashrootreal."temp";

			///////////// Section SET  NEW configfiles for addons/update OR DELETE /////////////
			$configrealnew = $upslashrootreal.".new";
			if (!file_exists($configreal) && file_exists($configrealnew)) {
				if (!@copy($configrealnew, $configreal)) {
				} else {
					unlink($configrealnew);
				}
			} elseif (file_exists($configrealnew)) {
				unlink($configrealnew);
			}

			if ($updatemake == "doppelt") {
				break;
			}
      // echo "DEBUG: Working with $awkconfig now ... \r\n";
			$awkrealm = $awkexe." -v DIR=".$awkslashdir." -v CONFIG=".$awkconfig. " -v CONFIGNEW=".$awkconfigtemp. "  -v SUBSTIT=".$substitslash." -f ".$awk;

			if (file_exists($awk) && file_exists($awkexe) && file_exists($configreal)) {
				$handle = popen($awkrealm, 'w'); // Fix by Wiedmann
				pclose($handle);
			}

			if (file_exists($configtemp) && file_exists($configreal)) {
				if (!@copy($configtemp, $configreal)) {
				} else {
					unlink($configtemp);
				}
			}
		}

		if (($xamppinstaller == "newpath") || ($BS == 1)) {
			if (file_exists($installsysroot)) {
				$datei = fopen($installsysroot, 'r');
				unset($newzeile);
				$i = 0;
				while (!feof($datei)) {
					$zeile = fgets($datei, 255);
					$newzeile[] = $zeile;
					$i++;
				}
				fclose($datei);
			}

			$datei = fopen($installsysroot, 'w');
			if ($datei) {
				for ($z = 0; $z < $i + 1; $z++) {
					if (preg_match("/DIR/i", $newzeile[$z])) {
						$includenewdir = "DIR = $partwampp\r\n";
						fputs($datei, $includenewdir);
					} else {
						$includenewdir = $newzeile[$z];
						fputs($datei, $includenewdir);
					}
				}
			}
			fclose($datei);
		}

		////////// Replace (copy) some newer files ////////////////
		$phpversion = trim(@file_get_contents($partwampp."\\install\\.phpversion")); //Fix by Wiedmann
		switch ($phpversion) {
			case 4:
				$phpbin = $partwampp."\\apache\\bin\\php.ini";
				$phpcgi = $partwampp."\\php\\php4\\php.ini";
				@copy($phpbin, $phpcgi);
				$phpbin = $partwampp."\\php\\php5.ini";
				$phpcgi = $partwampp."\\php\\php.ini";
				@copy($phpbin, $phpcgi);
				break;

			default:
				$phpbin = $partwampp."\\apache\\bin\\php.ini";
				$phpcgi = $partwampp."\\php\\php.ini";
				@copy($phpbin, $phpcgi);
				$phpbin = $partwampp."\\php\\php4\\php4.ini";
				$phpcgi = $partwampp."\\php\\php4\\php.ini";
				@copy($phpbin, $phpcgi);
				break;
		}

		$workersbin = $partwampp."\\tomcat\\conf\\workers.properties";
		$workersjk = $partwampp."\\tomcat\\conf\\jk\\workers.properties";
		if (file_exists($workersbin)) {
			copy($workersbin,$workersjk);
		}

		echo "  DONE!\r\n\r\n";
		echo "\r\n  ##### Have fun with ApacheFriends XAMPP! #####\r\n\r\n\r\n";
		sleep(1);
	}

	//////////////// Selection for modules  ////////////////
	if ((($perlactive == "yes") || ($pythonactive == "yes") || ($javaactive == "yes")) && ($update == "")) {
		$u = 1;

		if ($perlactive == "yes") {
			$moduleconf = "conf/extra/perl.conf";
			$moduleconfigure = "MOD_PERL";
			$u++;
		}
		if ($pythonactive == "yes") {
			$moduleconf = "conf/extra/pyton.conf";
			$moduleconfigure = "MOD_PYTHON";
			$u++;
		}
		if ($javaactive == "yes") {
			$moduleconf = "conf/extra/java.conf";
			$moduleconfigure = "MOD_JDK";
			$u++;
		}

		set_time_limit(0);
		define('NEWSTDIN', fopen("php://stdin", "r"));
		while ($CS == "0") {
			echo "\n  Please select your choice!\n";
			echo "  Bitte jetzt auswaehlen!\n\n";
			if ($perlactive == "yes") {
				echo "  1) Configuration with MOD_PERL (mit MOD_PERL)\n";
				echo "  2) Configuration without MOD_PERL (ohne MOD MOD_PERL)\n";
			}
			if ($pythonactive == "yes") {
				echo "  3) Configuration with MOD_PYTHON (mit MOD_PYTHON)\n";
				echo "  4) Configuration without MOD_PYTHON (ohne MOD_PYTHON)\n";
			}
			if ($javaactive == "yes") {
				echo "  5) Configuration with MOD_JDK (mit MOD_JDK)\n";
				echo "  6) Configuration without MOD_JDK (ohne MOD_JDK)\n";
			}
			echo "  x) Exit (Beenden)\n";

			switch (trim(fgets(NEWSTDIN, 256))) {
				case 1:
					$CS = 1;
					echo "\r\n  Starting configure XAMPP with MOD_PERL ...\r\n";
					sleep(1);
					break;

				case 2:
					$CS = 2;
					echo "\r\n  Starting configure XAMPP without MOD_PERL ...\r\n";
					sleep(1);
					break;

				case 3:
					$CS = 3;
					echo "\r\n  Starting configure XAMPP with MOD_PYTHON ...\r\n";
					sleep(1);
					break;

				case 4:
					$CS = 4;
					echo "\r\n  Starting configure XAMPP without MOD_PYTHON ...\r\n";
					sleep(1);
					break;

				case 5:
					$CS = 5;
					echo "\r\n  Starting configure XAMPP with MOD_JDK ...\r\n";
					sleep(1);
					break;

				case 6:
				$CS = 6;
				echo "\r\n  Starting configure XAMPP without MOD_JDK ...\r\n";
				sleep(1);
				break;

				case "x":
					echo "\r\n  Setup is terminating on demand ...  exit\r\n";
					echo "  Das Setup wurde auf Wunsch abgebrochen ...\r\n";
					sleep(3);
					exit;

				default:
					exit;
			}
		}
		fclose(NEWSTDIN);

		if ($CS == 1) {
			$include = "Include conf/extra/perl.conf"; $searchstring="conf/extra/perl.conf";
		}
		if ($CS == 2) {
			$include = "# Include conf/extra/perl.conf"; $searchstring="conf/extra/perl.conf";
		}
		if ($CS == 3) {
			$include = "Include conf/extra/python.conf"; $searchstring="conf/extra/python.conf";
		}
		if ($CS == 4) {
			$include = "# Include conf/extra/python.conf"; $searchstring="conf/extra/python.conf";
		}
		if ($CS == 5) {
			$include = "Include conf/extra/java.conf"; $searchstring="conf/extra/java.conf";
		}
		if ($CS == 6) {
			$include = "# Include conf/extra/java.conf"; $searchstring="conf/extra/java.conf";
		}

		if ($CS > 0) {
			$i = 0;
			$datei = fopen($confhttpdroot, 'r');
			while (!feof($datei)) {
				$zeile = fgets($datei, 255);
				$newzeile[] = $zeile;
				$i++;
			}
			fclose($datei);
			$datei = fopen($confhttpdroot, 'w');
			if ($datei) {
				for ($z = 0; $z < $i + 1; $z++) {
					if (preg_match('/'.$searchstring.'/i', $newzeile[$z])) {
						fputs($datei, $include);
					} else {
						fputs($datei, $newzeile[$z]);
					}
				}
			}
			fclose($datei);
			unset($newzeile);

			/// Vogelgesang 28.12.06 because obsolet since 1.51
			/* $i = 0;
			$datei = fopen($confhttpd2root, 'r');
			while (!feof($datei)) {
				$zeile = fgets($datei, 255);
				$newzeile[] = $zeile;
				$i++;
			}
			fclose($datei);
			$datei = fopen($confhttpd2root, 'w');
			if ($datei) {
				for($z = 0; $z < $i + 1; $z++) {
					if (eregi($searchstring, $newzeile[$z])) {
						fputs($datei, $include);
					} else {
						fputs($datei, $newzeile[$z]);
					}
				}
			}
			fclose($datei);
			unset($newzeile);
			$i = 0;
			$datei = fopen($confhttpd3root, 'r');
			while (!feof($datei)) {
				$zeile = fgets($datei, 255);
				$newzeile[] = $zeile;
				$i++;
			}
			fclose($datei);
			$datei = fopen($confhttpd3root, 'w');
			if ($datei) {
				for ($z = 0; $z < $i + 1; $z++) {
					if (eregi($searchstring, $newzeile[$z])) {
						fputs($datei, $include);
					} else {
						fputs($datei, $newzeile[$z]);
					}
				}
			}
			fclose($datei);
			unset($newzeile);*/
			echo "  Done!\r\n\r\n";
		}
	}

	if (file_exists($partwampp.'\install\serverupdate.inc')) { // Fix by Wiedmann
		include $partwampp.'\install\serverupdate.inc';
		unlink($partwampp.'\install\serverupdate.inc');
		echo "\r\n".'Ready.'."\r\n";
	}

	if ($updatemake == "") {
		$updatemake="nothingtodo";
	}

	if (($updatemake == "nothingtodo") && ($xamppinstaller == "nothingtodo") && (($CS < 1) || ($CS == ""))) {
		echo "\r\n\r\n Sorry, but ... nothing to do!\r\n\r\n\r\n";
	}

	exit;
?>
