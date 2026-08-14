<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works
This is a UART, 3 Tap FIR Filter. It works by sending 3 samples individually, each with a value no greater than 255. Then send 3 different coefficients, with no value greater than 255. All being sent via UART at 9600 Baud Rate. It can communicate with the microcontroller or your personal computer.

## How to test

1)  Install HTerm, unzip the folder, and open the hterm.exe. Link: HTerm - der-hammer[https://www.der-hammer.info/pages/terminal.html]
2) Ensure the setting is the same as the screenshots, except for the COM Port. The COM Port number for the FPGA board can be found in Device Manager under Ports on Windows.
 <img width="2857" height="350" alt="Screenshot 2026-07-27 114752" src="https://github.com/user-attachments/assets/4914b5ff-f5fb-4cf9-945d-f2985e2d427a" />

3) After configuring the settings, click on connect
4) To send the required data, follow the format as: Sample0 Sample1 Sample2 Coefficient0 Coefficient1 Coefficient2. Ensure there is space between the values. No values above 255. When ready, press Enter, and the result will appear in the “Received Data” section.
 <img width="3280" height="725" alt="Screenshot 2026-07-27 115007" src="https://github.com/user-attachments/assets/b7286e85-d887-4483-b063-dd6d4e4988c5" />



## External hardware
- UART to USB adapter

List external hardware used in your project (e.g. PMOD, LED display, etc), if any
