# BoaLauncher
---
how to build the executable Windows:
- download https://www.lazarus-ide.org , suggested 32bit version from here: https://sourceforge.net/projects/lazarus/files/Lazarus%20Windows%2032%20bits/Lazarus%202.0.10/
- install Lazarus and then cross compiler to the same dir, e.g. C:\Lazarus
- launch Lazarus IDE, it will scan itself and prepare default configuration. Close it.
- now double click BladeOfAgonyLauncher.lpi file, then from the menu click "Run", then "Build". Done.
- "Blade of Agony - Launcher.exe" should be in the release dir.
---
how to build the executable Linux:
- download packages from https://sourceforge.net/projects/lazarus/files/Lazarus%20Linux%20amd64%20DEB/Lazarus%202.0.10/
- install
fpc-laz_3.2.0-1_amd64.deb
fpc-src_3.2.0-1_amd64.deb
lazarus-project_2.0.10-0_amd64.deb

be sure you have those packages installed:
- libc6-dev 
- and for QT5: libqt5pas-dev, libx11-dev
- and for GTK2: libpango1.0-dev, libgdk-pixbuf2.0-dev, libgtk2.0-dev
---
For testing purposes boa.ipk3 contains only menudef.txt file.
