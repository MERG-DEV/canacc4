cof_dir = ../dist/default/production
log_dir = ./logs
mdb_dir = .
m4_dir  = ./m4
scl_dir = ./scl

tests = $(basename $(notdir $(wildcard $(mdb_dir)/*.mdb)))
logs = $(addprefix $(log_dir)/, $(addsuffix .log, $(tests)))

test: $(logs)
	@echo
	@grep -h -e '_test: PASS' -e '_test: FAIL' -e '_test: TIMEOUT' $(log_dir)/*_test.log|sort -k2,2 -k1,1
	@echo \\n`grep -h '_test: PASS' $(log_dir)/*_test.log|wc -l` of `echo $(tests)|wc -w)` passed

$(logs): | $(log_dir)

$(log_dir):
	mkdir -p $(log_dir)

$(log_dir)/%.log: $(mdb_dir)/%.mdb $(scl_dir)/%.scl $(cof_dir)/*.production.cof
	@echo $(*F)
	@mdb $< > $@ 2>&1

clean:
	rm $(log_dir)/*.log
