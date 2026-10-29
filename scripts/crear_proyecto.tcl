# Crea el proyecto de Vivado en vivado/ a partir de las fuentes del repositorio.
#
# Uso, desde la consola Tcl de Vivado:
#   cd <raíz del repositorio>
#   source scripts/crear_proyecto.tcl
# o desde una terminal:
#   vivado -mode batch -source scripts/crear_proyecto.tcl
#   vivado -mode batch -source scripts/crear_proyecto.tcl -tclargs <tb>
#
# Los archivos se agregan sin copiarlos: editar un .v desde Vivado modifica el
# de rtl/ o tb/. Un archivo nuevo entra al proyecto volviendo a correr el
# script. Si vivado/ ya existe, el proyecto se borra y se vuelve a crear.

set raiz [file normalize [file join [file dirname [info script]] ..]]

create_project tp_arqui [file join $raiz vivado] -part xc7a35tcpg236-1 -force
set_property target_language Verilog [current_project]

set fuentes  [glob -nocomplain [file join $raiz rtl * *.v] [file join $raiz rtl * *.vh]]
set benches  [glob -nocomplain [file join $raiz tb *.v]]
set restricc [glob -nocomplain [file join $raiz constraints *.xdc]]

if {[llength $fuentes]} {
    add_files -norecurse $fuentes
    set_property include_dirs [file join $raiz rtl core] [get_filesets sources_1]
}
if {[llength $benches]} {
    add_files -fileset sim_1 -norecurse $benches
}
if {[llength $restricc]} {
    add_files -fileset constrs_1 -norecurse $restricc
}

# Con los topes en automático, Vivado elige el módulo que no instancia nadie.
# Cuando exista rtl/top/top.v conviene fijarlo:
#   set_property top top [get_filesets sources_1]
update_compile_order -fileset sources_1

# El test bench a simular se puede pasar como argumento; sin argumento queda
# en automático:
#   vivado -mode batch -source scripts/crear_proyecto.tcl -tclargs tb_register_file
if {[info exists argv] && [llength $argv]} {
    set_property top [lindex $argv 0] [get_filesets sim_1]
    set_property top_lib xil_defaultlib [get_filesets sim_1]
}
update_compile_order -fileset sim_1

puts "Proyecto creado en [file join $raiz vivado tp_arqui.xpr]"
