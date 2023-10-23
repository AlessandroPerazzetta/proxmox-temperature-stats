# Displaying CPU Temperature in Proxmox Summery in Real Time

!["Dashboard Screenshot"](https://github.com/AlessandroPerazzetta/proxmox-temperature-stats/blob/main/screenshot.png?raw=true)

Source: [Reddit](https://www.reddit.com/r/homelab/comments/rhq56e/displaying_cpu_temperature_in_proxmox_summery_in/)

1) Lets install lm-sensors to show us the information we need. Type the following in the proxmox shell
   
    `apt-get install lm-sensors`
   
    Next we can check if its working. To do this we can type sensors
   
    The main part we are interested in is:
   
        root@pve:~# sensors
       
        coretemp-isa-0000
        Adapter: ISA adapter
        Package id 0:  +23.0°C  (high = +84.0°C, crit = +100.0°C)
        Core 0:        +21.0°C  (high = +84.0°C, crit = +100.0°C)
        Core 1:        +21.0°C  (high = +84.0°C, crit = +100.0°C)
        Core 2:        +22.0°C  (high = +84.0°C, crit = +100.0°C)
        Core 3:        +19.0°C  (high = +84.0°C, crit = +100.0°C)
   
    If you see this you are good to go!

2) Adding the output of sensors to information
   
    Here we will use Nano to edit some files. In your shell, type the following:
   
    `nano /usr/share/perl5/PVE/API2/Nodes.pm`
   
    Next, you can press F6 to search for my $dinfo and press Enter
   
    The code should look like this:
   
            $res->{pveversion} = PVE::pvecfg::package() . "/" .
                PVE::pvecfg::version_text();
       
            my $dinfo = df('/', 1);     # output is bytes
   
    We are going to add the following line of code in between: $res->{thermalstate} = \sensors\;
   
    So the final result should look like this:
   
            $res->{pveversion} = PVE::pvecfg::package() . "/" .
                PVE::pvecfg::version_text();
       
            $res->{thermalstate} = `sensors`;
       
            my $dinfo = df('/', 1);     # output is bytes
   
    Now press Ctrl+O to save and Ctrl+X to exit.

3) Making space for the new information
   
    Next we will need to edit another file, So once again we will use Nano
   
    Type the following command into your shell:
   
    `nano /usr/share/pve-manager/js/pvemanagerlib.js`
   
    Once in press F6 to search for my widget.pveNodeStatus and press Enter
   
    You will get a snippit of code that looks like this:
   
        Ext.define('PVE.node.StatusView', {
        extend: 'PVE.panel.StatusView',
        alias: 'widget.pveNodeStatus',
       
        height: 300,
        bodyPadding: '5 15 5 15',
       
        layout: {
            type: 'table',
            columns: 2,
            tableAttrs: {
                style: {
                    width: '100%'
                }
            }
        },
   
    Next change the bodyPadding: '5 15 5 15', to bodyPadding: '20 15 20 15',
   
    As well as height: 300, to height: 360,
   
    Dont close the file this time!

4) Final part to edit
   
    Ok so you know the drill by now search for PVE Manager Version and press Enter
   
    You will see a section of code like this:
   
            {
                itemId: 'version',
                colspan: 2,
                printBar: false,
                title: gettext('PVE Manager Version'),
                textField: 'pveversion',
                value: ''
            }
   
    Ok now we need to add some code after this part. The code is:
   
            {
                itemId: 'thermal',
                colspan: 2,
                printBar: false,
                title: gettext('CPU Thermal State'),
                textField: 'thermalstate',
                renderer:function(value){
                    const c0 = value.match(/Core 0.*?\+([\d\.]+)Â/)[1];
                    const c1 = value.match(/Core 1.*?\+([\d\.]+)Â/)[1];
                    const c2 = value.match(/Core 2.*?\+([\d\.]+)Â/)[1];
                    const c3 = value.match(/Core 3.*?\+([\d\.]+)Â/)[1];
                    return `Core 0: ${c0} ℃ | Core 1: ${c1} ℃ | Core 2: ${c2} ℃ | Core 3: ${c3} ℃`
                }
            }
   
    Therefore your final result should look something like this:
   
            {
                itemId: 'version',
                colspan: 2,
                printBar: false,
                title: gettext('PVE Manager Version'),
                textField: 'pveversion',
                value: ''
            },
            {
                itemId: 'thermal',
                colspan: 2,
                printBar: false,
                title: gettext('CPU Thermal State'),
                textField: 'thermalstate',
                renderer:function(value){
                    const c0 = value.match(/Core 0.*?\+([\d\.]+)Â/)[1];
                    const c1 = value.match(/Core 1.*?\+([\d\.]+)Â/)[1];
                    const c2 = value.match(/Core 2.*?\+([\d\.]+)Â/)[1];
                    const c3 = value.match(/Core 3.*?\+([\d\.]+)Â/)[1];
                    return `Core 0: ${c0} ℃ | Core 1: ${c1} ℃ | Core 2: ${c2} ℃ | Core 3: ${c3} ℃`
                }
            }
   
    Now we can finally save and exit.

5) Restart the summery page
   
    To do this you will have to type in the following command:
   
    `systemctl restart pveproxy`
   
    If you got kicked out of the shell or it froze, dont worry this is normal! As the final step, either refresh your webpage with F5 or ideally close you browser and open proxmox again.