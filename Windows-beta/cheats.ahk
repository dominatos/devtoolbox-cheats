#NoEnv
#SingleInstance Force
#Persistent
SetWorkingDir %A_ScriptDir%
;@Ahk2Exe-SetMainIcon imageres.dll, 110

CHEATS_DIR = C:\Users\<USER>\cheats.d
LOG_FILE = C:\Users\<USER>\cheats_debug.log

; ============= Debug Log =============
FileDelete, %LOG_FILE%
FileAppend, Script started`n, %LOG_FILE%

; ============= Tray Setup =============
Menu, Tray, Tip, Dev Toolbox Cheats

; Check for custom icon in cheats.d, fallback to system icon if missing
CustomIcon := CHEATS_DIR . "\icon.ico"
if FileExist(CustomIcon) {
    Menu, Tray, Icon, %CustomIcon%
} else {
    Menu, Tray, Icon, imageres.dll, 110 ; Default gear icon
}

; ============= Backups & S3 =============
Menu, BackupsS3, Add, s3cmd — S3 CLI, OpenFile
Menu, BackupsS3, Icon, s3cmd — S3 CLI, imageres.dll, 165
Menu, BackupsS3, Add, Borg Backup, OpenFile
Menu, BackupsS3, Icon, Borg Backup, imageres.dll, 165
Menu, BackupsS3, Add, Restic Backup, OpenFile
Menu, BackupsS3, Icon, Restic Backup, imageres.dll, 165

; ============= Basics =============
Menu, Basics, Add, Linux Basics — Cheatsheet, OpenFile
Menu, Basics, Icon, Linux Basics — Cheatsheet, imageres.dll, 110
Menu, Basics, Add, Linux Basics 2 — Cheatsheet, OpenFile
Menu, Basics, Icon, Linux Basics 2 — Cheatsheet, imageres.dll, 110

; ============= Cloud =============
Menu, Cloud, Add, AWS CLI, OpenFile
Menu, Cloud, Icon, AWS CLI, imageres.dll, 165
Menu, Cloud, Add, Azure CLI, OpenFile
Menu, Cloud, Icon, Azure CLI, imageres.dll, 165
Menu, Cloud, Add, GCP CLI, OpenFile
Menu, Cloud, Icon, GCP CLI, imageres.dll, 165
Menu, Cloud, Add, OpenStack, OpenFile
Menu, Cloud, Icon, OpenStack, imageres.dll, 165

; ============= Databases =============
Menu, Databases, Add, Memcached, OpenFile
Menu, Databases, Icon, Memcached, imageres.dll, 13
Menu, Databases, Add, MongoDB, OpenFile
Menu, Databases, Icon, MongoDB, imageres.dll, 13
Menu, Databases, Add, MySQL/MariaDB && Cluster, OpenFile
Menu, Databases, Icon, MySQL/MariaDB && Cluster, imageres.dll, 13
Menu, Databases, Add, OpenSearch, OpenFile
Menu, Databases, Icon, OpenSearch, imageres.dll, 13
Menu, Databases, Add, Oracle, OpenFile
Menu, Databases, Icon, Oracle, imageres.dll, 13
Menu, Databases, Add, PostgreSQL, OpenFile
Menu, Databases, Icon, PostgreSQL, imageres.dll, 13
Menu, Databases, Add, Redis, OpenFile
Menu, Databases, Icon, Redis, imageres.dll, 13
Menu, Databases, Add, SQLite, OpenFile
Menu, Databases, Icon, SQLite, imageres.dll, 13

; ============= Dev & Tools =============
Menu, DevTools, Add, Ansible, OpenFile
Menu, DevTools, Icon, Ansible, imageres.dll, 117
Menu, DevTools, Add, Build Tools, OpenFile
Menu, DevTools, Icon, Build Tools, imageres.dll, 117
Menu, DevTools, Add, Git Advanced, OpenFile
Menu, DevTools, Icon, Git Advanced, imageres.dll, 117
Menu, DevTools, Add, Git, OpenFile
Menu, DevTools, Icon, Git, imageres.dll, 117
Menu, DevTools, Add, Jenkins, OpenFile
Menu, DevTools, Icon, Jenkins, imageres.dll, 117
Menu, DevTools, Add, Kafka, OpenFile
Menu, DevTools, Icon, Kafka, imageres.dll, 117
Menu, DevTools, Add, Node Tools, OpenFile
Menu, DevTools, Icon, Node Tools, imageres.dll, 117
Menu, DevTools, Add, Python Tools, OpenFile
Menu, DevTools, Icon, Python Tools, imageres.dll, 117
Menu, DevTools, Add, Terraform, OpenFile
Menu, DevTools, Icon, Terraform, imageres.dll, 117
Menu, DevTools, Add, tmux, OpenFile
Menu, DevTools, Icon, tmux, imageres.dll, 117
Menu, DevTools, Add, Zookeeper, OpenFile
Menu, DevTools, Icon, Zookeeper, imageres.dll, 117

; ============= Diagnostics =============
Menu, Diagnostics, Add, Diagnostics, OpenFile
Menu, Diagnostics, Icon, Diagnostics, shell32.dll, 247
Menu, Diagnostics, Add, Process Diagnostics, OpenFile
Menu, Diagnostics, Icon, Process Diagnostics, shell32.dll, 247

; ============= Files & Archives =============
Menu, FilesArchives, Add, diff && patch, OpenFile
Menu, FilesArchives, Icon, diff && patch, shell32.dll, 257
Menu, FilesArchives, Add, tar, OpenFile
Menu, FilesArchives, Icon, tar, shell32.dll, 257
Menu, FilesArchives, Add, tar + zstd, OpenFile
Menu, FilesArchives, Icon, tar + zstd, shell32.dll, 257
Menu, FilesArchives, Add, zip/7z/zstd, OpenFile
Menu, FilesArchives, Icon, zip/7z/zstd, shell32.dll, 257

; ============= Identity Management =============
Menu, IdentityMgmt, Add, AD CLI, OpenFile
Menu, IdentityMgmt, Icon, AD CLI, shell32.dll, 269

; ============= Infrastructure Management =============
Menu, InfraMgmt, Add, AWX, OpenFile
Menu, InfraMgmt, Icon, AWX, imageres.dll, 110
Menu, InfraMgmt, Add, Uyuni, OpenFile
Menu, InfraMgmt, Icon, Uyuni, imageres.dll, 110

; ============= Kubernetes & Containers =============
Menu, K8s, Add, Docker, OpenFile
Menu, K8s, Icon, Docker, imageres.dll, 10
Menu, K8s, Add, Helm, OpenFile
Menu, K8s, Icon, Helm, imageres.dll, 10
Menu, K8s, Add, K9s, OpenFile
Menu, K8s, Icon, K9s, imageres.dll, 10
Menu, K8s, Add, kubectl, OpenFile
Menu, K8s, Icon, kubectl, imageres.dll, 10
Menu, K8s, Add, kubectl JSONPath, OpenFile
Menu, K8s, Icon, kubectl JSONPath, imageres.dll, 10
Menu, K8s, Add, kubectl Kustomize, OpenFile
Menu, K8s, Icon, kubectl Kustomize, imageres.dll, 10
Menu, K8s, Add, OpenShift, OpenFile
Menu, K8s, Icon, OpenShift, imageres.dll, 10
Menu, K8s, Add, Podman && nerdctl, OpenFile
Menu, K8s, Icon, Podman && nerdctl, imageres.dll, 10

; ============= Monitoring =============
Menu, Monitoring, Add, Cerebro, OpenFile
Menu, Monitoring, Icon, Cerebro, imageres.dll, 116
Menu, Monitoring, Add, CheckMK Agent, OpenFile
Menu, Monitoring, Icon, CheckMK Agent, imageres.dll, 116
Menu, Monitoring, Add, CheckMK, OpenFile
Menu, Monitoring, Icon, CheckMK, imageres.dll, 116
Menu, Monitoring, Add, Filebeat, OpenFile
Menu, Monitoring, Icon, Filebeat, imageres.dll, 116
Menu, Monitoring, Add, Nagios, OpenFile
Menu, Monitoring, Icon, Nagios, imageres.dll, 116
Menu, Monitoring, Add, SNMPD, OpenFile
Menu, Monitoring, Icon, SNMPD, imageres.dll, 116
Menu, Monitoring, Add, Telegraf, OpenFile
Menu, Monitoring, Icon, Telegraf, imageres.dll, 116
Menu, Monitoring, Add, VictoriaMetrics, OpenFile
Menu, Monitoring, Icon, VictoriaMetrics, imageres.dll, 116
Menu, Monitoring, Add, Zabbix Server, OpenFile
Menu, Monitoring, Icon, Zabbix Server, imageres.dll, 116

; ============= Network =============
Menu, Network, Add, autossh — Resilient SSH Tunnels, OpenFile
Menu, Network, Icon, autossh — Resilient SSH Tunnels, shell32.dll, 18
Menu, Network, Add, CURL — HTTP Client, OpenFile
Menu, Network, Icon, CURL — HTTP Client, shell32.dll, 18
Menu, Network, Add, DNS — dig/nslookup/host, OpenFile
Menu, Network, Icon, DNS — dig/nslookup/host, shell32.dll, 18
Menu, Network, Add, Fail2Ban — Intrusion Prevention, OpenFile
Menu, Network, Icon, Fail2Ban — Intrusion Prevention, shell32.dll, 18
Menu, Network, Add, firewalld — Firewall Management, OpenFile
Menu, Network, Icon, firewalld — Firewall Management, shell32.dll, 18
Menu, Network, Add, ip — Network Configuration, OpenFile
Menu, Network, Icon, ip — Network Configuration, shell32.dll, 18
Menu, Network, Add, iptables — Firewall Rules, OpenFile
Menu, Network, Icon, iptables — Firewall Rules, shell32.dll, 18
Menu, Network, Add, iptables to nftables Translation, OpenFile
Menu, Network, Icon, iptables to nftables Translation, shell32.dll, 18
Menu, Network, Add, nc / nmap — Network Tools, OpenFile
Menu, Network, Icon, nc / nmap — Network Tools, shell32.dll, 18
Menu, Network, Add, Network Diagnostics, OpenFile
Menu, Network, Icon, Network Diagnostics, shell32.dll, 18
Menu, Network, Add, netplan — Network Configuration, OpenFile
Menu, Network, Icon, netplan — Network Configuration, shell32.dll, 18
Menu, Network, Add, Network Backend Detection, OpenFile
Menu, Network, Icon, Network Backend Detection, shell32.dll, 18
Menu, Network, Add, NetworkManager, OpenFile
Menu, Network, Icon, NetworkManager, shell32.dll, 18
Menu, Network, Add, nftables — Modern Firewall, OpenFile
Menu, Network, Icon, nftables — Modern Firewall, shell32.dll, 18
Menu, Network, Add, nmcli — NetworkManager CLI, OpenFile
Menu, Network, Icon, nmcli — NetworkManager CLI, shell32.dll, 18
Menu, Network, Add, resolvectl, OpenFile
Menu, Network, Icon, resolvectl, shell32.dll, 18
Menu, Network, Add, RSYNC — File Synchronization, OpenFile
Menu, Network, Icon, RSYNC — File Synchronization, shell32.dll, 18
Menu, Network, Add, SCP — Secure Copy, OpenFile
Menu, Network, Icon, SCP — Secure Copy, shell32.dll, 18
Menu, Network, Add, SS — Socket Statistics, OpenFile
Menu, Network, Icon, SS — Socket Statistics, shell32.dll, 18
Menu, Network, Add, SSH — Commands && Config, OpenFile
Menu, Network, Icon, SSH — Commands && Config, shell32.dll, 18
Menu, Network, Add, SSH Tunneling && Port Forwarding, OpenFile
Menu, Network, Icon, SSH Tunneling && Port Forwarding, shell32.dll, 18
Menu, Network, Add, systemd-networkd, OpenFile
Menu, Network, Icon, systemd-networkd, shell32.dll, 18
Menu, Network, Add, UFW — Uncomplicated Firewall, OpenFile
Menu, Network, Icon, UFW — Uncomplicated Firewall, shell32.dll, 18
Menu, Network, Add, VPN Plugins, OpenFile
Menu, Network, Icon, VPN Plugins, shell32.dll, 18
Menu, Network, Add, WireGuard — VPN Setup, OpenFile
Menu, Network, Icon, WireGuard — VPN Setup, shell32.dll, 18

; ============= Package Managers =============
Menu, PkgMgr, Add, AppImage — Portable Apps, OpenFile
Menu, PkgMgr, Icon, AppImage — Portable Apps, shell32.dll, 264
Menu, PkgMgr, Add, APT — Debian/Ubuntu, OpenFile
Menu, PkgMgr, Icon, APT — Debian/Ubuntu, shell32.dll, 264
Menu, PkgMgr, Add, DNF — RHEL/Fedora, OpenFile
Menu, PkgMgr, Icon, DNF — RHEL/Fedora, shell32.dll, 264
Menu, PkgMgr, Add, Flatpak, OpenFile
Menu, PkgMgr, Icon, Flatpak, shell32.dll, 264
Menu, PkgMgr, Add, Pacman — Arch Linux, OpenFile
Menu, PkgMgr, Icon, Pacman — Arch Linux, shell32.dll, 264
Menu, PkgMgr, Add, Package Managers Overview, OpenFile
Menu, PkgMgr, Icon, Package Managers Overview, shell32.dll, 264
Menu, PkgMgr, Add, Snap — Universal Packages, OpenFile
Menu, PkgMgr, Icon, Snap — Universal Packages, shell32.dll, 264
Menu, PkgMgr, Add, Zypper — OpenSUSE, OpenFile
Menu, PkgMgr, Icon, Zypper — OpenSUSE, shell32.dll, 264

; ============= Security & Crypto =============
Menu, Security, Add, AIDE, OpenFile
Menu, Security, Icon, AIDE, shell32.dll, 48
Menu, Security, Add, Cerbero Suite, OpenFile
Menu, Security, Icon, Cerbero Suite, shell32.dll, 48
Menu, Security, Add, CrowdSec, OpenFile
Menu, Security, Icon, CrowdSec, shell32.dll, 48
Menu, Security, Add, Git Secret Leak Detection, OpenFile
Menu, Security, Icon, Git Secret Leak Detection, shell32.dll, 48
Menu, Security, Add, GPG / age — Encryption, OpenFile
Menu, Security, Icon, GPG / age — Encryption, shell32.dll, 48
Menu, Security, Add, htpasswd — Basic Auth, OpenFile
Menu, Security, Icon, htpasswd — Basic Auth, shell32.dll, 48
Menu, Security, Add, OpenSSL — Commands, OpenFile
Menu, Security, Icon, OpenSSL — Commands, shell32.dll, 48
Menu, Security, Add, OpenSSL CSR with SAN, OpenFile
Menu, Security, Icon, OpenSSL CSR with SAN, shell32.dll, 48
Menu, Security, Add, pass — Password Store, OpenFile
Menu, Security, Icon, pass — Password Store, shell32.dll, 48
Menu, Security, Add, SSH Honeypot + CrowdSec, OpenFile
Menu, Security, Icon, SSH Honeypot + CrowdSec, shell32.dll, 48
Menu, Security, Add, SSH Keys && Access Management, OpenFile
Menu, Security, Icon, SSH Keys && Access Management, shell32.dll, 48

; ============= Storage & FS =============
Menu, StorageFS, Add, ACL, OpenFile
Menu, StorageFS, Icon, ACL, shell32.dll, 9
Menu, StorageFS, Add, Chroot, OpenFile
Menu, StorageFS, Icon, Chroot, shell32.dll, 9
Menu, StorageFS, Add, Disk Growth, OpenFile
Menu, StorageFS, Icon, Disk Growth, shell32.dll, 9
Menu, StorageFS, Add, LVM — Basics, OpenFile
Menu, StorageFS, Icon, LVM — Basics, shell32.dll, 9
Menu, StorageFS, Add, Partition && Mount, OpenFile
Menu, StorageFS, Icon, Partition && Mount, shell32.dll, 9
Menu, StorageFS, Add, SMART && mdadm RAID, OpenFile
Menu, StorageFS, Icon, SMART && mdadm RAID, shell32.dll, 9

; ============= System & Logs =============
Menu, SysLogs, Add, cron / at — Commands, OpenFile
Menu, SysLogs, Icon, cron / at — Commands, imageres.dll, 110
Menu, SysLogs, Add, date && timedatectl, OpenFile
Menu, SysLogs, Icon, date && timedatectl, imageres.dll, 110
Menu, SysLogs, Add, du/df/lsof/ps, OpenFile
Menu, SysLogs, Icon, du/df/lsof/ps, imageres.dll, 110
Menu, SysLogs, Add, ionice && nice, OpenFile
Menu, SysLogs, Icon, ionice && nice, imageres.dll, 110
Menu, SysLogs, Add, journalctl — Basics, OpenFile
Menu, SysLogs, Icon, journalctl — Basics, imageres.dll, 110
Menu, SysLogs, Add, journalctl — Systemd Journal, OpenFile
Menu, SysLogs, Icon, journalctl — Systemd Journal, imageres.dll, 110
Menu, SysLogs, Add, Kernel-panic RHEL, OpenFile
Menu, SysLogs, Icon, Kernel-panic RHEL, imageres.dll, 110
Menu, SysLogs, Add, Kibana, OpenFile
Menu, SysLogs, Icon, Kibana, imageres.dll, 110
Menu, SysLogs, Add, logrotate, OpenFile
Menu, SysLogs, Icon, logrotate, imageres.dll, 110
Menu, SysLogs, Add, Ubuntu VPS Optimization, OpenFile
Menu, SysLogs, Icon, Ubuntu VPS Optimization, imageres.dll, 110
Menu, SysLogs, Add, SELinux && AppArmor, OpenFile
Menu, SysLogs, Icon, SELinux && AppArmor, imageres.dll, 110
Menu, SysLogs, Add, systemctl — Commands, OpenFile
Menu, SysLogs, Icon, systemctl — Commands, imageres.dll, 110
Menu, SysLogs, Add, systemd Timers, OpenFile
Menu, SysLogs, Icon, systemd Timers, imageres.dll, 110
Menu, SysLogs, Add, systemd unit template, OpenFile
Menu, SysLogs, Icon, systemd unit template, imageres.dll, 110

; ============= Text & Parsing =============
Menu, TextParsing, Add, AWK — Commands, OpenFile
Menu, TextParsing, Icon, AWK — Commands, shell32.dll, 151
Menu, TextParsing, Add, cut/sort/uniq, OpenFile
Menu, TextParsing, Icon, cut/sort/uniq, shell32.dll, 151
Menu, TextParsing, Add, FIND — Commands, OpenFile
Menu, TextParsing, Icon, FIND — Commands, shell32.dll, 151
Menu, TextParsing, Add, fzf — Fuzzy Finder, OpenFile
Menu, TextParsing, Icon, fzf — Fuzzy Finder, shell32.dll, 151
Menu, TextParsing, Add, GREP — Commands, OpenFile
Menu, TextParsing, Icon, GREP — Commands, shell32.dll, 151
Menu, TextParsing, Add, JQ — Commands, OpenFile
Menu, TextParsing, Icon, JQ — Commands, shell32.dll, 151
Menu, TextParsing, Add, Bash Loops, OpenFile
Menu, TextParsing, Icon, Bash Loops, shell32.dll, 151
Menu, TextParsing, Add, Modern CLI, OpenFile
Menu, TextParsing, Icon, Modern CLI, shell32.dll, 151
Menu, TextParsing, Add, SED — Commands, OpenFile
Menu, TextParsing, Icon, SED — Commands, shell32.dll, 151
Menu, TextParsing, Add, Tree, OpenFile
Menu, TextParsing, Icon, Tree, shell32.dll, 151
Menu, TextParsing, Add, tr/head/tail/watch, OpenFile
Menu, TextParsing, Icon, tr/head/tail/watch, shell32.dll, 151
Menu, TextParsing, Add, vim, OpenFile
Menu, TextParsing, Icon, vim, shell32.dll, 151
Menu, TextParsing, Add, yq — YAML processor, OpenFile
Menu, TextParsing, Icon, yq — YAML processor, shell32.dll, 151

; ============= Virtualization =============
Menu, Virtualization, Add, KVM / Libvirt, OpenFile
Menu, Virtualization, Icon, KVM / Libvirt, imageres.dll, 10

; ============= Web Servers =============
Menu, WebServers, Add, Apache HTTPD, OpenFile
Menu, WebServers, Icon, Apache HTTPD, imageres.dll, 11
Menu, WebServers, Add, HAProxy, OpenFile
Menu, WebServers, Icon, HAProxy, imageres.dll, 11
Menu, WebServers, Add, Nginx, OpenFile
Menu, WebServers, Icon, Nginx, imageres.dll, 11
Menu, WebServers, Add, Tomcat, OpenFile
Menu, WebServers, Icon, Tomcat, imageres.dll, 11
Menu, WebServers, Add, WebLogic Server, OpenFile
Menu, WebServers, Icon, WebLogic Server, imageres.dll, 11

; ============= Main Tray Menu =============
Menu, Tray, Add, 💾 Backups & S3, :BackupsS3
Menu, Tray, Icon, 💾 Backups & S3, imageres.dll, 165
Menu, Tray, Add, 🐧 Basics, :Basics
Menu, Tray, Icon, 🐧 Basics, imageres.dll, 110
Menu, Tray, Add, ☁️ Cloud, :Cloud
Menu, Tray, Icon, ☁️ Cloud, imageres.dll, 165
Menu, Tray, Add, 🗄️ Databases, :Databases
Menu, Tray, Icon, 🗄️ Databases, imageres.dll, 13
Menu, Tray, Add, 🛠️ Dev & Tools, :DevTools
Menu, Tray, Icon, 🛠️ Dev & Tools, imageres.dll, 117
Menu, Tray, Add, 🔍 Diagnostics, :Diagnostics
Menu, Tray, Icon, 🔍 Diagnostics, shell32.dll, 247
Menu, Tray, Add, 📁 Files & Archives, :FilesArchives
Menu, Tray, Icon, 📁 Files & Archives, shell32.dll, 257
Menu, Tray, Add, 🔑 Identity Management, :IdentityMgmt
Menu, Tray, Icon, 🔑 Identity Management, shell32.dll, 269
Menu, Tray, Add, 🏗️ Infrastructure Management, :InfraMgmt
Menu, Tray, Icon, 🏗️ Infrastructure Management, imageres.dll, 110
Menu, Tray, Add, ☸️ Kubernetes & Containers, :K8s
Menu, Tray, Icon, ☸️ Kubernetes & Containers, imageres.dll, 10
Menu, Tray, Add, 📈 Monitoring, :Monitoring
Menu, Tray, Icon, 📈 Monitoring, imageres.dll, 116
Menu, Tray, Add, 🌐 Network, :Network
Menu, Tray, Icon, 🌐 Network, shell32.dll, 18
Menu, Tray, Add, 📦 Package Managers, :PkgMgr
Menu, Tray, Icon, 📦 Package Managers, shell32.dll, 264
Menu, Tray, Add, 🔒 Security & Crypto, :Security
Menu, Tray, Icon, 🔒 Security & Crypto, shell32.dll, 48
Menu, Tray, Add, 💽 Storage & FS, :StorageFS
Menu, Tray, Icon, 💽 Storage & FS, shell32.dll, 9
Menu, Tray, Add, 📋 System & Logs, :SysLogs
Menu, Tray, Icon, 📋 System & Logs, imageres.dll, 110
Menu, Tray, Add, 📝 Text & Parsing, :TextParsing
Menu, Tray, Icon, 📝 Text & Parsing, shell32.dll, 151
Menu, Tray, Add, 💻 Virtualization, :Virtualization
Menu, Tray, Icon, 💻 Virtualization, imageres.dll, 10
Menu, Tray, Add, 🌍 Web Servers, :WebServers
Menu, Tray, Icon, 🌍 Web Servers, imageres.dll, 11
Menu, Tray, Add,
Menu, Tray, Add, 📂 Open cheats folder, OpenFolder
Menu, Tray, Icon, 📂 Open cheats folder, shell32.dll, 4
Menu, Tray, Add, ❌ Exit, ExitApp
Menu, Tray, Icon, ❌ Exit, shell32.dll, 28


FileAppend, All menus built`n, %LOG_FILE%
return

