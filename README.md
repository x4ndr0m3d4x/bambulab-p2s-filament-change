> [!IMPORTANT]
> 🚧 Still work in progress.

> [!WARNING]
> This software comes with no warranty. I am not responsible for broken printers, failed prints, or thermonuclear war. Use at your own risk.

# BambuLab P2S Manual Filament Change G-code (No AMS Required)

A custom **Change Filament G-code** script for Bambu Lab printers that pauses multi-color & multi-material prints for manual filament swaps.

When a filament change is triggered, the printer:
1. Cuts the filament and purges the old material at the poop chute
2. Pauses and beeps, prompting you to remove the old filament and load the new one
3. Purges and flushes the new filament
4. Wipes the nozzle
5. Resumes printing automatically

All temperatures, speeds, and filament types are pulled automatically from slicer variables, so no manual editing of the script is required between prints.

---

## Tested On

Tested with [this model](https://makerworld.com/en/models/1292793-ikea-alex-70x33-full-extension-mod-small-drawer?from=search#profileId-1592445) on a 0.4mm nozzle using the following sequence:
- **Layer N:** PETG → PLA (same layer change)
- **Layer N+1:** PLA → PETG (same layer change)

---

## Limitations

- The `.gcode` file must be **exported manually** from the slicer after slicing
- The exported file must be **transferred to the printer via USB** (or another direct method) — it cannot be sent wirelessly through Bambu Studio as usual, as it reports missing filament

---

## Setup

> [!NOTE]
> This script replaces the "Change filament G-code" in Bambu Studio's machine settings. It must be configured before slicing.

1. Open the file you want to print in **Bambu Studio**
2. Open **Machine Settings** (pencil icon in the top right corner of the printer icon)
3. Select the **"Machine G-code"** tab
4. Select all the content in the **"Change filament G-code"** field and delete it
5. Paste the entire contents of `filament_change.gcode` into that field
6. **Slice** the model as usual
7. **Export** the resulting `.gcode` file to a USB drive
8. Plug the USB into your printer and **print from USB**

---

## Compatibility

Developed and tested on the **Bambu Lab P2S**. It may work on other Bambu printers with minor modifications, but the cutting sequence and coordinates are specific to the P2S.

---

## How It Works

The script follows a similar flow to Bambu's official multi-color routine, adapted for manual operation:

- **Cutting** — moves to the poop chute area, activates the filament cutter, and cuts the filament
- **Pause** — pauses the print and notifies you via the printer display and a beep (`M300`)
- **Flush** — purges the new filament through the nozzle at the poop chute using slicer-provided feedrates
- **Wipe** — runs a wipe sequence across the nozzle wiper
- **Resume** — re-homes the Y axis to prevent layer shifts, restores fan settings, and continues the print
