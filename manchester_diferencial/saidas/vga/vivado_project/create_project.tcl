# Recria o projeto Vivado da saída VGA (manchester_dif) nesta pasta.
#
# Uso, no Tcl Console do Vivado (Window > Tcl Console):
#   cd <caminho do repositório>/manchester_diferencial/saidas/vga/vivado_project
#   source create_project.tcl
#
# O projeto usa o núcleo do codificador da pasta src/ do projeto principal
# (sem cópia), o controlador VGA e o top manchester_dif_vga, que pinta a tela
# inteira de verde (nível alto) ou azul (nível baixo) com 1 s por bit.

set proj_dir [file normalize [file dirname [info script]]]
set out_dir  [file normalize [file join $proj_dir ..]]
set root_dir [file normalize [file join $out_dir .. ..]]

create_project manchester_dif_vga $proj_dir -part xc7a35tcpg236-1 -force
set_property target_language VHDL [current_project]
set_property simulator_language VHDL [current_project]

# Núcleo do codificador, display, controlador VGA e top da saída VGA
add_files -norecurse [list \
  [file join $root_dir src manchester_dif.vhd] \
  [file join $root_dir src display_7seg.vhd] \
  [file join $out_dir src vga_controller.vhd] \
  [file join $out_dir src manchester_dif_vga.vhd]]
add_files -fileset constrs_1 -norecurse [file join $out_dir constraints manchester_dif_vga.xdc]
add_files -fileset sim_1 -norecurse [list \
  [file join $out_dir sim manchester_dif_vga_tb.vhd] \
  [file join $out_dir sim vga_controller_tb.vhd]]

set_property top manchester_dif_vga [get_filesets sources_1]
set_property top manchester_dif_vga_tb [get_filesets sim_1]

# O testbench simula 50 ms (cerca de três quadros); pode levar alguns minutos
set_property -name {xsim.simulate.runtime} -value {51ms} -objects [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "Projeto manchester_dif_vga criado em $proj_dir"
