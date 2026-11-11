# Recria o projeto Vivado do codificador Manchester Diferencial nesta pasta.
#
# Uso, no Tcl Console do Vivado (Window > Tcl Console):
#   cd <caminho do repositório>/manchester_diferencial/vivado_project
#   source create_project.tcl
#
# Ou pelo terminal, sem abrir a interface gráfica:
#   vivado -mode batch -source create_project.tcl
#
# Os arquivos-fonte são referenciados nas pastas src/, sim/ e constraints/,
# sem cópia para dentro do projeto.

set proj_dir [file normalize [file dirname [info script]]]
set root_dir [file normalize [file join $proj_dir ..]]

create_project manchester_dif $proj_dir -part xc7a35tcpg236-1 -force
set_property target_language VHDL [current_project]
set_property simulator_language VHDL [current_project]

# Código-fonte, constraints e testbench
add_files -norecurse [list [file join $root_dir src manchester_dif.vhd] [file join $root_dir src display_7seg.vhd]]
add_files -fileset constrs_1 -norecurse [file join $root_dir constraints manchester_dif.xdc]
add_files -fileset sim_1 -norecurse [list [file join $root_dir sim manchester_dif_tb.vhd] [file join $root_dir sim display_7seg_tb.vhd]]

# Módulos top da síntese e da simulação
set_property top manchester_dif [get_filesets sources_1]
set_property top manchester_dif_tb [get_filesets sim_1]

# Tempo de simulação suficiente para todo o testbench (termina em ~3,9 us)
set_property -name {xsim.simulate.runtime} -value {4us} -objects [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "Projeto manchester_dif criado em $proj_dir"
