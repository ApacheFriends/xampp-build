BEGIN {
	# ORS="\\r\\n";
	# SUBSTIT = "\\\\xamppcoffee";
	# DIR = "D:\\xampp";
	# server_cmd = "D:\\xampp\\install\\server.xml";
	while (getline < CONFIG) {
		sub(SUBSTIT,DIR,$0);
		print $0 > CONFIGNEW
	}

	# print "@rem  Installation Program, second part" > "D:\\xampp\\install\\inst.bat"
	# D:\xampp\install\awk -v DIR = "C:\\xampp" -f D:\xampp\install\test.awk
}
