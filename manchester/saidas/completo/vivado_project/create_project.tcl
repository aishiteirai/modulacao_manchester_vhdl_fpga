# Recria o projeto Vivado com todas as saídas (manchester) nesta pasta.
#
# Uso, no Tcl Console do Vivado (Window > Tcl Console):
#   cd <caminho do repositório>/manchester/saidas/completo/vivado_project
#   source create_project.tcl
#
# O projeto usa o núcleo do codificador da pasta src/ do projeto principal e o
# controlador VGA da saída vga/ (sem cópia), e o top manchester_completo, que
# leva o mesmo sinal, com 1 s por bit, aos LEDs, ao display, ao VGA e ao PMOD.

set proj_dir [file normalize [file dirname [info script]]]
set out_dir  [file normalize [file join $proj_dir ..]]
set root_dir [file normalize [file join $out_dir .. ..]]
set vga_dir  [file normalize [file join $out_dir .. vga]]

create_project manchester_completo $proj_dir -part xc7a35tcpg236-1 -force
set_property target_language VHDL [current_project]
set_property simulator_language VHDL [current_project]

# Núcleo do codificador, display, controlador VGA e top com todas as saídas
add_files -norecurse [list \
  [file join $root_dir src manchester.vhd] \
  [file join $root_dir src display_7seg.vhd] \
  [file join $vga_dir src vga_controller.vhd] \
  [file join $out_dir src manchester_completo.vhd]]
add_files -fileset constrs_1 -norecurse [file join $out_dir constraints manchester_completo.xdc]
add_files -fileset sim_1 -norecurse [file join $out_dir sim manchester_completo_tb.vhd]

set_property top manchester_completo [get_filesets sources_1]
set_property top manchester_completo_tb [get_filesets sim_1]

# O testbench simula 50 ms (cerca de três quadros); pode levar alguns minutos
set_property -name {xsim.simulate.runtime} -value {51ms} -objects [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "Projeto manchester_completo criado em $proj_dir"
