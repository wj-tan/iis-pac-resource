```mermaid
graph TD;
    A[Start Script] --> B(Define Configs & Check Directories);
    B --> C(Dynamically discover *.pac files in C:\Repository);
    C --> D{Any PAC files found?};
    D -- No --> E(Log Error & Exit);
    D -- Yes --> F[Determine IsFirstRun status];
    F --> G{For Each PACFile in Repository};
    
    G --> H(Calculate Paths: Repo, Live, Archive);
    H --> I{Check Repo Modified Time vs. Latest Archive Time};
    
    I -- No Change / Repo Older --> J(Log 'No Change', Skip Deployment);
    
    I -- Change Detected / First Run --> K[DEPLOY: Copy Repo File to Primary Live Folder];
    K --> L[ARCHIVE: Copy New Live File to Local Archive Folder];
    L --> M(Add PACFile to FilesToSync list);
    
    J --> N; 
    M --> N{End PACFile Loop?};
    
    N -- Yes --> O{FilesToSync > 0 OR IsFirstRun?};
    O -- No --> P(Log 'No Changes to Sync' & Exit);
    
    O -- Yes --> Q{For Each SecondaryServer};
    Q --> R{Test Server Connectivity};
    R -- Fail --> S(Log Server Error, Continue to Next Server);
    R -- Pass --> T{For Each PACFile in FilesToSync};
    
    T --> U(Ensure Remote Live Dir Exists);
    U --> V(Ensure Remote Archive Dir Exists);
    V --> W[Copy LIVE PAC File to Remote Live Dir];
    W --> X[Copy NEW Archive File(s) to Remote Archive Dir];
    X --> Y{End FilesToSync Loop?};
    
    S --> Z;
    Y -- Yes --> Z{End SecondaryServer Loop?};
    
    Z -- Yes --> Z_Final{IsFirstRun?};
    Z_Final -- Yes --> Z_Flag(Create first_run.flag);
    Z_Flag --> Z_End(Log 'Script Finished' & Exit);
    Z_Final -- No --> Z_End;
```
