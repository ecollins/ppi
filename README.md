# Elliott's PPI Development Repository

Code for replicating, re-factoring, and developing new features for the PPI

## Current set-up:

1. `./ppi-code/` : This contains standard functions used across all national and custom PPI projects

2. `./[country]/` : Organized data files, country-specific code, config files, and documentation to make [Country]'s PPI

  - `./data/raw/` : Downloaded data files used in each PPI, which are occasionally quite large. Each subfolder should look like and contain a ReadMe.md file with links to where to download the documentation.


  - `./data/clean/` : Organized files constructed via .do file and used by R or Python file to make the new PPI model
