<img src="https://www.dotkit.app/dk-logo.svg" width="70" align="right">

# dotkit/gpu - gpu detection and install

> [!CAUTION]
> dotkit is still in early development, and is not yet ready for use.
> expect breaking changes and bugs.

## overview

installing the correct gpu drivers for users is crutial for a smooth experience, as such we provide a simple gpu detection and installation system.

dotkit/gpu is a module that provides the following functionality:

- automatic detection of connected gpus
- leverage pci-ids lists and a database to provide the best supported gpu
- additionally installs hardware acceleration for supported gpus
- prompts for user input to ensure they want to install the driver
- installs the drivers for the detected gpu