; ============= File Map =============
FileMap(item) {
    static files := {}
    if (files.Count() = 0) {
        ; Backups & S3
        files["s3cmd — S3 CLI"]                       := "backups-s3\s3cmdcheatsheet.md"
        files["Borg Backup"]                           := "backups-s3\borgcheatsheet.md"
        files["Restic Backup"]                         := "backups-s3\resticcheatsheet.md"
        ; Basics
        files["Linux Basics — Cheatsheet"]             := "basics\linuxbasicscheatsheet.md"
        files["Linux Basics 2 — Cheatsheet"]           := "basics\linuxbasics2cheatsheet.md"
        ; Cloud
        files["AWS CLI"]                               := "cloud\awsclicheatsheet.md"
        files["Azure CLI"]                             := "cloud\azureclicheatsheet.md"
        files["GCP CLI"]                               := "cloud\gcpclicheatsheet.md"
        files["OpenStack"]                             := "cloud\openstackcheatsheet.md"
        ; Databases
        files["Memcached"]                             := "databases\memcached-sysadmin.md"
        files["MongoDB"]                               := "databases\mongodbcheatsheet.md"
        files["MySQL/MariaDB & Cluster"]               := "databases\mysqlcheatsheet.md"
        files["OpenSearch"]                            := "databases\opensearchcheatsheet.md"
        files["Oracle"]                                := "databases\oraclecheatsheet.md"
        files["PostgreSQL"]                            := "databases\postgrescheatsheet.md"
        files["Redis"]                                 := "databases\redis_prod_cheatsheet.md"
        files["SQLite"]                                := "databases\sqlitecheatsheet.md"
        ; Dev & Tools
        files["Ansible"]                               := "dev-tools\ansiblecheatsheet.md"
        files["Build Tools"]                           := "dev-tools\buildtoolscheatsheet.md"
        files["Git Advanced"]                          := "dev-tools\gitadvancedcheatsheet.md"
        files["Git"]                                   := "dev-tools\gitcheatsheet.md"
        files["Jenkins"]                               := "dev-tools\jenkinscheatsheet.md"
        files["Kafka"]                                 := "dev-tools\kafkacheatsheet.md"
        files["Node Tools"]                            := "dev-tools\nodetoolscheatsheet.md"
        files["Python Tools"]                          := "dev-tools\pythontoolscheatsheet.md"
        files["Terraform"]                             := "dev-tools\terraformcheatsheet.md"
        files["tmux"]                                  := "dev-tools\tmuxcheatsheet.md"
        files["Zookeeper"]                             := "dev-tools\zookeepercheatsheet.md"
        ; Diagnostics
        files["Diagnostics"]                           := "diagnostics\diagcheatsheet.md"
        files["Process Diagnostics"]                   := "diagnostics\process_diagnostics_cheatsheet.md"
        ; Files & Archives
        files["diff & patch"]                          := "files-archives\diffpatchcheatsheet.md"
        files["tar"]                                   := "files-archives\tarcheatsheet.md"
        files["tar + zstd"]                            := "files-archives\tarzstdcheatsheet.md"
        files["zip/7z/zstd"]                           := "files-archives\zip7zzstdcheatsheet.md"
        ; Identity Management
        files["AD CLI"]                                := "identity-management\adclicheatsheet.md"
        ; Infrastructure Management
        files["AWX"]                                   := "infrastructure-mgmt\awxcheatsheet.md"
        files["Uyuni"]                                 := "infrastructure-mgmt\uyunicheatsheet.md"
        ; Kubernetes & Containers
        files["Docker"]                                := "kubernetes-containers\dockercheatsheet.md"
        files["Helm"]                                  := "kubernetes-containers\helmcheatsheet.md"
        files["K9s"]                                   := "kubernetes-containers\k9scheatsheet.md"
        files["kubectl"]                               := "kubernetes-containers\kubectlcheatsheet.md"
        files["kubectl JSONPath"]                      := "kubernetes-containers\kubectljsonpathcheatsheet.md"
        files["kubectl Kustomize"]                     := "kubernetes-containers\kubectlkustomizecheatsheet.md"
        files["OpenShift"]                             := "kubernetes-containers\openshiftcheatsheet.md"
        files["Podman & nerdctl"]                      := "kubernetes-containers\podmannerdctlcheatsheet.md"
        ; Monitoring
        files["Cerebro"]                               := "monitoring\cerebrocheatsheet.md"
        files["CheckMK Agent"]                         := "monitoring\checkmkagentcheatsheet.md"
        files["CheckMK"]                               := "monitoring\checkmkcheatsheet.md"
        files["Filebeat"]                              := "monitoring\filebeatcheatsheet.md"
        files["Nagios"]                                := "monitoring\nagioscheatsheet.md"
        files["SNMPD"]                                 := "monitoring\snmpdcheatsheet.md"
        files["Telegraf"]                              := "monitoring\telegrafcheatsheet.md"
        files["VictoriaMetrics"]                       := "monitoring\victoriametricscheatsheet.md"
        files["Zabbix Server"]                         := "monitoring\zabbixcheatsheet.md"
        ; Network
        files["autossh — Resilient SSH Tunnels"]       := "network\autosshcheatsheet.md"
        files["CURL — HTTP Client"]                    := "network\curlcheatsheet.md"
        files["DNS — dig/nslookup/host"]               := "network\dnscheatsheet.md"
        files["Fail2Ban — Intrusion Prevention"]       := "network\fail2bancheatsheet.md"
        files["firewalld — Firewall Management"]       := "network\firewalldcheatsheet.md"
        files["ip — Network Configuration"]            := "network\ipcheatsheet.md"
        files["iptables — Firewall Rules"]             := "network\iptablescheatsheet.md"
        files["iptables to nftables Translation"]      := "network\iptablesnfttranslatecheatsheet.md"
        files["nc / nmap — Network Tools"]             := "network\ncnmapcheatsheet.md"
        files["Network Diagnostics"]                   := "network\netdiagcheatsheet.md"
        files["netplan — Network Configuration"]       := "network\netplancheatsheet.md"
        files["Network Backend Detection"]             := "network\network-backend-detectioncheatsheet.md"
        files["NetworkManager"]                        := "network\networkmanagercheatsheet.md"
        files["nftables — Modern Firewall"]            := "network\nftcheatsheet.md"
        files["nmcli — NetworkManager CLI"]            := "network\nmclicheatsheet.md"
        files["resolvectl"]                            := "network\resolvectlcheatsheet.md"
        files["RSYNC — File Synchronization"]          := "network\rsynccheatsheet.md"
        files["SCP — Secure Copy"]                     := "network\scpcheatsheet.md"
        files["SS — Socket Statistics"]                := "network\sscheatsheet.md"
        files["SSH — Commands & Config"]               := "network\sshcheatsheet.md"
        files["SSH Tunneling & Port Forwarding"]       := "network\ssh_vpn_tunnel_cheatsheet.md"
        files["systemd-networkd"]                      := "network\systemd-networkdcheatsheet.md"
        files["UFW — Uncomplicated Firewall"]          := "network\ufwcheatsheet.md"
        files["VPN Plugins"]                           := "network\vpn-pluginscheatsheet.md"
        files["WireGuard — VPN Setup"]                 := "network\wireguardcheatsheet.md"
        ; Package Managers
        files["AppImage — Portable Apps"]              := "package-managers\appimagecheatsheet.md"
        files["APT — Debian/Ubuntu"]                   := "package-managers\aptcheatsheet.md"
        files["DNF — RHEL/Fedora"]                     := "package-managers\dnfcheatsheet.md"
        files["Flatpak"]                               := "package-managers\flatpakcheatsheet.md"
        files["Pacman — Arch Linux"]                   := "package-managers\pacmancheatsheet.md"
        files["Package Managers Overview"]             := "package-managers\pkgmanagerscheatsheet.md"
        files["Snap — Universal Packages"]             := "package-managers\snapcheatsheet.md"
        files["Zypper — OpenSUSE"]                     := "package-managers\zyppercheatsheet.md"
        ; Security & Crypto
        files["AIDE"]                                  := "security-crypto\aidecheatsheet.md"
        files["Cerbero Suite"]                         := "security-crypto\cerberocheatsheet.md"
        files["CrowdSec"]                              := "security-crypto\crowdseccheatsheet.md"
        files["Git Secret Leak Detection"]             := "security-crypto\gitleakscheatsheet.md"
        files["GPG / age — Encryption"]                := "security-crypto\gpgagecheatsheet.md"
        files["htpasswd — Basic Auth"]                 := "security-crypto\htpasswdcheatsheet.md"
        files["OpenSSL — Commands"]                    := "security-crypto\opensslcheatsheet.md"
        files["OpenSSL CSR with SAN"]                  := "security-crypto\opensslsancsrcheatsheet.md"
        files["pass — Password Store"]                 := "security-crypto\passcheatsheet.md"
        files["SSH Honeypot + CrowdSec"]               := "security-crypto\ssh_honeypot_crowdsec.md"
        files["SSH Keys & Access Management"]          := "security-crypto\ssh_keys_cheatsheet.md"
        ; Storage & FS
        files["ACL"]                                   := "storage-fs\aclcheatsheet.md"
        files["Chroot"]                                := "storage-fs\chrootcheatsheet.md"
        files["Disk Growth"]                           := "storage-fs\diskgrowcheatsheet.md"
        files["LVM — Basics"]                          := "storage-fs\lvmcheatsheet.md"
        files["Partition & Mount"]                     := "storage-fs\partitionmountcheatsheet.md"
        files["SMART & mdadm RAID"]                    := "storage-fs\smartraidcheatsheet.md"
        ; System & Logs
        files["cron / at — Commands"]                  := "system-logs\cronatcheatsheet.md"
        files["date & timedatectl"]                    := "system-logs\datetzcheatsheet.md"
        files["du/df/lsof/ps"]                         := "system-logs\diskproccheatsheet.md"
        files["ionice & nice"]                         := "system-logs\ionicenicescheatsheet.md"
        files["journalctl — Basics"]                   := "system-logs\journalctlbasicscheatsheet.md"
        files["journalctl — Systemd Journal"]          := "system-logs\journalctlcheatsheet.md"
        files["Kernel-panic RHEL"]                     := "system-logs\kernelpanicscheatsheet.md"
        files["Kibana"]                                := "system-logs\kibanacheatsheet.md"
        files["logrotate"]                             := "system-logs\logrotatecheatsheet.md"
        files["Ubuntu VPS Optimization"]               := "system-logs\optimize-vps-ubuntu.md"
        files["SELinux & AppArmor"]                    := "system-logs\selinuxapparmorcheatsheet.md"
        files["systemctl — Commands"]                  := "system-logs\systemctlcheatsheet.md"
        files["systemd Timers"]                        := "system-logs\systemdtimerscheatsheet.md"
        files["systemd unit template"]                 := "system-logs\systemdunittemplate.md"
        ; Text & Parsing
        files["AWK — Commands"]                        := "text-parsing\awkcheatsheet.md"
        files["cut/sort/uniq"]                         := "text-parsing\cutsortuniqcheatsheet.md"
        files["FIND — Commands"]                       := "text-parsing\findcheatsheet.md"
        files["fzf — Fuzzy Finder"]                    := "text-parsing\fzfcheatsheet.md"
        files["GREP — Commands"]                       := "text-parsing\grepcheatsheet.md"
        files["JQ — Commands"]                         := "text-parsing\jqcheatsheet.md"
        files["Bash Loops"]                            := "text-parsing\loopscheatsheet.md"
        files["Modern CLI"]                            := "text-parsing\modernclicheatsheet.md"
        files["SED — Commands"]                        := "text-parsing\sedcheatsheet.md"
        files["Tree"]                                  := "text-parsing\treecheatsheet.md"
        files["tr/head/tail/watch"]                    := "text-parsing\trheadtailwatchcheatsheet.md"
        files["vim"]                                   := "text-parsing\vimquickstartcheatsheet.md"
        files["yq — YAML processor"]                   := "text-parsing\yqcheatsheet.md"
        ; Virtualization
        files["KVM / Libvirt"]                         := "virtualization\kvmcheatsheet.md"
        ; Web Servers
        files["Apache HTTPD"]                          := "web-servers\apachecheatsheet.md"
        files["HAProxy"]                               := "web-servers\haproxycheatsheet.md"
        files["Nginx"]                                 := "web-servers\nginxcheatsheet.md"
        files["Tomcat"]                                := "web-servers\tomcatcheatsheet.md"
        files["WebLogic Server"]                       := "web-servers\weblogiccheatsheet.md"
    }
    return files[item]
}

OpenFile:
    item := A_ThisMenuItem
    FileAppend, OpenFile called: %item%`n, %LOG_FILE%
    rel := FileMap(item)
    FileAppend, Rel: %rel%`n, %LOG_FILE%
    if (rel != "") {
        path := CHEATS_DIR . "\" . rel
        FileAppend, Path: %path%`n, %LOG_FILE%
        Run, %path%
    }
return

OpenFolder:
    Run, %CHEATS_DIR%
return

ExitApp:
    ExitApp
return
