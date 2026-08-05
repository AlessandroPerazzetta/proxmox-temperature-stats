

# Mostrar la temperatura de la CPU en el resumen de Proxmox en tiempo real

### Estándar
!["Captura del Panel"](https://github.com/AlessandroPerazzetta/proxmox-temperature-stats/blob/main/screenshot_standard.png?raw=true)

### JSON
!["Captura del Panel"](https://github.com/AlessandroPerazzetta/proxmox-temperature-stats/blob/main/screenshot_json.png?raw=true)


## Instalación automatizada del script

### Estándar
wget -O - https://raw.githubusercontent.com/AlessandroPerazzetta/proxmox-temperature-stats/main/pve_thermal_standard.sh | bash

### JSON
wget -O - https://raw.githubusercontent.com/AlessandroPerazzetta/proxmox-temperature-stats/main/pve_thermal_json.sh | bash

## Instalación manual

1) Instalemos `lm-sensors` para mostrarnos la información que necesitamos. Escriba lo siguiente en la shell de Proxmox
   
    `apt-get install lm-sensors`
   
    A continuación, podemos verificar si está funcionando. Para esto, podemos escribir `sensors`
   
    La parte principal en la que estamos interesados es:
   
        root@pve:~# sensors
       
        coretemp-isa-0000
        Adapter: ISA adapter
        Package id 0:  +23.0°C  (high = +84.0°C, crit = +100.0°C)
        Core 0:        +21.0°C  (high = +84.0°C, crit = +100.0°C)
        Core 1:        +21.0°C  (high = +84.0°C, crit = +100.0°C)
        Core 2:        +22.0°C  (high = +84.0°C, crit = +100.0°C)
        Core 3:        +19.0°C  (high = +84.0°C, crit = +100.0°C)
   
    ¡Si ve esto, está listo para continuar!

2) Agregar la salida de `sensors` a la información
   
    Aquí editaremos algunos archivos. En su shell, escriba lo siguiente:
   
    `vi /usr/share/perl5/PVE/API2/Nodes.pm`
   
    A continuación, puede buscar `my $dinfo` y presionar Enter
   
    El código debería verse así:
   
            $res->{pveversion} = PVE::pvecfg::package() . "/" .
                PVE::pvecfg::version_text();
       
            my $dinfo = df('/', 1);     # output is bytes
   
    Vamos a agregar la siguiente línea de código en medio: `$res->{thermalstate} = \`sensors\`;`
   
    Así que el resultado final debería verse así:
   
            $res->{pveversion} = PVE::pvecfg::package() . "/" .
                PVE::pvecfg::version_text();
       
            $res->{thermalstate} = `sensors`;
       
            my $dinfo = df('/', 1);     # output is bytes
   
    Ahora guarde y salga.

    ### Versión ESTÁNDAR

    No agregue parámetros para tener el formato de salida estándar:
    
        $res->{thermalstate} = `sensors`;

    ### Versión JSON

    Agregue parámetros para tener el formato de salida JSON:
    
        $res->{thermalstate} = `sensors -jA`;



3) Crear espacio para la nueva información
   
    A continuación, necesitaremos editar otro archivo
   
    Escriba el siguiente comando en su shell:
   
    `vi /usr/share/pve-manager/js/pvemanagerlib.js`
   
    Una vez dentro, presione para buscar `widget.pveNodeStatus` y presione Enter
   
    Obtendrá un fragmento de código que se ve así:
   
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
   
    A continuación, cambie `bodyPadding: '5 15 5 15',` por `bodyPadding: '20 15 20 15',`
   
    Así como `height: 300,` por `height: 360,`
   
    ¡Esta vez no cierre el archivo!

4) Parte final a editar
   
    Ahora busque `PVE Manager Version` y presione Enter
   
    Verá una sección de código como esta:
   
            {
                itemId: 'version',
                colspan: 2,
                printBar: false,
                title: gettext('PVE Manager Version'),
                textField: 'pveversion',
                value: ''
            }
   
    Bien, ahora necesitamos agregar algo de código después de esta parte. El código es:
   
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
   
    Por lo tanto, su resultado final debería verse algo así:
   
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
   
    Ahora finalmente podemos guardar y salir.

    ### Versión ESTÁNDAR

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

    ### Versión JSON
            {
                itemId: 'thermals',
                colspan: 2,
                printBar: false,
                title: gettext('Thermals'),
                textField: 'thermalstate',
                renderer:function(value){
                    let result = [];
                    const sensors = JSON.parse(value);
                    Object.entries(sensors).forEach(([sensor, temps]) => {
                        let sensorTemps = [];
                        Object.entries(temps).forEach(([name, temp]) => {
                            Object.entries(temp).forEach(([key, val]) => {
                                if(key.includes('_input')){
                                    sensorTemps.push(name + ': ' + val + ' °C');
                                }
                            });
                        });
                        result.push(sensor + ' ' + sensorTemps.join(' | '))
                    });
                    return result.join('<br>');
                }
            }



5) Reiniciar el administrador de pve y actualizar la página de resumen
   
    Para hacer esto, deberá escribir el siguiente comando:
   
    `systemctl restart pveproxy`
   
    Si fue desconectado de la shell o se congeló, ¡no se preocupe, esto es normal! Como paso final, actualice su página web con F5 o, idealmente, cierre su navegador y abra Proxmox nuevamente.


Créditos: [Reddit](https://www.reddit.com/r/homelab/comments/rhq56e/displaying_cpu_temperature_in_proxmox_summery_in/)
