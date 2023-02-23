cof_dir = ../dist/default/production
log_dir = ./logs
mdb_dir = .
m4_dir  = ./m4
scl_dir = ./scl

mdbs = $(wildcard $(mdb_dir)/*.mdb)
tests = $(basename $(notdir $(mdbs)))
scls = $(addprefix $(scl_dir)/, $(addsuffix .scl, $(tests)))
logs = $(addprefix $(log_dir)/, $(addsuffix .log, $(tests)))

test: $(logs)
	@echo
	@grep -h -e '_test: PASS' -e '_test: FAIL' -e '_test: TIMEOUT' $(log_dir)/*_test.log|sort -k2,2 -k1,1
	@echo \\n`grep -h '_test: PASS' $(log_dir)/*_test.log|wc -l` of `echo $(tests)|wc -w)` passed

$(logs): $(log_dir)/%.log: $(mdb_dir)/%.mdb $(scl_dir)/%.scl $(cof_dir)/*.production.cof | $(log_dir)
	@echo $(*F)
	@mdb $< > $@ 2>&1

$(log_dir):
	mkdir -p $(log_dir)

$(scls): $(scl_dir)/%.scl: $(scl_dir)/%.m4
	m4 --include=$(m4_dir) $< > $@

clean:
	rm $(scl_dir)/*.scl
	rm $(log_dir)/*.log
