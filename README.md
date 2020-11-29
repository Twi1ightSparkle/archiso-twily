# archiso-twily

Must be done on Arch

- Install Arch on bare metal or in a VM
- Prepare according to https://wiki.archlinux.org/index.php/Archiso
- Create working directories
    ```bash
    pacman -Sy archiso
    mkdir -p /arch/
    mkdir -p /arch/out/
    mkdir -p /arch/work/
    cp -r /usr/share/archiso/configs/releng/* /arch/archlive/
    mkdir -p /arch/archlive/airootfs/root/.ssh/
    ```
- Use `archlive` = `/arch/archlive/`
- Use `releng` profile
- Make all changes from files in the `/arch` folder in here
- Make `send_ip_drives_to_matrix.sh` excecutable
    ```bash
    chmod +x /arch/archlive/airootfs/root/send_ip_drives_to_matrix.sh
    ```
- Change the config in `/arch/archlive/airootfs/root/send_ip_drives_to_matrix.sh`
- Add your publilc SSH key to `/arch/archlive/airootfs/root/.ssh/authorized_keys`
- Set SSH key permissions
    ```bash
    chmod 700 /arch/archlive/airootfs/root/.ssh/
    chmod 600 /arch/archlive/airootfs/root/.ssh/authorized_keys
    ```
- Enable OpenSSH on boot
    ```bash
    cd /arch/
    mkdir -p archlive/airootfs/etc/systemd/system/multi-user.target.wants
    ln -s /usr/lib/systemd/system/sshd.service archlive/airootfs/etc/systemd/system/multi-user.target.wants/
    ```
- Build the ISO
    ```bash
    mkarchiso -v -w /arch/work -o /arch/out /arch/archlive/
    ```
- Clear the work dirs before building again
    ```bash
    rm -r /arch/work/*
    rm -r /arch/out/*
    ```
