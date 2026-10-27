# cfb-logos

Every FBS and FCS college football logo, sorted by conference.

```
images/
  fbs/<conference>/<school>.png
  fcs/<conference>/<school>.png
```

`cfb-logos.csv` lists each school's ESPN ID, name, mascot, conference, and logo URL.

To download fresh copies from ESPN (saved flat into `images/`, not sorted):

```powershell
powershell -ExecutionPolicy Bypass -File .\download-logos.ps1
```
