source "qemu" "lvm" {
  boot_command    = ["<wait>e<wait5>", "<down><wait><down><wait><down><wait2><end><wait5>", "<bs><bs><bs><bs><wait>autoinstall ---<wait><f10>"]
  boot_wait       = "2s"
  cpus            = 8
  disk_size       = "120G"
  format          = "raw"
  headless        = var.headless
  http_directory  = var.http_directory
  iso_checksum    = "file:http://releases.ubuntu.com/${var.ubuntu_series}/SHA256SUMS"
  iso_target_path = "packer_cache/${var.ubuntu_series}.iso"
  iso_url         = "https://releases.ubuntu.com/${var.ubuntu_series}/${var.ubuntu_lvm_iso}"
  memory          = 8192
  qemuargs = [
    ["-vga", "qxl"],
    ["-device", "virtio-blk-pci,drive=drive0,bootindex=0"],
    ["-device", "virtio-blk-pci,drive=cdrom0,bootindex=1"],
    ["-device", "virtio-blk-pci,drive=drive1,bootindex=2"],
    ["-drive", "if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE.fd"],
    ["-drive", "if=pflash,format=raw,file=OVMF_VARS.fd"],
    ["-drive", "file=output-lvm/packer-lvm,if=none,id=drive0,cache=writeback,discard=ignore,format=raw"],
    ["-drive", "file=seeds-lvm.iso,format=raw,cache=none,if=none,id=drive1,readonly=on"],
    ["-drive", "file=packer_cache/${var.ubuntu_series}.iso,if=none,id=cdrom0,media=cdrom"]
  ]
  shutdown_command       = "sudo -S shutdown -P now"
  ssh_handshake_attempts = 500
  ssh_password           = var.ssh_ubuntu_password
  ssh_timeout            = "45m"
  ssh_username           = "ubuntu"
  ssh_wait_timeout       = "15m"
}

