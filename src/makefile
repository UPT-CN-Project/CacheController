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
#---------------------------------------
all: decoder mux and_wordgate bitwise_comparator cache_line four_way_set control_unit cache_memory cache_controller
#---------------------------------------
# decoder
#---------------------------------------
.PHONY: decoder
decoder:
	@echo "===== Building and testing decoder (decNto2N) ====="
	@mkdir -p $(BUILD_DIR)

	@$(SIMULATOR) $(SIM_FLAGS) -o $(BUILD_DIR)/decoder_sim.vvp $(SRC_DIR)/decoder.v $(TB_DIR)/decoder_tb.v

	@vvp $(BUILD_DIR)/decoder_sim.vvp
	@echo "===== Finished decoder testing ====="

#---------------------------------------
# mux
#---------------------------------------
.PHONY: mux
mux:
	@echo "===== Building and testing mux (muxNto1) ====="
	@mkdir -p $(BUILD_DIR)

	@$(SIMULATOR) $(SIM_FLAGS) -o $(BUILD_DIR)/mux_sim.vvp $(SRC_DIR)/mux.v $(TB_DIR)/mux_tb.v

	@vvp $(BUILD_DIR)/mux_sim.vvp
	@echo "===== Finished mux testing ====="

#---------------------------------------
# and_wordgate
#---------------------------------------
.PHONY: and_wordgate
and_wordgate:
	@echo "===== Building and testing and_wordgate ====="
	@mkdir -p $(BUILD_DIR)
	@$(SIMULATOR) $(SIM_FLAGS) -o $(BUILD_DIR)/and_wordgate_sim.vvp \
		$(SRC_DIR)/and_wordgate.v $(TB_DIR)/and_wordgate_tb.v
	@vvp $(BUILD_DIR)/and_wordgate_sim.vvp
	@echo "===== Finished testing ====="

#---------------------------------------
# bitwise_comparator
#---------------------------------------
.PHONY: bitwise_comparator
bitwise_comparator:
	@echo "===== Building and testing bitwise_comparator ====="
	@mkdir -p $(BUILD_DIR)
	@$(SIMULATOR) $(SIM_FLAGS) -o $(BUILD_DIR)/bitwise_comparator_sim.vvp \
		$(SRC_DIR)/bitwise_comparator.v $(SRC_DIR)/bit_comparator.v $(SRC_DIR)/and_wordgate.v $(TB_DIR)/bitwise_comparator_tb.v
	@vvp $(BUILD_DIR)/bitwise_comparator_sim.vvp
	@echo "===== Finished testing ====="

#---------------------------------------
# cache_line
#---------------------------------------
.PHONY: cache_line
cache_line:
	@echo "===== Building and testing cache_line ====="
	@mkdir -p $(BUILD_DIR)
	@$(SIMULATOR) $(SIM_FLAGS) -o $(BUILD_DIR)/cache_line_sim.vvp \
		$(SRC_DIR)/cache_line.v $(SRC_DIR)/bitwise_comparator.v $(SRC_DIR)/bit_comparator.v $(SRC_DIR)/and_wordgate.v $(TB_DIR)/cache_line_tb.v
	@vvp $(BUILD_DIR)/cache_line_sim.vvp
	@echo "===== Finished testing ====="

#---------------------------------------
# four_way_set
#---------------------------------------
.PHONY: four_way_set
four_way_set:
	@echo "===== Building and testing four_way_set ====="
	@mkdir -p $(BUILD_DIR)

	@$(SIMULATOR) $(SIM_FLAGS) -o $(BUILD_DIR)/four_way_set_sim.vvp $(SRC_DIR)/four_way_set.v $(SRC_DIR)/cache_line.v $(SRC_DIR)/encoder4to2.v $(SRC_DIR)/bitwise_comparator.v $(SRC_DIR)/bit_comparator.v $(SRC_DIR)/and_wordgate.v $(SRC_DIR)/mux.v $(TB_DIR)/four_way_set_tb.v

	@vvp $(BUILD_DIR)/four_way_set_sim.vvp
	@echo "===== Finished testing ====="

#---------------------------------------
# cache_memory
#---------------------------------------
.PHONY: cache_memory
cache_memory:
	@echo "===== Building cache_memory ====="
	@mkdir -p $(BUILD_DIR)

	@$(SIMULATOR) $(SIM_FLAGS) -o $(BUILD_DIR)/cache_memory_sim.vvp $(SRC_DIR)/cache_memory.v $(SRC_DIR)/four_way_set.v $(SRC_DIR)/cache_line.v $(SRC_DIR)/encoder4to2.v $(SRC_DIR)/bitwise_comparator.v $(SRC_DIR)/bit_comparator.v $(SRC_DIR)/and_wordgate.v $(SRC_DIR)/mux.v $(SRC_DIR)/decoder.v $(SRC_DIR)/tristate_driver.v $(TB_DIR)/cache_memory_tb.v

	@echo "===== Finished testing ====="

#---------------------------------------
# control_unit
#---------------------------------------
.PHONY: control_unit
control_unit:
		@echo "===== Building control_unit ====="
		@mkdir -p $(BUILD_DIR)

		@$(SIMULATOR) $(SIM_FLAGS) -o $(BUILD_DIR)/control_unit_sim.vvp $(SRC_DIR)/control_unit.v $(TB_DIR)/control_unit_tb.v

		@echo "===== Finished testing ====="

#---------------------------------------
# cache_controller
#---------------------------------------
.PHONY: cache_controller
cache_controller:
	@echo "===== Building cache_controller ====="
	@mkdir -p $(BUILD_DIR)

	@$(SIMULATOR) $(SIM_FLAGS) -o $(BUILD_DIR)/cache_controller_sim.vvp $(SRC_DIR)/cache_controller.v $(SRC_DIR)/control_unit.v $(SRC_DIR)/cache_memory.v $(SRC_DIR)/four_way_set.v $(SRC_DIR)/cache_line.v $(SRC_DIR)/encoder4to2.v $(SRC_DIR)/bitwise_comparator.v $(SRC_DIR)/bit_comparator.v $(SRC_DIR)/and_wordgate.v $(SRC_DIR)/mux.v $(SRC_DIR)/decoder.v $(SRC_DIR)/tristate_driver.v $(TB_DIR)/cache_controller_tb.v

	@echo "===== Finished testing ====="

#---------------------------------------
# clean: remove all generated .vvp files
#---------------------------------------
.PHONY: clean
clean:
	@echo "Cleaning up simulation executables..."
	@rm -rf $(BUILD_DIR)
	@echo "Cleanup complete."
