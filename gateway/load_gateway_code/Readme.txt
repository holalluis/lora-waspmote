*****************************************************************
	SCRIPT TO  LOAD A BINARY FILE INTO a GATEWAY
*****************************************************************
Version: 1.0
Date: 04-2015

Note: This process is dangerous and can brick your Gateway. Do it only if you are really sure about what you are doing. If you have questions, please contact Libelium technical support team at www.libelium.com/contact

Note: this is a beta verison and it can be other errors not contempled.
*****************************************************************

The purpose of this script is to upload a code into a Gateway without using the Waspmote IDE.

The necessary .HEX files are already included.

The AVRdude tool is also necessary. A 64 bit version is already included, but if your system is different you may need to install it manually on your machine by doing "apt get....".


********
 STEPS
********

1. Open a terminal and go to the folder /load_gateway_code
2. Execute the file load_code by the command "./load_code"
3. Then The program will ask you for the Gateway COM port. Type the exact name without errors and press enter. Example: USB2. you will see a progress bar increasing. If no error messages, the program will be loaded into Gateway.
4. After uploading the code, a test is done if you press enter. Remember to plug the LoRa module.




Libelium Comunicaciones Distribuidas S.L. 
Address: C/ Escatrón 16, (Edificio LIBELIUM) C.P: 50014
Zaragoza (Spain)
Phone	+34 976 54 74 92
Fax	+34 976 47 31 86



