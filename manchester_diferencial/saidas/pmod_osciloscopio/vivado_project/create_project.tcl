# Recria o projeto Vivado da saída PMOD (manchester_dif) nesta pasta.
#
# Uso, no Tcl Console do Vivado (Window > Tcl Console):
#   cd <caminho do repositório>/manchester_diferencial/saidas/pmod_osciloscopio/vivado_project
#   source create_project.tcl
#
# O projeto usa o núcleo do codificador da pasta src/ do projeto principal
# (sem cópia) e o top manchester_dif_pmod, que leva o sinal codificado e o dado
# original ao conector PMOD JA com 1 ms por bit.

set proj_dir [file normalize [file dirname [info script]]]
set out_dir  [file normalize [file join $proj_dir ..]]
set root_dir [file normalize [file join $out_dir .. ..]]

create_project manchester_dif_pmod $proj_dir -part xc7a35tcpg236-1 -force
set_property target_language VHDL [current_project]
set_property simulator_language VHDL [current_project]

# Núcleo do codificador, display de 7 segmentos e top da saída PMOD
add_files -norecurse [list \
  [file join $root_dir src manchester_dif.vhd] \
  [file join $root_dir src display_7seg.vhd] \
  [file join $out_dir src manchester_dif_pmod.vhd]]
add_files -fileset constrs_1 -norecurse [file join $out_dir constraints manchester_dif_pmod.xdc]
add_files -fileset sim_1 -norecurse [file join $out_dir sim manchester_dif_pmod_tb.vhd]

set_property top manchester_dif_pmod [get_filesets sources_1]
set_property top manchester_dif_pmod_tb [get_filesets sim_1]

# O testbench transmite 16 bits de 1 ms
set_property -name {xsim.simulate.runtime} -value {17ms} -objects [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "Projeto manchester_dif_pmod criado em $proj_dir"
