# Variables
SIM_RX = tb/eth_rx/vsim/vsim.do
SIM_TX = tb/eth_tx/vsim/vsim.do

# Targets
all: sim_tx

sim_rx:
	@echo "Running simulation..."
	vsim -do $(SIM_RX)
	@echo "Simulation completed"
	
sim_tx:
	@echo "Running simulation..."
	vsim -do $(SIM_TX)
	@echo "Simulation completed"

clean:
	@echo "Cleaning up..."
	rm -rf work
	rm -f transcript
	rm -f vsim.wlf
	@echo "Clean completed."

.PHONY: all sim clean
