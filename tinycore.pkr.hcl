variable "vm_description" {
  type    = string
  default = "Router"
}

variable "vm_version" {
  type    = string
  default = "7"
}
packer {
  required_plugins {
    virtualbox = {
      version = ">= 0.0.1"
      source  = "github.com/hashicorp/virtualbox"
    }
  }
}

source "virtualbox-iso" "tinyCoreRouter" {
  guest_os_type    = "Linux_64"
  iso_url          = "http://tinycorelinux.net/7.x/x86/archive/7.2/Core-7.2.iso"
  iso_checksum     = "md5:77bf8cceacd2110120451f3f22f85156"
  ssh_username     = "tc"
  ssh_password     = "root1960-"
  boot_wait        = "4s"
  shutdown_command = "sudo poweroff"
  export_opts = [
    "--manifest",
    "--vsys", "0",
    "--description", "${var.vm_description}",
    "--version", "${var.vm_version}"
  ]
  format  = "ova"
  vm_name = "TinyCore_Router"

  boot_command = [
    "<enter><wait10>",
    "ifconfig",
    "<return>",
    "tce-load -iw openssh.tcz<return><wait120>",
    "cd /usr/local/etc/ssh<return>",
    "sudo cp ssh_config.example ssh_config<return>",
    "cd<return>",
    "passwd<return><wait3>",
    "root1960-",
    "<return>",
    "root1960-",
    "<return>",
    "sudo /usr/local/etc/init.d/openssh start<return><wait5>"
  ]

  vboxmanage = [
    ["modifyvm", "{{.Name}}", "--memory", "128"],
    ["modifyvm", "{{.Name}}", "--cpus", "1"],
    ["modifyvm", "{{.Name}}", "--nic2", "bridged"],
    ["modifyvm", "{{.Name}}", "--bridgeadapter2", "Carte de bouclage Microsoft KM-TEST"],
  ]
}

build {
  sources = ["sources.virtualbox-iso.tinyCoreRouter"]
  provisioner "shell" {
    execute_command = "echo '' | sudo -S sh -c '{{ .Vars }} {{ .Path }}'"
    inline          = ["cp -R /tmp/tce ~/"]
    pause_before    = "1s"
  }

  provisioner "shell" {
    inline       = ["tce-load -iw parted.tcz", "tce-load -iw grub2.tcz"]
    pause_before = "1s"
  }

  provisioner "shell" {
    execute_command = "echo '' | sudo -S sh -c '{{ .Vars }} {{ .Path }}'"
    inline          = ["export PATH=$PATH:/usr/local/sbin:/usr/local/bin", "parted /dev/sda mktable msdos", "parted /dev/sda mkpart primary ext3 1% 99%", "parted /dev/sda set 1 boot on", "mkfs.ext3 /dev/sda1", "parted /dev/sda print", "rebuildfstab", "mount /mnt/sda1", "echo COPY SOFT", "echo /usr/local/etc/init.d/openssh start >> /opt/bootlocal.sh", "echo usr/local/etc/ssh > /opt/.filetool.lst", "echo etc/passwd>> /opt/.filetool.lst", "echo etc/shadow>> /opt/.filetool.lst", "/bin/tar -C / -T /opt/.filetool.lst -cvzf /mnt/sda1/mydata.tgz", "mv ~/tce /mnt/sda1/", "cp -R /opt /mnt/sda1", "echo INSTALLING GRUB", "grub-install --target=i386-pc --boot-directory=/mnt/sda1/boot /dev/sda", "mount /mnt/sr0/", "cp /mnt/sr0/boot/core.gz /mnt/sda1/boot/", "cp /mnt/sr0/boot/vmlinuz /mnt/sda1/boot/", "echo set timeout=3 > /mnt/sda1/boot/grub/grub.cfg", "echo menuentry \\\"Tiny Core\\\" { >> /mnt/sda1/boot/grub/grub.cfg", "echo  linux /boot/vmlinuz com1=9600,8n1 loglevel=3 user=tc console=ttyS0 console=tty0 noembed nomodeset tce=sda1 opt=sda1 home=sda1 restore=sda1 >> /mnt/sda1/boot/grub/grub.cfg", "echo  initrd /boot/core.gz >> /mnt/sda1/boot/grub/grub.cfg", "echo } >> /mnt/sda1/boot/grub/grub.cfg", "reboot"]
    pause_before    = "1s"
  }

  provisioner "shell" {
    inline       = ["echo THANKS FOR WHATCHING!", "echo ---===  BYE!  ===---"]
    pause_before = "5s"
  }
}