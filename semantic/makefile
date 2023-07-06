# MakeFile Semantic Analysis 
# top (all)

SRCS := $(wildcard *.c)			# All files with the .c extension will be stored in a variable SRCS
BINS := $(SRCS:%.c=%)			# 

all: lexer parser fort600

fort600: errcheck.o types.o ast.o hash_t.o utils.o fort600_main.o
	gcc -o fort600 include/bison/fort600.tab.c include/flex/lex.yy.c include/errcheck/errcheck.o include/hashtable/hash_t.o include/ast/ast.o include/types/types.o include/utils/utils.o fort600_main.o -lm -g -I include/

errcheck.o: include/errcheck/errcheck.c include/errcheck/errcheck.h
	gcc -o include/errcheck/errcheck.o -c include/errcheck/errcheck.c -I include/

types.o: include/types/types.c include/types/types.h
	gcc -o include/types/types.o -c include/types/types.c -I include/

hash_t.o: include/hashtable/hash_t.c include/hashtable/hash_t.h
	gcc -o include/hashtable/hash_t.o -c include/hashtable/hash_t.c -I include/

ast.o: include/ast/ast.c include/ast/ast.h
	gcc -o include/ast/ast.o -c include/ast/ast.c -I include/

utils.o: include/utils/utils.c include/utils/utils.h
	gcc -o include/utils/utils.o -c include/utils/utils.c -I include/

fort600_main.o: fort600_main.c
	gcc -o fort600_main.o -c fort600_main.c -I include/

lexer: fort600.l
	flex -o include/flex/lex.yy.c fort600.l

parser: fort600.y
	bison -v -d -o include/bison/fort600.tab.c fort600.y

clean:
	rm include/flex/lex.yy.c
	rm include/bison/*
	find include/ -name '*.o' -type f -delete
	rm fort600_main.o
	rm fort600
	rm ast.gv