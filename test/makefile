.SUFFIXES:

cof_dir := ../dist/default/production
dat_dir := ./data
log_dir := ./logs
mdb_dir := ./mdb
scl_dir := ./scl

tests := $(basename $(notdir $(wildcard $(mdb_dir)/*_test.m4)))
logs := $(addprefix $(log_dir)/, $(addsuffix .log, $(tests)))
mdbs := $(addprefix $(mdb_dir)/, $(addsuffix .mdb, $(tests)))
scls := $(addprefix $(scl_dir)/, $(addsuffix .scl, $(tests)))

dats := $(wildcard $(dat_dir)/*.dat)
mdb_incs := $(wildcard $(mdb_dir)/*.inc)
mdb_m4s := $(wildcard $(mdb_dir)/*.m4)
scl_incs := $(wildcard $(scl_dir)/*.inc)
scl_m4s := $(wildcard $(scl_dir)/*.m4)

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

.PHONY: clean
clean:
	rm -f $(log_dir)/*.log $(mdb_dir)/*.mdb $(scl_dir)/*.scl *.dep

data.dep: $(scl_m4s) $(dats)
	@rm -f $@
	@touch $@
	@for dat_file in $(dats);                                                    \
	  do for m4_file in $$(grep -l $${dat_file} $(scl_m4s));                     \
	    do echo $(log_dir)/$$(basename $${m4_file} .m4).log: $${dat_file} >> $@; \
	  done;                                                                      \
	done

inc.dep: $(mdb_m4s) $(mdb_incs) $(scl_m4s) $(scl_incs)
	@rm -f $@
	@touch $@
	@for inc_file in $(mdb_incs);                                                                \
	  do for m4_file in $$(grep -l include\($$(basename $${inc_file})\) $(mdb_m4s) $(mdb_incs)); \
	    do echo $${m4_file}: $${inc_file} >> $@; echo \\t @touch $${m4_file} >> $@;              \
	  done;                                                                                      \
	done
	@for inc_file in $(scl_incs);                                                                \
	  do for m4_file in $$(grep -l include\($$(basename $${inc_file})\) $(scl_m4s) $(scl_incs)); \
	    do echo $${m4_file}: $${inc_file} >> $@; echo \\t @touch $${m4_file} >> $@;              \
	  done;                                                                                      \
	done

ifeq ($(filter clean, $(MAKECMDGOALS)), )
include data.dep inc.dep
endif
