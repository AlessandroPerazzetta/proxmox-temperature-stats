#!/bin/bash

PVE_NODES_FILE="/usr/share/perl5/PVE/API2/Nodes.pm"
PVE_MANAGERLIB_FILE="/usr/share/pve-manager/js/pvemanagerlib.js"

PVE_NODES_FILE_BKP="${PVE_NODES_FILE}_ORI"
PVE_MANAGERLIB_FILE_BKP="${PVE_MANAGERLIB_FILE}_ORI"

THERMAL_TPL="            
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
            return \`Core 0: ${c0} ℃ | Core 1: ${c1} ℃ | Core 2: ${c2} ℃ | Core 3: ${c3} ℃\`
        }
    }"


function installPackages() {
    apt-get install -y wget lm-sensors
}

function injectNodes() {
    if grep -q "res->{thermalstate}" $PVE_NODES_FILE; then
        echo "Sensors already injected to nodes file!!!"
        exit 1
    else
        echo "Sensors injection to nodes file not found, injecting..."

        echo "- backup original file: $PVE_NODES_FILE to $PVE_NODES_FILE_BKP"     
        # Copy the source file to the destination file  
        cp "$PVE_NODES_FILE" "$PVE_NODES_FILE_BKP"
        
        # Find the dinfo block and add thermal template
        sed -i 's/my $dinfo = df('\''\/'\''\, 1);/$res->{thermalstate} = `sensors`;\n&/' $PVE_NODES_FILE
    fi
}

function injectTemplate() {
    if grep -q "CPU Thermal State" $PVE_MANAGERLIB_FILE; then
        echo "Sensors already injected to nodes js file!!!"
        exit 1
    else
        echo "Sensors injection to pve manager js file not found, injecting..."

        echo "- backup original file: $PVE_MANAGERLIB_FILE to $PVE_MANAGERLIB_FILE_BKP"
        # Copy the source file to the destination file
        cp "$PVE_MANAGERLIB_FILE" "$PVE_MANAGERLIB_FILE_BKP"
        
        echo "Adding thermal template:\n$THERMAL_TPL"       
        # Define the temporary file
        tmpfile=$(mktemp)
        
        # Find the PVE Manager Version block and add thermal template
        awk -v var="$THERMAL_TPL" '/PVE Manager Version/ {p=1} p && /},/ {print; print var; p=0; next} 1' "$PVE_MANAGERLIB_FILE" > "$tmpfile"

        # Overwrite the original file with the modified content
        mv "$tmpfile" "$PVE_MANAGERLIB_FILE"
        chmod 644 "$PVE_MANAGERLIB_FILE"
        
        echo "Template fix: Change $PVE_MANAGERLIB_FILE file to match exact sensors output count inside the thermal template block"
        echo "<<< !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! >>>"
        echo "If something bad occur, restore original files with:"
        echo "# apt install --reinstall pve-manager proxmox-widget-toolkit libjs-extjs"
        echo "<<< !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! >>>"
    fi
}

function init() {
    installPackages
    injectNodes
    injectTemplate

    systemctl restart pveproxy
}

init