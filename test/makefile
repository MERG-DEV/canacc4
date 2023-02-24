cof_dir = ../dist/default/production
log_dir = ./logs
mdb_dir = ./mdb
scl_dir = ./scl

tests = $(basename $(notdir $(wildcard $(mdb_dir)/*_test.m4)))
logs = $(addprefix $(log_dir)/, $(addsuffix .log, $(tests)))
mdbs = $(addprefix $(mdb_dir)/, $(addsuffix .mdb, $(tests)))
scls = $(addprefix $(scl_dir)/, $(addsuffix .scl, $(tests)))

test: $(logs)
	@echo
	@grep -h -e '_test: PASS' -e '_test: FAIL' -e '_test: TIMEOUT' $(log_dir)/*_test.log|sort -k2,2 -k1,1
	@echo \\n`grep -h '_test: PASS' $(log_dir)/*_test.log|wc -l` of `echo $(tests)|wc -w)` passed

$(logs): $(log_dir)/%.log: $(mdb_dir)/%.mdb $(scl_dir)/%.scl $(cof_dir)/*.production.cof | $(log_dir)
	@echo $(*F)
	@mdb $< > $@ 2>&1

$(log_dir):
	mkdir -p $(log_dir)

$(mdbs): %.mdb: %.m4
	@cd $(@D) && m4 $(<F) > $(@F)

$(scls): %.scl: %.m4
	@cd $(@D) && m4 $(<F) > $(@F)

clean:
	rm $(log_dir)/*.log
	rm $(mdb_dir)/*.mdb
	rm $(scl_dir)/*.scl

$(scl_dir)/flim_enumerate_test.scl: $(scl_dir)/rx_tx.inc
