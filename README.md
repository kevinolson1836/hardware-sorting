![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/test/badge.svg) ![](../../workflows/fpga/badge.svg)

# Tiny Tapeout Verilog Project Template

- [Read the documentation for project](docs/info.md)

## What is Tiny Tapeout?

Tiny Tapeout is an educational project that aims to make it easier and cheaper than ever to get your digital and analog designs manufactured on a real chip.

To learn more and get started, visit https://tinytapeout.com.

## Set up your Verilog project

1. Add your Verilog files to the `src` folder.
2. Edit the [info.yaml](info.yaml) and update information about your project, paying special attention to the `source_files` and `top_module` properties. If you are upgrading an existing Tiny Tapeout project, check out our [online info.yaml migration tool](https://tinytapeout.github.io/tt-yaml-upgrade-tool/).
3. Edit [docs/info.md](docs/info.md) and add a description of your project.
4. Adapt the testbench to your design. See [test/README.md](test/README.md) for more information.

The GitHub action will automatically build the ASIC files using [LibreLane](https://www.zerotoasiccourse.com/terminology/librelane/).

## Enable GitHub actions to build the results page

- [Enabling GitHub Pages](https://tinytapeout.com/faq/#my-github-action-is-failing-on-the-pages-part)

## Resources

- [FAQ](https://tinytapeout.com/faq/)
- [Digital design lessons](https://tinytapeout.com/digital_design/)
- [Learn how semiconductors work](https://tinytapeout.com/siliwiz/)
- [Join the community](https://tinytapeout.com/discord)
- [Build your design locally](https://www.tinytapeout.com/guides/local-hardening/)



## Main work flow 

1. install the harding tools
    - https://www.tinytapeout.com/guides/local-hardening/

2. harden the thing with:
    - First, generate the LibreLane configuration file
      - /tt/tt_tool.py --create-user-config
    
    - Then run the following command to harden the project locally. Notice that this command requires you to have Docker (or a compatible container engine) installed and running.
      - ./tt/tt_tool.py --harden

    - It’s also recommended to run the following command, checking for any synthesis / clock warnings:
      - ./tt/tt_tool.py --print-warnings

    - NOTE the file gets saved at   /runs/wokwi/final/gds/

3. convert it to a file blender can use 
    - python3 gds2gltf.py /path/to/your_design.gds

    - that will make a .gltf file that blender can open