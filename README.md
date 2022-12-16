# Packer GitHub Actions Runner Images for MAAS 

[Packer](http://packer.io) [templates](https://www.packer.io/docs/templates/index.html),
associated scripts, and configuration for creating deployable OS images for [MAAS](http://maas.io).

Based on [GitHub Actions Runner Images](https://github.com/actions/runner-images) repositiory

## Existing templates

| **OS** | **Versions** |
|---|:------------:|
| Ubuntu  |  22.04 LTS   |

### Known issues
Right now installation of `brew` is disable, since it was breaking teh build.

### Output

All templates are configured to output to serial. Packer does not officially
support serial output([GH:5](https://github.com/hashicorp/packer-plugin-qemu/issues/5)).
To see output run with PACKER_LOG=1.

If you wish to use a GUI modify each template as follows:

* Remove any boot_command line that contains "console" or "com1_Port"
* Remove ""-serial", "stdio"" from qemuargs. qemuargs may be removed as well if empty.

If you wish to use QEMU's UI also remove "headless": true

If you keep "headless": true you can connect using VNC. Packer will output the
IP and port to connect to when run.

## Contributing new templates

We welcome contributions of new templates.

The following is a set of guidelines for contributing to Packer MAAS. 
These are mostly guidelines, not rules. Use your best judgment, and feel free to propose changes to this document in a pull request.

### Project structure

Each OS has it's own directory in the repository. The typical contents is:

* one or more HCL2 templates
* a `scripts` directory with auxiliary scripts required by `provisioner` and `post-processor`
* a `http` directory with auto-configuration files used by the OS installer
* a `README.md` file describing
    * what is the target OS
    * host requirements for building this template
    * MAAS requirements for deploying the generated image
    * description of each template (HCL2) file, including the use of all parameters defined by them
    * step by step instruction to build it
    * default login credentials for the image (if any)
    * instructions for uploading this image to MAAS
* a `Makefile` to build the template

### How to submit a new template

1. [Fork the project](https://github.com/canonical/packer-maas/fork) to your own GH account
2. Create a local branch
3. If you are contributing a new OS, create a new directory following the guidelines above
4. If you are creating a new template for an already supported OS, just create a HCL2 file and add auxiliary files it requires to the appropriate directories
5. Run `packer validate .` in the directory to check your template
6. Commit your changes and push the branch to your repository
7. Open a Merge Request to packer-maas
8. Wait for review
