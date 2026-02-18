; MANUAL FILAMENT CHANGE - P2S (No AMS Required)
; Based on P1S manual change script + P2S filament change gcode
; Supports multi-color and multi-material printing
;
; Uses slicer variables for automatic temperature and material configuration

;--------------------
; MANUAL TOOLCHANGE START
;--------------------

M204 S9000
G17
G2 Z{max_layer_z + 0.4} I0.86 J0.86 P1 F10000 ; spiral lift
G1 Z{max_layer_z + 3.0} F1200

M400
M106 P1 S0  ; turn off part cooling fan
M106 P2 S0  ; turn off aux fan

; ===== CUTTING SEQUENCE =====
; Move to poop chute area at back of printer
G1 X56 F21000       ; Move to poop chute X position
G1 Y245 F21000      ; Approach back area
G1 Y272 F3000       ; Move to poop chute at back (just before limit)
M400

; Heat nozzle to OLD filament temperature for clean cut
; Using old_filament_temp variable from slicer
M109 S[old_filament_temp]  ; OLD filament unload temp

; P2S CUTTING MOTION (based on manual measurements)
; Already at X56 Y272 (poop chute)
G1 Y253 F3000       ; Move 19mm forward to align with cutter (272-19=253)
G1 X16 F3000        ; Move 40mm left toward cutter (56-40=16)
G1 X0 F300          ; Slow movement 15mm left to press cutting lever (ACTUAL CUT)
M400                ; Wait for cut to complete
G1 X56 F12000       ; Fast movement 56mm right (away from cutter)
G1 Y272 F3000       ; Move 19mm back to poop chute

; Push filament stub out and retract
G1 E10 F200
G1 E-10 F200
G1 E-20 F500

; Retract poop chute 3 times (like official routine)
G1 Y262 F3000       ; Move forward to retract chute
G1 Y272 F3000       ; Move back to engage chute
G1 Y262 F3000       ; Retract again
G1 Y272 F3000       ; Engage again
G1 Y262 F3000       ; Retract third time
G1 Y272 F3000       ; Final engage

; ===== PAUSE FOR MANUAL FILAMENT CHANGE =====
M118 P1 A1 action:notification REMOVE old filament and LOAD new filament
M300 S1000 P500  ; Beep
M400 U1  ; Pause - user removes old filament and loads new one

; Move away from chute and back (helps with loading)
G1 X65 Y240 F12000
G1 Y272 F3000

; ===== PURGE/FLUSH NEW FILAMENT =====
M400
G92 E0

; Ensure at poop chute for purging (CRITICAL - repositions after pause)
G1 X56 Y272 F12000
M400

; Heat to NEW filament temperature for flushing
; Using new_filament_temp variable from slicer
M109 S[new_filament_temp]  ; NEW filament load/print temp

; FLUSH STAGE 1 - Initial purge at poop chute
; Purges old material out with controlled extrusion
; Using old_filament_e_feedrate and new_filament_e_feedrate from slicer
G1 E15 F{old_filament_e_feedrate}   ; Initial extrusion with old filament speed
G1 E10 F50                           ; Slow pulse
G1 E10 F{old_filament_e_feedrate}   ; Medium speed
G1 E10 F50                           ; Slow pulse
G1 E10 F{new_filament_e_feedrate}   ; Faster extrusion with new filament speed

; Retract and re-prime
G1 E-0.5 F1800
G1 E0.5 F300

; FLUSH STAGE 2 - Secondary purge (reduced amount)
G1 E10 F{new_filament_e_feedrate}
G1 E2 F50
G1 E10 F{new_filament_e_feedrate}
G1 E2 F50
G1 E10 F{new_filament_e_feedrate}

; Final retract
G1 E-0.5 F1800
G1 E0.5 F{new_filament_e_feedrate}

; Compensate for oozing during temp stabilization
G1 E2 F{new_filament_e_feedrate}

M400
G92 E0
G1 E-0.5 F1800

; Retract poop chute 3 times after purging (like official routine)
G1 Y262 F3000
G1 Y272 F3000
G1 Y262 F3000
G1 Y272 F3000
G1 Y262 F3000
G1 Y272 F3000

; ===== WIPE NOZZLE =====
M106 P1 S255  ; Max part cooling for wipe
M400 S3

; Move to nozzle wiper (30mm right of poop chute = X85)
G1 X85 Y272 F12000

; Wipe sequence - quick left-right motions across wiper (X80-X90 range)
G1 X80 F5000        ; Left end of wiper
G1 X90 F10000       ; Fast to right end
G1 X80 F10000       ; Fast to left end
G1 X90 F10000       ; Fast to right end
G1 X80 F10000       ; Fast to left end
G1 X90 F10000       ; Fast to right end
G1 X85 F5000        ; Return to center

; Extra retraction to prevent oozing
G1 E-1.0 F1800      ; Additional retraction before moving away

; Move away from wiper area
G1 Y264 F12000

M400
G1 Z{max_layer_z + 3.0} F3000

G1 E-2.0 F1800  ; Retract 2mm to create negative pressure

; POSITION VERIFICATION (prevents layer shift)
; Option 1: Quick Y-axis verification (uncomment to enable)
G28 Y  ; Re-home Y axis only to ensure position accuracy

G1 E2.0 F1800  ; Prime back the retraction

; Set acceleration based on layer
{if layer_z <= (initial_layer_print_height + 0.001)}
M204 S[initial_layer_acceleration]
{else}
M204 S[default_acceleration]
{endif}

; Set NEW filament type for firmware (automatic based on slicer)
M1002 set_filament_type:{filament_type[next_extruder]}

; Re-enable air printing detection (automatic based on filament type)
{if (filament_type[next_extruder] == "PLA") || (filament_type[next_extruder] == "PETG") || (filament_type[next_extruder] == "PLA-CF") || (filament_type[next_extruder] == "PETG-CF")}
M1015.4 S1 K1 H[nozzle_diameter]
{else}
M1015.4 S0 K0 H[nozzle_diameter]
{endif}

; Enable AMS air printing detect (keeps system happy even without AMS)
M620.6 I[next_extruder] W1

; Set chamber cooling (automatic based on filament and temperature)
{if (overall_chamber_temperature < 40)}
{if (layer_num + 1 < close_fan_the_first_x_layers[next_extruder] + 1)}
    {if (min_vitrification_temperature <= 50)}
        M106 P2 S{first_x_layer_fan_speed[next_extruder]*255.0/100.0}
        M106 P10 S{first_x_layer_fan_speed[next_extruder]*255.0/100.0}
    {endif}
{else}
    {if (min_vitrification_temperature <= 50)}
        {if (nozzle_diameter == 0.2)}
            M142 P1 R30 S40 U{max_additional_fan/100.0} V1.0 O45
        {else}
            M142 P1 R30 S40 U{max_additional_fan/100.0} V1.0 O45
        {endif}
    {endif}
    M106 P10 S{additional_cooling_fan_speed[next_extruder]*255.0/100.0}
{endif}
{endif}

; Restore part cooling fan (automatic based on filament settings)
M106 S{fan_min_speed[next_extruder]*255.0/100.0}

; Dummy AMS commands to prevent system hang
; These hide the T[next_extruder] command
M620 S[next_extruder]A
T[next_extruder]
M621 S[next_extruder]A

;--------------------
; MANUAL TOOLCHANGE END
;--------------------
