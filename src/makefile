# Makefile for Cache Controller Project
#---------------------------------------

# Simulator settings
SIMULATOR := iverilog
SIM_FLAGS := -g2012

# Source/testbench directories
SRC_DIR := main
TB_DIR  := testbench

# Where to drop compiled simulation executables
BUILD_DIR := build

#---------------------------------------
.PHONY: all clean

all: and_wordgate bitwise_comparator four_way_set cache_line control_unit cache_memory cache_controller

#---------------------------------------
# and_wordgate
#---------------------------------------
.PHONY: and_wordgate
and_wordgate:
	@echo "===== Building and testing and_wordgate ====="

	@mkdir -p $(BUILD_DIR)

	@$(SIMULATOR) $(SIM_FLAGS) -o $(BUILD_DIR)/and_wordgate_sim.vvp $(SRC_DIR)/and_wordgate.v $(TB_DIR)/and_wordgate_tb.v

	@vvp $(BUILD_DIR)/and_wordgate_sim.vvp

	@echo "===== Finished testing ====="

#---------------------------------------
# bitwise_comparator
#---------------------------------------
.PHONY: bitwise_comparator
bitwise_comparator:
	@echo "===== Building bitwise_comparator ====="

	@mkdir -p $(BUILD_DIR)

	@$(SIMULATOR) $(SIM_FLAGS) -o $(BUILD_DIR)/bitwise_comparator_sim.vvp $(SRC_DIR)/bitwise_comparator.v $(SRC_DIR)/bit_comparator.v $(SRC_DIR)/and_wordgate.v $(TB_DIR)/bitwise_comparator_tb.v

	@vvp $(BUILD_DIR)/bitwise_comparator_sim.vvp

	@echo "===== Finished testing ====="


#---------------------------------------
# cache_line
#---------------------------------------
.PHONY: cache_line
cache_line:
	@echo "===== Building cache_line ====="
	@mkdir -p $(BUILD_DIR)

	@$(SIMULATOR) $(SIM_FLAGS) -o $(BUILD_DIR)/cache_line.vvp $(SRC_DIR)/cache_line.v $(SRC_DIR)/bitwise_comparator.v $(SRC_DIR)/bit_comparator.v $(SRC_DIR)/and_wordgate.v $(TB_DIR)/cache_line_tb.v

	@vvp $(BUILD_DIR)/cache_line.vvp

	@echo "==============================="


#---------------------------------------
# four_way_set: placeholder
#---------------------------------------
.PHONY: four_way_set
four_way_set:
	@echo "===== Building four_way_set ====="
	@mkdir -p $(BUILD_DIR)
	@$(SIMULATOR) $(SIM_FLAGS) -o $(BUILD_DIR)/four_way_set_sim.vvp $(SRC_DIR)/four_way_set.v $(SRC_DIR)/bit_comparator.v $(SRC_DIR)/and_wordgate.v $(TB_DIR)/four_way_set_tb.v


	@echo "==============================="

#---------------------------------------
# control_unit: placeholder
#---------------------------------------
.PHONY: control_unit
control_unit:
	@echo "===== Building control_unit ====="
	@mkdir -p $(BUILD_DIR)
	@echo "(placeholder)"
	@echo "==============================="

#---------------------------------------
# cache_memory: placeholder
#---------------------------------------
.PHONY: cache_memory
cache_memory:
	@echo "===== Building cache_memory ====="
	@mkdir -p $(BUILD_DIR)
	@echo "(placeholder)"
	@echo "==============================="

#---------------------------------------
# cache_controller: placeholder
#---------------------------------------
.PHONY: cache_controller
cache_controller:
	@echo "===== Building cache_controller ====="
	@mkdir -p $(BUILD_DIR)
	@echo "(placeholder)"
	@echo "===================================="

#---------------------------------------
# clean: remove all generated .vvp files
#---------------------------------------
.PHONY: clean
clean:
	@echo "Cleaning up simulation executables..."
	@rm -rf $(BUILD_DIR)
	@echo "Cleanup complete."
