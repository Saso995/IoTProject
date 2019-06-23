INSTRUCTIONS
------------

FOLDER CONTENT:

1) source code:

	- sendAckAppC.nc, sendAckC.nc, sendAck.h
		They contain the implementation of the TinyOS program for the Waste management problem

	- TestSerial.java 
		Implementation of the program to read messages from the serial port

	- RunSimulationScript.py (use topology.txt as topology and meyer-heavy.txt as noise trace)
		Python script to simulate the sensor node that sends messages through the serial interface.

	- RunSimulationScript2.py (use topology2.txt as topology and casino-lab.txt as noise trace)
		Python script to simulate the sensor node that sends messages through the serial interface.

	- topology.txt and topology2.txt (the first it's the provided, the second is made by me in the same folder there is also a picture of it)
	
	- meyer-heavy.txt and casino-lab.txt
	
HOW TO USE IT:

1. compile the tinyos program for simulation using the serial port, typing
	make micaz sim-sf
2. open the serial forwarder on port 9001 typing
	java net.tinyos.sf.SerialForwarder -comm sf@localhost:9001&
3. run the java program that accepts messages from the serial port 9002
	java TestSerial -comm sf@localhost:9002
4. run the python simulation
	python RunSimulationScript.py or python RunSimulationScript2.py

2) logFile:

	- logFile.txt and logFile2.txt contain the simulation respectively of RunSimulationScript.py and RunSimulationScript2.py 
	
	- logFileSerial.txt and logFileSerial2.txt contain the output on the serial port respectively of RunSimulationScript.py and RunSimulationScript2.py 
	
3) Project Report

Bova Salvatore 10499292