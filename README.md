
## CTA_TOOLS Plugin



### Legal disclaimer

On 27 Apr 2023 I (Alex Bettarini) have contacted Dr Örjan Smedby (Linköping University Sweden), one of the authors of the original version of this plugin, and I have been given authorization to resume work on the project, using the original name "CMIV_CTA_TOOLS" or any other name.

### Setting up the project

- create subdirectory `Binaries/` containing the following items

        Binaries
        ├── DCM.framework
        ├── DCMTK
        ├── GLM
        ├── ITK
        ├── MieleAPI.framework
        └── VTK
        
    note that each subdirectory can be a symbolic link into some other location where those items are actually installed, In particular:
    
        /Applications/miele-lxiv.app/Contents/Frameworks/DCM.framework
        /Applications/miele-lxiv.app/Contents/Frameworks/MieleAPI.framework
