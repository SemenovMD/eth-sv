# Variables
SIM = tb/eth_tx/vsim/vsim.do

# Targets
all: sim

sim:
	@echo "Running simulation..."
	vsim -do $(SIM)
	@echo "Simulation completed"

clean:
	@echo "Cleaning up..."
	rm -rf work
	rm -f transcript
	rm -f vsim.wlf
	@echo "Clean completed."

.PHONY: all sim clean