build {
  sources = ["source.qemu.lvm"]

  provisioner "shell" {
    execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    inline          = ["mkdir ${var.image_folder}", "chmod 777 ${var.image_folder}"]
  }

  provisioner "shell" {
    execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    script          = "${path.root}/scripts/build/configure-apt-mock.sh"
  }

  provisioner "shell" {
    environment_vars = ["DEBIAN_FRONTEND=noninteractive"]
    execute_command  = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    scripts          = [
      "${path.root}/scripts/build/install-ms-repos.sh",
      "${path.root}/scripts/build/configure-apt-sources.sh",
      "${path.root}/scripts/build/configure-apt.sh"
    ]
  }

  provisioner "shell" {
    execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    script          = "${path.root}/scripts/build/configure-limits.sh"
  }

  provisioner "file" {
    destination = "${var.helper_script_folder}"
    source      = "${path.root}/scripts/helpers"
  }

  provisioner "file" {
    destination = "${var.installer_script_folder}"
    source      = "${path.root}/scripts/build"
  }

  provisioner "file" {
    destination = "${var.image_folder}"
    sources     = [
      "${path.root}/assets/post-gen",
      "${path.root}/scripts/tests",
      "${path.root}/scripts/docs-gen"
    ]
  }

  provisioner "file" {
    destination = "${var.image_folder}/docs-gen/"
    source      = "${path.root}/../helpers/software-report-base"
  }

  provisioner "file" {
    destination = "${var.installer_script_folder}/toolset.json"
    source      = "${path.root}/toolsets/toolset-2204.json"
  }

  provisioner "shell" {
    execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    inline          = [
      "mv ${var.image_folder}/docs-gen ${var.image_folder}/SoftwareReport",
      "mv ${var.image_folder}/post-gen ${var.image_folder}/post-generation"
    ]
  }

  provisioner "shell" {
    environment_vars = ["IMAGE_VERSION=${var.image_version}", "IMAGEDATA_FILE=${var.imagedata_file}"]
    execute_command  = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    scripts          = ["${path.root}/scripts/build/configure-image-data.sh"]
  }

  provisioner "shell" {
    environment_vars = ["IMAGE_VERSION=${var.image_version}", "IMAGE_OS=${var.image_os}", "HELPER_SCRIPTS=${var.helper_script_folder}"]
    execute_command  = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    scripts          = ["${path.root}/scripts/build/configure-environment.sh"]
  }

  provisioner "shell" {
    environment_vars = ["DEBIAN_FRONTEND=noninteractive", "HELPER_SCRIPTS=${var.helper_script_folder}", "INSTALLER_SCRIPT_FOLDER=${var.installer_script_folder}"]
    execute_command  = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    scripts          = ["${path.root}/scripts/build/install-apt-vital.sh"]
  }

  provisioner "shell" {
    environment_vars = ["HELPER_SCRIPTS=${var.helper_script_folder}"]
    execute_command  = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    scripts          = ["${path.root}/scripts/build/install-powershell.sh"]
  }

  provisioner "shell" {
    environment_vars = ["HELPER_SCRIPTS=${var.helper_script_folder}", "INSTALLER_SCRIPT_FOLDER=${var.installer_script_folder}"]
    execute_command  = "sudo sh -c '{{ .Vars }} pwsh -f {{ .Path }}'"
    scripts          = ["${path.root}/scripts/build/Install-PowerShellModules.ps1", "${path.root}/scripts/build/Install-PowerShellAzModules.ps1"]
  }

  provisioner "shell" {
    environment_vars = ["HELPER_SCRIPTS=${var.helper_script_folder}", "INSTALLER_SCRIPT_FOLDER=${var.installer_script_folder}", "DEBIAN_FRONTEND=noninteractive"]
    execute_command  = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    scripts          = [
      "${path.root}/scripts/build/install-actions-cache.sh",
      "${path.root}/scripts/build/install-runner-package.sh",
      "${path.root}/scripts/build/install-apt-common.sh",
      "${path.root}/scripts/build/install-azcopy.sh",
      "${path.root}/scripts/build/install-azure-cli.sh",
      "${path.root}/scripts/build/install-azure-devops-cli.sh",
      "${path.root}/scripts/build/install-bicep.sh",
      "${path.root}/scripts/build/install-aliyun-cli.sh",
      "${path.root}/scripts/build/install-apache.sh",
      "${path.root}/scripts/build/install-aws-tools.sh",
      "${path.root}/scripts/build/install-clang.sh",
      "${path.root}/scripts/build/install-swift.sh",
      "${path.root}/scripts/build/install-cmake.sh",
      "${path.root}/scripts/build/install-codeql-bundle.sh",
      "${path.root}/scripts/build/install-container-tools.sh",
      "${path.root}/scripts/build/install-dotnetcore-sdk.sh",
      "${path.root}/scripts/build/install-erlang.sh",
      "${path.root}/scripts/build/install-firefox.sh",
      "${path.root}/scripts/build/install-microsoft-edge.sh",
      "${path.root}/scripts/build/install-gcc-compilers.sh",
      "${path.root}/scripts/build/install-gfortran.sh",
      "${path.root}/scripts/build/install-git.sh",
      "${path.root}/scripts/build/install-git-lfs.sh",
      "${path.root}/scripts/build/install-github-cli.sh",
      "${path.root}/scripts/build/install-google-chrome.sh",
      "${path.root}/scripts/build/install-google-cloud-cli.sh",
      "${path.root}/scripts/build/install-haskell.sh",
      "${path.root}/scripts/build/install-heroku.sh",
      "${path.root}/scripts/build/install-hhvm.sh",
      "${path.root}/scripts/build/install-java-tools.sh",
      "${path.root}/scripts/build/install-kubernetes-tools.sh",
      "${path.root}/scripts/build/install-oc-cli.sh",
      "${path.root}/scripts/build/install-leiningen.sh",
      "${path.root}/scripts/build/install-miniconda.sh",
      "${path.root}/scripts/build/install-mono.sh",
      "${path.root}/scripts/build/install-kotlin.sh",
      "${path.root}/scripts/build/install-mysql.sh",
      "${path.root}/scripts/build/install-mssql-tools.sh",
      "${path.root}/scripts/build/install-sqlpackage.sh",
      "${path.root}/scripts/build/install-nginx.sh",
      "${path.root}/scripts/build/install-nvm.sh",
      "${path.root}/scripts/build/install-nodejs.sh",
      "${path.root}/scripts/build/install-bazel.sh",
      "${path.root}/scripts/build/install-oras-cli.sh",
      "${path.root}/scripts/build/install-phantomjs.sh",
      "${path.root}/scripts/build/install-php.sh",
      "${path.root}/scripts/build/install-postgresql.sh",
      "${path.root}/scripts/build/install-pulumi.sh",
      "${path.root}/scripts/build/install-ruby.sh",
      "${path.root}/scripts/build/install-rlang.sh",
      "${path.root}/scripts/build/install-rust.sh",
      "${path.root}/scripts/build/install-julia.sh",
      "${path.root}/scripts/build/install-sbt.sh",
      "${path.root}/scripts/build/install-selenium.sh",
      "${path.root}/scripts/build/install-terraform.sh",
      "${path.root}/scripts/build/install-packer.sh",
      "${path.root}/scripts/build/install-vcpkg.sh",
      "${path.root}/scripts/build/configure-dpkg.sh",
      "${path.root}/scripts/build/install-mongodb.sh",
      "${path.root}/scripts/build/install-yq.sh",
      "${path.root}/scripts/build/install-android-sdk.sh",
      "${path.root}/scripts/build/install-pypy.sh",
      "${path.root}/scripts/build/install-python.sh",
      "${path.root}/scripts/build/install-zstd.sh"
    ]
  }

  provisioner "shell" {
    environment_vars = ["HELPER_SCRIPTS=${var.helper_script_folder}", "INSTALLER_SCRIPT_FOLDER=${var.installer_script_folder}", "DOCKERHUB_LOGIN=${var.dockerhub_login}", "DOCKERHUB_PASSWORD=${var.dockerhub_password}"]
    execute_command  = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    scripts          = ["${path.root}/scripts/build/install-docker.sh", "${path.root}/scripts/build/install-docker-compose.sh"]
  }

  provisioner "shell" {
    environment_vars = ["HELPER_SCRIPTS=${var.helper_script_folder}", "INSTALLER_SCRIPT_FOLDER=${var.installer_script_folder}"]
    execute_command  = "sudo sh -c '{{ .Vars }} pwsh -f {{ .Path }}'"
    scripts          = ["${path.root}/scripts/build/Install-Toolset.ps1", "${path.root}/scripts/build/Configure-Toolset.ps1"]
  }

  provisioner "shell" {
    environment_vars = ["HELPER_SCRIPTS=${var.helper_script_folder}", "INSTALLER_SCRIPT_FOLDER=${var.installer_script_folder}"]
    execute_command  = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    scripts          = ["${path.root}/scripts/build/install-pipx-packages.sh"]
  }

  provisioner "shell" {
    environment_vars = ["HELPER_SCRIPTS=${var.helper_script_folder}", "DEBIAN_FRONTEND=noninteractive", "INSTALLER_SCRIPT_FOLDER=${var.installer_script_folder}"]
    execute_command  = "/bin/sh -c '{{ .Vars }} {{ .Path }}'"
    scripts          = ["${path.root}/scripts/build/install-homebrew.sh"]
  }

  provisioner "shell" {
    environment_vars = ["HELPER_SCRIPTS=${var.helper_script_folder}"]
    execute_command  = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    scripts          = ["${path.root}/scripts/build/configure-snap.sh"]
  }

  provisioner "shell" {
    execute_command  = "echo 'ubuntu' | sudo -S sh -c '{{ .Vars }} {{ .Path }}'"
    inline          = ["echo 'Restarting VM'", "reboot"]
    expect_disconnect = true
    pause_after = "60s"
  }

  provisioner "shell" {
    execute_command     = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    pause_before        = "30s"
    scripts             = ["${path.root}/scripts/build/cleanup.sh"]
    start_retry_timeout = "10m"
  }

  provisioner "shell" {
    environment_vars    = ["IMAGE_VERSION=${var.image_version}", "INSTALLER_SCRIPT_FOLDER=${var.installer_script_folder}"]
    inline              = [
      "pwsh -Command Write-Host Running Generate-SoftwareReport.ps1 script",
      "pwsh -File ${var.image_folder}/SoftwareReport/Generate-SoftwareReport.ps1 -OutputDirectory ${var.image_folder}",
      "pwsh -Command Write-Host Running RunAll-Tests.ps1 script",
      "pwsh -File ${var.image_folder}/tests/RunAll-Tests.ps1 -OutputDirectory ${var.image_folder}"
    ]
    max_retries         = "3"
    start_retry_timeout = "2m"
  }

  provisioner "file" {
    destination = "${path.root}/Ubuntu2204-Readme.md"
    direction   = "download"
    source      = "${var.image_folder}/software-report.md"
  }

  provisioner "file" {
    destination = "${path.root}/software-report.json"
    direction   = "download"
    source      = "${var.image_folder}/software-report.json"
  }

  provisioner "shell" {
    environment_vars = ["HELPER_SCRIPT_FOLDER=${var.helper_script_folder}", "INSTALLER_SCRIPT_FOLDER=${var.installer_script_folder}", "IMAGE_FOLDER=${var.image_folder}"]
    execute_command  = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    scripts          = ["${path.root}/scripts/build/configure-system.sh"]
  }

  provisioner "file" {
    destination = "/tmp/"
    source      = "${path.root}/assets/ubuntu2204.conf"
  }

  provisioner "shell" {
    execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    inline          = ["mkdir -p /etc/vsts", "cp /tmp/ubuntu2204.conf /etc/vsts/machine_instance.conf"]
  }

  provisioner "file" {
    destination = "/tmp/curtin-hooks"
    source      = "${path.root}/scripts/curtin-hooks"
  }

  provisioner "shell" {
    environment_vars  = ["HOME_DIR=/home/ubuntu", "http_proxy=${var.http_proxy}", "https_proxy=${var.https_proxy}", "no_proxy=${var.no_proxy}"]
    execute_command   = "echo 'ubuntu' | {{ .Vars }} sudo -S -E sh -eux '{{ .Path }}'"
    expect_disconnect = true
    scripts           = ["${path.root}/scripts/curtin.sh", "${path.root}/scripts/networking.sh", "${path.root}/scripts/cleanup.sh"]
  }

  post-processor "compress" {
    output = "custom-ubuntu-lvm.dd.gz"
  }
}
