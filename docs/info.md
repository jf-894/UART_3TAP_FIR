<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works
This is a UART, 3 Tap FIR Filter. It works by sending 3 samples individually, each with a value no greater than 255. Then send 3 different coefficients, with no value greater than 255. All being sent via UART at 9600 Baud Rate. All samples and Coefficients are must be 8-bit. The result is limited to an 8-bit value, which ranges from 0 to 255. It can communicate with the microcontroller or your personal computer. 

The values are received in the following order:

Sample0 Sample1 Sample2 Coefficient0 Coefficient1 Coefficient2

The FIR filter calculates:

Output = (Sample0 × Coefficient0) + (Sample1 × Coefficient1) + (Sample2 × Coefficient2)


## How to test

You are welcome to use any software other than HTerm if you can't use it or have difficulty with it. Just as long as you can follow the format of step 5

1)  When using the UART to USB adapter, connect the RX cable to the Tinytapeout board's TX pin(Output pin 0) and the TX cable to the Tinytapeout board's RX pin(Input pin 0). Connect the Ground cable to the Ground pin of the Tinytapeout board. 

2) Install HTerm, unzip the folder, and open the hterm.exe. Link: [HTerm - der-hammer](https://www.der-hammer.info/pages/terminal.html)
   Website-https://www.der-hammer.info/pages/terminal.html
   
3) Ensure the setting is the same as the screenshots, except for the COM Port. The COM Port number for the FPGA board can be found in Device Manager under Ports on Windows.
 <img width="2857" height="350" alt="Screenshot 2026-07-27 114752" src="https://github.com/user-attachments/assets/4914b5ff-f5fb-4cf9-945d-f2985e2d427a" />

4) After configuring the settings, click on connect
 
5) To send the required data, follow the format as: Sample0 Sample1 Sample2 Coefficient0 Coefficient1 Coefficient2. Ensure there is space between the values. No values above 255. When ready, press Enter, and the result will appear in the “Received Data” section.
 <img width="3280" height="725" alt="Screenshot 2026-07-27 115007" src="https://github.com/user-attachments/assets/b7286e85-d887-4483-b063-dd6d4e4988c5" />


The image below shows the final result
 <img width="2065" height="930" alt="Screenshot 2026-07-27 115133" src="https://github.com/user-attachments/assets/50419999-f792-4199-963e-da5488563f9d" />



## Using Microcontrollers
1) Set up your UART protocol based on your microcontroller and ensure the baud rate is 9600. Then connect the microcontroller's RX pin to the Tinytapeout board's TX pin(Output pin 0). Then connect the microcontroller's TX pin to the Tinytapeout board's RX pin(Input pin 0). Lastly and most importantly, connect the Ground pin of the microcontroller to the Ground pin of the Tinytapeout board.

2) Write your code so that it sends 3 samples individually, each with a value no greater than 255. Then send 3 individual coefficients, with no value greater than 255. Ensure you have a variable to store the 8-bit data.


## External hardware
- UART to USB adapter
- Wires
