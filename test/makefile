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
	@grep -e 'Error: ' -e 'Failed to parse SCL' $(log_dir)/*_test.log|sort
	@echo
	@grep -h -e '_test: PASS' -e '_test: FAIL' -e '_test: TIMEOUT' $(log_dir)/*_test.log|sort -k2,2 -k1,1
	@echo \\n`grep -l '_test: PASS' $(log_dir)/*_test.log|wc -l` of `echo $(tests)|wc -w)` passed

.PHONY: run
run:
	@rm -f $(log_dir)/*.log
	@$(MAKE) test

$(logs): $(log_dir)/%.log: $(mdb_dir)/%.mdb $(scl_dir)/%.scl $(cof_dir)/*.production.cof | $(log_dir)
	@-mdb $< > $@ 2>&1
	@-grep -h -e 'Error: ' -e 'Failed to parse SCL' -e '_test: PASS' -e '_test: FAIL' -e '_test: TIMEOUT' $@||echo $(*F)

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
	@for dat_file in $(dats); do                                               \
     for m4_file in $$(grep -l $${dat_file} $(scl_m4s)); do                  \
       echo $(log_dir)/$$(basename $${m4_file} .m4).log: $${dat_file} >> $@; \
	   done;                                                                   \
	 done

mdb.dep: $(mdb_m4s) $(mdb_incs)
	@rm -f $@
	@touch $@
	@for including_file in $$(grep -l -e 'include(.*\.inc)' $(mdb_m4s) $(mdb_incs)); do                                 \
     echo -n $${including_file}: >> $@;                                                                               \
     for included_file in $$(grep -e 'include(.*\.inc)' $${including_file}|sed 's/.*(\(.*\)).*/\1/g'|tr '\n' ' '); do \
       echo -n ' $(mdb_dir)/'$${included_file} >> $@;                                                                 \
     done;                                                                                                            \
     echo '\n\t@'touch $$'@'>> $@;                                                                                 \
   done

scl.dep: $(scl_m4s) $(scl_incs)
	@rm -f $@
	@touch $@
	@for including_file in $$(grep -l -e 'include(.*\.inc)' $(scl_m4s) $(scl_incs)); do                                 \
     echo -n $${including_file}: >> $@;                                                                               \
     for included_file in $$(grep -e 'include(.*\.inc)' $${including_file}|sed 's/.*(\(.*\)).*/\1/g'|tr '\n' ' '); do \
       echo -n ' $(scl_dir)/'$${included_file} >> $@;                                                                 \
     done;                                                                                                            \
     echo '\n\t@'touch $$'@'>> $@;                                                                                 \
   done

ifeq ($(filter clean, $(MAKECMDGOALS)), )
include data.dep mdb.dep scl.dep
endif
